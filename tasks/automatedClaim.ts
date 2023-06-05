import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import chunk from '../utils/chunk'

task('automatedClaim', 'Claim all rewards for a season')
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
    const ClaimFacet = await ethers.getContractAt('ClaimFacet', diamondAddress)
    // Load all Deposit events
    const filter = DepositFacet.filters.Deposit(seasonId, null, null)
    const depositEvents = await DepositFacet.queryFilter(filter)
    // Get all depositors
    const depositors = depositEvents.map((event) => event.args?.user)
    const uniqueDepositors = [...new Set(depositors)]
    // Slice the array into chunks of 100
    const chunkedDepositors = chunk(uniqueDepositors, 100)
    // Claim for each chunk
    for (const chunk of chunkedDepositors) {
      await (await ClaimFacet.automatedClaim(seasonId, chunk)).wait(3)
    }
  })
