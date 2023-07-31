import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'

/*
 * Starting at 15,000 VAPE per season, on Season 1,
 * we will decreate the emissions by 0.41217% per season.
 */
const calculateSeasonRewards = (seasonId: number) => {
  const initialRewards = 15000
  const emissionsDecrement = 0.0041217
  const seasonRewards = Math.floor(
    initialRewards * (1 - emissionsDecrement) ** seasonId
  )
  return seasonRewards
}

const daysInMonth = () => {
  const now = new Date()
  const year = now.getFullYear()
  const month = now.getMonth()

  // Create a date for the first day of the next month
  const nextMonth = new Date(year, month + 1, 1)

  // Subtract one day to get the last day of the current month
  nextMonth.setDate(nextMonth.getDate() - 1)

  return nextMonth.getDate()
}

async function main() {
  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  const DiamondManagerFacet = await ethers.getContractAt(
    'DiamondManagerFacet',
    diamondAddress
  )
  const currentSeasonId = await DiamondManagerFacet.getCurrentSeasonId()
  const startSeasonTx = await DiamondManagerFacet.startNewSeasonWithDuration(
    calculateSeasonRewards(Number(currentSeasonId.toString()) + 1),
    daysInMonth() * 24 * 60 * 60
  )
  await startSeasonTx.wait(1)

  console.log('✅ New season started')

  const mintVAPETx = await DiamondManagerFacet.claimTokensForSeason()
  await mintVAPETx.wait(1)

  console.log('✅ Vape minted')

  console.log('✅ All done')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
