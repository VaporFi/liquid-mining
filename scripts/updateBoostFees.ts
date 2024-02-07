import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { logTx } from '../utils/logTx'
import { parseUnits } from 'ethers'

async function main() {
  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  const DiamondManagerFacet = await ethers.getContractAt(
    'DiamondManagerFacet',
    diamondAddress
  )

  const level1Tx = await DiamondManagerFacet.setBoostFee(
    1,
    parseUnits('0.1', 6).toString()
  )
  await logTx(level1Tx)
  const level2Tx = await DiamondManagerFacet.setBoostFee(
    2,
    parseUnits('0.15', 6).toString()
  )
  await logTx(level2Tx)
  const level3Tx = await DiamondManagerFacet.setBoostFee(
    2,
    parseUnits('0.2', 6).toString()
  )
  await logTx(level3Tx)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
