import { network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { deployContract } from '../utils/deployContract'
import { addOrReplaceFacets } from '../utils/diamond'

async function main(facetName: string) {
  console.log('Upgrading facet', facetName)
  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  const facet = await deployContract(facetName)

  await addOrReplaceFacets([facet], diamondAddress)
  console.log('✅ Facet upgraded')
}

main('BoostFacet')
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
