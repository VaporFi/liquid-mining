import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'

task('season:start', 'Start a new season')
  .addParam('rewards', 'The rewards for the season to distribute')
  .addOptionalParam('duration', 'The duration of the season in days')
  .setAction(async ({ rewards, duration }, { ethers, network }) => {
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const DiamondManagerFacet = await ethers.getContractAt(
      'DiamondManagerFacet',
      diamondAddress
    )

    if (duration) {
      await (
        await DiamondManagerFacet.startNewSeasonWithDuration(
          ethers.parseEther(rewards),
          duration
        )
      ).wait(3)
    } else {
      await (await DiamondManagerFacet.startNewSeason(rewards)).wait(3)
    }

    console.log('✅ Started new season')
  })
