import { subtask, task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import chunk from '../utils/chunk'
import type { DepositEvent } from '../typechain-types/src/facets/DepositFacet'
import Bottleneck from 'bottleneck'
import * as path from 'path'

const BLOCK_RANGE = 500

const FROM_BLOCK: { [key: string]: number } = {
  fuji: 23009545,
  avalanche: 0, // TODO: Update this once we have a mainnet deployment
}

const limiter = new Bottleneck({
  minTime: 10, // ~30 requests per second
  maxConcurrent: 1,
})

task('automated-claim:single', 'Claim rewards for a single wallet')
  .addParam('wallet', 'The wallet to claim for')
  .addParam('seasonId', 'The season ID')
  .setAction(async ({ wallet, seasonId }, { ethers, network }) => {
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const ClaimFacet = await ethers.getContractAt('ClaimFacet', diamondAddress)
    const DiamondManagerFacet = await ethers.getContractAt(
      'DiamondManagerFacet',
      diamondAddress
    )

    try {
      const userData = await DiamondManagerFacet.getUserDataForSeason(
        wallet,
        seasonId
      )
      if (userData.depositPoints > 0 && !userData.hasWithdrawnOrRestaked) {
        console.log(`Claiming for ${wallet}`)
        const tx = await ClaimFacet.automatedClaim(seasonId, wallet)
        await tx.wait(3)
        console.log(
          `✅ Claimed for ${wallet}: https://snowtrace.io/tx/${tx.hash}`
        )
      } else {
        console.log(`Skipping ${wallet} because they have no deposits`, {
          deposit: userData.depositPoints,
          withdrawn: userData.hasWithdrawnOrRestaked,
        })
      }
    } catch (error) {
      console.error('❌ AutomatedClaim failed:', error)
      throw error
    }
  })

task('automated-claim:all', 'Claim all rewards for a season')
  .addOptionalParam('seasonId', 'The season ID')
  .addOptionalParam('loadFromDisk')
  .addOptionalParam('loadFromSubgraph')
  .addOptionalParam('dryRun')
  .setAction(
    async (
      { seasonId, dryRun, loadFromDisk, loadFromSubgraph },
      { ethers, network, run }
    ) => {
      const [deployer] = await ethers.getSigners()
      console.log('AutomatedClaim task', deployer.address, network.name)
      // Load Diamond and ClaimFacet
      const diamondAddress =
        LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
          .address
      const ClaimFacet = await ethers.getContractAt(
        'ClaimFacet',
        diamondAddress
      )
      const DiamondManagerFacet = await ethers.getContractAt(
        'DiamondManagerFacet',
        diamondAddress
      )
      const AuthorizationFacet = await ethers.getContractAt(
        'AuthorizationFacet',
        diamondAddress
      )

      const isAuthorized = await AuthorizationFacet.authorized(deployer.address)

      if (!isAuthorized) {
        console.error('❌ Deployer is not authorized')
        return
      }

      const currentSeasonId = await DiamondManagerFacet.getCurrentSeasonId()

      let seasonToClaim: string
      if (seasonId === currentSeasonId.toString()) {
        const seasonEndTimestamp =
          await DiamondManagerFacet.getSeasonEndTimestamp(
            currentSeasonId.toString()
          )
        const currentTimestamp = Math.floor(Date.now() / 1000)

        if (currentTimestamp < +seasonEndTimestamp.toString()) {
          console.error(
            `❌ Season ${currentSeasonId} has not ended yet, cannot claim`,
            {
              currentTimestamp,
              seasonEndTimestamp: +seasonEndTimestamp.toString(),
            }
          )
          return
        } else {
          console.log(`✅ Season ${currentSeasonId} has ended, can claim`, {
            currentTimestamp,
            seasonEndTimestamp: +seasonEndTimestamp.toString(),
          })
          seasonToClaim = currentSeasonId.toString()
        }
      } else {
        seasonToClaim = seasonId.toString()
      }

      // Load all Deposit events
      const depositorsSource = loadFromSubgraph
        ? 'subgraph'
        : loadFromDisk
        ? 'disk'
        : 'rpc'
      const depositors = await run(`loadDepositors:${depositorsSource}`, {
        seasonId: seasonToClaim,
      })

      try {
        // Slice the array into chunks of 100
        const chunkedDepositors = chunk(depositors, 100)

        // Claim for each chunk
        for (const chunk of chunkedDepositors) {
          const validatedWallets = await Promise.all(
            chunk.map(async (wallet: string) => {
              const userData = await DiamondManagerFacet.getUserDataForSeason(
                wallet,
                seasonToClaim
              )
              await new Promise((resolve) => setTimeout(resolve, 100))
              if (
                userData.depositPoints > 0 &&
                !userData.hasWithdrawnOrRestaked
              ) {
                return wallet
              }

              console.log(`Skipping ${wallet} because they have no deposits`)
              return
            })
          )
          console.log(`Claiming for ${validatedWallets.length} depositors`)
          const filteredWallets = validatedWallets.filter(
            (item) => item !== undefined
          )

          if (filteredWallets.length === 0) {
            console.log('No wallets to claim for, skipping...')
            continue
          }

          if (!dryRun) {
            const tx = await ClaimFacet.automatedClaimBatch(
              seasonToClaim,
              filteredWallets,
              {
                gasLimit: 13_000_000,
              }
            )
            await tx.wait(5)
            console.log(`https://snowtrace.io/tx/${tx.hash}`)
            await new Promise((resolve) => setTimeout(resolve, 1000))
          } else {
            console.log('Dry run, skipping claim')
          }
          console.log(`✅ Claimed for ${chunk.length} depositors`)
        }
      } catch (error) {
        console.error('❌ AutomatedClaim failed:', error)
        throw error
      }

      console.log('✅ Done')
    }
  )

subtask('loadDepositors:subgraph', async ({ seasonId }, { network }) => {
  const url = 'https://api.thegraph.com/subgraphs/name/vaporfi/liquid-mining'

  const query = `{
            season(id:${seasonId}){
              minerWallets
            }
        }`

  const response = await fetch(url, {
    method: 'POST',
    body: JSON.stringify({ query }),
  }).then(async (res) => await res.json())

  const wallets = response?.data?.season?.minerWallets
  const uniqueWallets = [...new Set(wallets)]

  if (!uniqueWallets) {
    throw new Error('No wallets found')
  } else {
    console.log(`Found ${uniqueWallets.length} wallets`)
  }

  // Save to disk
  // const saveToPath = `./data/season-depositors-${network.name}-${seasonId}.json`
  const saveToPath = path.join(
    __dirname,
    `./data/season-depositors-${network.name}-${seasonId}.json`
  )
  require('fs').writeFileSync(saveToPath, JSON.stringify(uniqueWallets), {
    flag: 'w',
  })

  return wallets
})

subtask('loadDepositors:disk', 'Load deposits from disk')
  .addParam('seasonId', 'The season ID')
  .setAction(async ({ seasonId }, { ethers, network }) => {
    const path = `./data/season-depositors-${network.name}-${seasonId}.json`
    const depositors = require(path)
    console.log(`Loaded ${depositors.length} depositors from ${path}`)
    return depositors
  })

subtask('loadDepositors:rpc', 'Load deposits from RPC')
  .addParam('seasonId', 'The season ID')
  .setAction(async ({ seasonId }, { ethers, network }) => {
    // Load Diamond and ClaimFacet
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const DepositFacet = await ethers.getContractAt(
      'DepositFacet',
      diamondAddress
    )

    // Load all Deposit events
    const depositFilter = DepositFacet.filters.Deposit(
      seasonId,
      undefined,
      undefined
    )
    /*
     * Query events for evey 10,000 blocks since FROM_BLOCK
     * using a limiter to avoid rate limiting from RPC provider
     * @dev Ankr has a rate limit of 30 requests per second
     */
    const lastBlock = await ethers.provider.getBlockNumber()
    const result = await limiter.schedule(async () => {
      let depositEvents: DepositEvent.Log[] = []
      for (let i = FROM_BLOCK[network.name]; i < lastBlock; i += BLOCK_RANGE) {
        const toBlock =
          i + BLOCK_RANGE > lastBlock ? lastBlock : i + BLOCK_RANGE
        console.log(`Querying events from block ${i} to ${toBlock}`)
        const events = await DepositFacet.queryFilter(depositFilter, i, toBlock)
        console.log(`Found ${events.length} events`)
        depositEvents = depositEvents.concat(events)
      }
      console.log(`Found ${depositEvents.length} total events`)
      return depositEvents
    })

    // Get all depositors
    const depositors = result.map((event) => event.args?.user)
    const uniqueDepositors = [...new Set(depositors)]

    // Save to disk
    const path = `./data/season-depositors-${network.name}-${seasonId}.json`
    require('fs').writeFileSync(path, JSON.stringify(uniqueDepositors))

    return uniqueDepositors
  })
