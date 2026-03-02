import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { deployContract } from '../utils/deployContract'
import { addOrReplaceFacets } from '../utils/diamond'
import yargs from 'yargs'

const argv = yargs(process.argv.slice(2)).options({
  facetName: {
    type: 'string',
    description: 'The name of the facet to upgrade',
  },
  network: {
    type: 'string',
    description: 'The network to deploy to',
    default: 'fuji',
  },
}).argv

async function main() {
  const { facetName, network } = await argv

  if (!facetName) {
    throw new Error('Facet name is required')
  }

  console.log('Upgrading facet', facetName)
  const diamondAddress =
    LiquidMiningDiamond[network as keyof typeof LiquidMiningDiamond].address
  const facet = await deployContract(facetName)

  await addOrReplaceFacets([facet], diamondAddress)
  console.log('✅ Facet upgraded')
}

// i.e yarn hardhat run --network avalanche scripts/upgradeFacet.ts --facetName DiamondManagerFacet
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
