import { ethers, network } from 'hardhat'
import { deployContract } from '../../utils/deployContract'
import LiquidMining from '../../deployments/LiquidMiningDiamond.json'

async function main() {
  const liquidMining = LiquidMining[network.name as keyof typeof LiquidMining]

  try {
    await deployContract('GelatoResolver', {
      args: [liquidMining.address],
      log: true,
    })
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
