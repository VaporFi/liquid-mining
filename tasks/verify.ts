import { task } from 'hardhat/config'
import getContractDeployed from '../utils/getContractDeployment'

task('verify:contract', 'Verifies a contract on etherscan')
  .addParam('contract', 'The contract name')
  .setAction(async (taskArgs, hre) => {
    const { contract } = taskArgs
    const { network } = hre

    const { address, args } = await getContractDeployed(contract, network.name)

    try {
      await hre.run('verify:verify', {
        address: address,
        constructorArguments: args,
      })
    } catch (err) {
      console.log(err)
      return
    }
  })

task('verify:facets', 'Verifies all facets on etherscan').setAction(
  async (taskArgs, hre) => {
    const { network } = hre

    const facets = [
      'AuthorizationFacet',
      'BoostFacet',
      'ClaimFacet',
      'DepositFacet',
      'DiamondCutFacet',
      'DiamondLoupeFacet',
      'DiamondManagerFacet',
      'FeeCollectorFacet',
      'OwnershipFacet',
      'PausationFacet',
      'RestakeFacet',
      'UnlockFacet',
      'WithdrawFacet',
    ]

    for (const facet of facets) {
      const { address, args } = await getContractDeployed(facet, network.name)

      try {
        await hre.run('verify:verify', {
          address: address,
          constructorArguments: args,
        })
      } catch (err) {
        console.log(err)
        continue
      }
    }
  }
)

task('verify:all', 'Verifies all contracts on etherscan').setAction(
  async (taskArgs, hre) => {
    await hre.run('verify:contract', { contract: 'LiquidMiningDiamond' })
    await hre.run('verify:facets')
  }
)
