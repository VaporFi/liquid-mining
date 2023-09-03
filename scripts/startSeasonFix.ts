import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'

/*
 * Starting at 15,000 VAPE per season, on Season 1,
 * we will decreate the emissions by 0.41217% per season.
 */
const calculateReward = (seasonId: number) => {
  // Initial values
  const initialRewards = 15000
  const reductionPercentage = 0.41217 / 100

  let reward = initialRewards
  for (let season = 2; season <= seasonId; season++) {
    reward = reward - reward * reductionPercentage
  }

  return reward
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
  const rewards = calculateReward(Number(currentSeasonId.toString()) + 1)
  const parsedRewards = ethers.parseEther(rewards.toString())
  console.log('Attempting to start new season')
  const startSeasonTx =
    await DiamondManagerFacet.startNewSeasonWithEndTimestamp(
      parsedRewards.toString(),
      1696118400 // 2023-10-01 00:00:00 UTC
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
