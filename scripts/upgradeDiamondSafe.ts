import Safe, { EthersAdapter } from '@safe-global/protocol-kit'
import { ethers, network } from 'hardhat'
import TokenFactoryDiamond from '../deployments/LiquidMiningDiamond.json'
import { deployContract } from '../utils/deployContract'
import { addOrReplaceFacets } from '../utils/diamond'
import getFacets from '../utils/getFacets'
import { addresses } from '../config/addresses'

async function main() {
  console.log('💎 Upgrading diamond')
  const CHAIN_ID = ['avalanche', 'fuji'].includes(network.name)
    ? network.config?.chainId || '43113'
    : '43113'
  const diamondAddress =
    TokenFactoryDiamond[network.name as keyof typeof TokenFactoryDiamond]
      .address

  // Deploy Facets
  const FacetNames = getFacets(['DiamondCutFacet', 'DiamondLoupeFacet'])

  const Facets = []
  for (const name of FacetNames) {
    Facets.push(await deployContract(name))
  }

  // Create Safe Adapter
  const [deployer] = await ethers.getSigners()
  const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: deployer })
  const safeSdk = await Safe.create({
    ethAdapter,
    safeAddress: addresses.teamMultiSig[CHAIN_ID],
  })

  // Do diamond cut
  console.log('💎 Adding facets')
  await addOrReplaceFacets(
    Facets,
    diamondAddress,
    undefined,
    undefined,
    safeSdk
  )

  console.log('✅ Diamond upgraded')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
