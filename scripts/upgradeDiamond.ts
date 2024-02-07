import { network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { deployContract } from '../utils/deployContract'
import { addOrReplaceFacets } from '../utils/diamond'
import { defaultArgs } from './deploy/deployDiamond'
import getFacets from '../utils/getFacets'

async function main() {
  console.log('💎 Upgrading diamond')
  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address

  // Deploy Facets
  const FacetNames = getFacets(['DiamondCutFacet', 'DiamondLoupeFacet'])

  // const Facets = await Promise.all(
  //   FacetNames.map((name) => deployContract(name))
  // )
  const Facets = []
  for (const name of FacetNames) {
    Facets.push(await deployContract(name))
  }

  // Do diamond cut
  await addOrReplaceFacets(Facets, diamondAddress)
  console.log('✅ Diamond upgraded')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
