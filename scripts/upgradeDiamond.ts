import { network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { deployContract } from '../utils/deployContract'
import { addOrReplaceFacets } from '../utils/diamond'
import { defaultArgs } from './deploy/deployDiamond'

async function main() {
  console.log('💎 Upgrading diamond')
  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  // Deploy DiamondInit
  const diamondInit = await deployContract('DiamondInit')

  // Deploy Facets
  const BoostFacet = await deployContract('BoostFacet')
  const ClaimFacet = await deployContract('ClaimFacet')
  const DepositFacet = await deployContract('DepositFacet')
  const DiamondManagerFacet = await deployContract('DiamondManagerFacet')
  const FeeCollectorFacet = await deployContract('FeeCollectorFacet')
  const RestakeFacet = await deployContract('RestakeFacet')
  const UnlockFacet = await deployContract('UnlockFacet')
  const WithdrawFacet = await deployContract('WithdrawFacet')

  // Do diamond cut
  const args = defaultArgs
  const functionCall = diamondInit.interface.encodeFunctionData('init', [
    Object.values(args),
  ])
  await addOrReplaceFacets(
    [
      BoostFacet,
      ClaimFacet,
      DepositFacet,
      DiamondManagerFacet,
      FeeCollectorFacet,
      RestakeFacet,
      UnlockFacet,
      WithdrawFacet,
    ],
    diamondAddress,
    diamondInit.address,
    functionCall
  )
  console.log('✅ Diamond upgraded')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
