import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'

task('season:set-season-end', 'Force set the end of the current season')
  .addParam('end', 'The timestamp of the end of the season')
  .setAction(async ({ end }, { ethers, network }) => {
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const DiamondManagerFacet = await ethers.getContractAt(
      'DiamondManagerFacet',
      diamondAddress
    )

    const currentSeasonId = await DiamondManagerFacet.getCurrentSeasonId()
    const setSeasonEndTx = await DiamondManagerFacet.setSeasonEndTimestamp(
      currentSeasonId,
      end
    )

    await setSeasonEndTx.wait(3)

    console.log('✅ Set season end timestamp')
  })
