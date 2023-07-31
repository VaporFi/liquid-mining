import { subtask, task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import chunk from '../utils/chunk'
import type { DepositEvent } from '../typechain-types/src/facets/DepositFacet'
import Bottleneck from 'bottleneck'

const BLOCK_RANGE = 500

const FROM_BLOCK: { [key: string]: number } = {
  fuji: 23009545,
  avalanche: 0, // TODO: Update this once we have a mainnet deployment
}

const limiter = new Bottleneck({
  minTime: 10, // ~30 requests per second
  maxConcurrent: 1,
})

task('automatedClaim', 'Claim all rewards for a season')
  .addParam('seasonId', 'The season ID')
  .addOptionalParam(
    'loadFromDisk',
    'Whether to load the deposits from disk under data folder'
  )
  .addOptionalParam('dryRun', 'Whether to run the task without claiming')
  .setAction(
    async (
      { seasonId, dryRun, loadFromDisk, loadFromSubgraph },
      { ethers, network, run }
    ) => {
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

      const currentSeasonId = await DiamondManagerFacet.getCurrentSeasonId()

      if (seasonId.toString() !== currentSeasonId.toString()) {
        console.error(
          `❌ Season ID ${seasonId} is not the current season ID ${currentSeasonId}`
        )
        return
      }

      // Load all Deposit events
      const depositorsSource = loadFromSubgraph
        ? 'subgraph'
        : loadFromDisk
        ? 'disk'
        : 'rpc'
      const depositors = await run(`loadDepositors:${depositorsSource}`, {
        seasonId,
      })

      try {
        // Slice the array into chunks of 100
        const chunkedDepositors = chunk(depositors, 100)
        // Claim for each chunk
        for (const chunk of chunkedDepositors) {
          console.log(`Claiming for ${chunk.length} depositors`, chunk)
          if (!dryRun) {
            await (
              await ClaimFacet.automatedClaimBatch(seasonId, chunk)
            ).wait(3)
          } else {
            console.log('Dry run, skipping claim')
          }
          console.log(`✅ Claimed for ${chunk.length} depositors`)
        }
      } catch (error) {
        console.error('❌ AutomatedClaim failed:', error)
        throw error
      }

      /*
       * TODO: implement starting a new season right after claiming
       * 1. Calculate new season rewards amount (VAPE)
       * 2. Calculate new season start and end timestamps
       * 3. Call Diamond to start new season
       * 4. Call diamond to mint VAPE through emissions manager(function name is claimTokensForSeason)
       */

      console.log('✅ Done')
    }
  )

subtask('loadDepositors:subgraph', async ({ seasonId }) => {
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
