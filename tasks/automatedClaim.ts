import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import chunk from '../utils/chunk'
import { DepositEvent } from '../typechain-types/src/facets/DepositFacet'
import Bottleneck from 'bottleneck'

const FROM_BLOCK: { [key: string]: number } = {
  fuji: 23009545,
  avalanche: 0, // TODO: Update this once we have a mainnet deployment
}

const limiter = new Bottleneck({
  minTime: 33, // ~30 requests per second
  maxConcurrent: 1,
})

task('automatedClaim', 'Claim all rewards for a season')
  .addParam('seasonId', 'The season ID')
  .addOptionalParam('dryRun', 'Whether to run the task without claiming')
  .setAction(async ({ seasonId, dryRun }, { ethers, network }) => {
    // Load Diamond and ClaimFacet
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const DepositFacet = await ethers.getContractAt(
      'DepositFacet',
      diamondAddress
    )
    const ClaimFacet = await ethers.getContractAt('ClaimFacet', diamondAddress)
    // Load all Deposit events
    const filter = DepositFacet.filters.Deposit(seasonId, null, null)
    /*
     * Query events for evey 10,000 blocks since FROM_BLOCK
     * using a limiter to avoid rate limiting from RPC provider
     * @dev Ankr has a rate limit of 30 requests per second
     */
    const lastBlock = await ethers.provider.getBlockNumber()
    const result = await limiter.schedule(async () => {
      let depositEvents: DepositEvent[] = []
      for (let i = FROM_BLOCK[network.name]; i < lastBlock; i += 10_000) {
        const toBlock = i + 10_000 > lastBlock ? 'latest' : i + 10_000
        console.log(`Querying events from block ${i} to ${toBlock}`)
        const events = await DepositFacet.queryFilter(filter, i, toBlock)
        console.log(`Found ${events.length} events`)
        depositEvents = depositEvents.concat(events)
      }
      console.log(`Found ${depositEvents.length} total events`)
      return depositEvents
    })

    // Get all depositors
    if (dryRun === 'true') return // If dry run, return early
    const depositors = result.map((event) => event.args?.user)
    const uniqueDepositors = [...new Set(depositors)]

    try {
      // Slice the array into chunks of 100
      const chunkedDepositors = chunk(uniqueDepositors, 100)
      // Claim for each chunk
      for (const chunk of chunkedDepositors) {
        await (await ClaimFacet.automatedClaim(seasonId, chunk)).wait(3)
      }
    } catch (e) {
      console.error(e)
      throw e
    }

    /*
     * TODO: implement starting a new season right after claiming
     * 1. Calculate new season rewards amount (VAPE)
     * 2. Calculate new season start and end timestamps
     * 3. Call EmmissionsManager to mint VAPE
     * 4. Call Diamond to start new season
     */

    console.log('✅ Done')
  })
