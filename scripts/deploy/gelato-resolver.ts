import { ethers, network } from 'hardhat'
import { deployContract } from '../../utils/deployContract'
import LiquidMining from '../../deployments/LiquidMiningDiamond.json'

async function main() {
  const liquidMining = LiquidMining[network.name as keyof typeof LiquidMining]

  try {
    const GelatoResolver = await deployContract('GelatoResolver', {
      args: [liquidMining.address],
      log: true,
    })

    const DiamondManagerFacet = await ethers.getContractAt(
      'DiamondManagerFacet',
      liquidMining.address
    )
    await DiamondManagerFacet.setGelatoExecutor(
      await GelatoResolver.getAddress()
    )
  } catch (error) {
    console.log(error)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
