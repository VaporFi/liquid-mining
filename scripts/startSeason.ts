import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { calculateReward, getNextMonthTimestamp, logTx } from '../utils'

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
  const nextSeasonEndTimestamp = getNextMonthTimestamp()
  console.log('Attempting to start new season')
  const startSeasonTx =
    await DiamondManagerFacet.startNewSeasonWithEndTimestamp(
      parsedRewards.toString(),
      nextSeasonEndTimestamp
    )
  await logTx(startSeasonTx)

  console.log('✅ New season started')

  const mintVAPETx = await DiamondManagerFacet.claimTokensForSeason()
  await logTx(mintVAPETx)
  console.log('✅ Vape minted')

  console.log('✅ All done')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
