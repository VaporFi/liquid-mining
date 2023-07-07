import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../../deployments/LiquidMiningDiamond.json'
import { ChainId, addresses } from '../../config/addresses'

async function main() {
  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  const DiamondManagerFacet = await ethers.getContractAt(
    'DiamondManagerFacet',
    diamondAddress
  )

  // const boostFixTx = await DiamondManagerFacet.setBoostFeeReceivers(
  //   [
  //     addresses.teamMultisig[ChainId.AVALANCHE],
  //     addresses.xVAPE[ChainId.AVALANCHE],
  //     addresses.passportPool[ChainId.AVALANCHE],
  //   ],
  //   [6000, 3000, 1000]
  // )
  // await boostFixTx.wait(1)

  // console.log('✅ Boost fee receivers set')

  // const emTx = await DiamondManagerFacet.setEmissionsManager(
  //   addresses.emissionsManager[ChainId.AVALANCHE]
  // )
  // await emTx.wait(1)

  // console.log('✅ Emissions manager set')

  const startSeasonTx = await DiamondManagerFacet.startNewSeasonWithDuration(
    '15000000000000000000000',
    24
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
