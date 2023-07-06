import deployDiamond, { FacetNames } from './deployDiamond'
import { ethers, network } from 'hardhat'
import { addresses } from '../../config/addresses'

async function main() {
  // Deploy LiquidMiningDiamond
  const diamond = await deployDiamond()
  const diamondAddress = await diamond.getAddress()

  console.log(
    `LiquidMiningDiamond deployed at ${diamondAddress} on ${network.name}`
  )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
