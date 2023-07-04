import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import chunk from '../utils/chunk'

async function main(seasonId: number) {
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
  const filter = DepositFacet.filters.Deposit(seasonId, undefined, undefined)
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
}

main(1)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
