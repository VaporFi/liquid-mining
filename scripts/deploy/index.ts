import deployDiamond, { FacetNames } from './deployDiamond'
import { Contract } from 'ethers'
import { ethers, network } from 'hardhat'
import { addresses } from '../../config/addresses'

async function main() {
  // Deploy VaporNodesDiamond
  const diamond = await deployDiamond()

  // Get facets
  const facets: { [K in (typeof FacetNames)[number]]: Contract } = {} as any

  // for (const facetName of FacetNames) {
  //   const facet = await ethers.getContractAt(facetName, diamond.address)
  //   facets[facetName] = facet
  // }

  const DiamondManagerFacet = await ethers.getContractAt(
    'DiamondManagerFacet',
    diamond.address
  )
  const OwnershipFacet = await ethers.getContractAt(
    'OwnershipFacet',
    diamond.address
  )

  // Start first season
  await (
    await DiamondManagerFacet.startNewSeasonWithDuration(
      ethers.utils.parseEther('15000'),
      2
    )
  ).wait()
  console.log('Season started')

  const currentSeason = await DiamondManagerFacet.getCurrentSeasonData()
  console.log('Current season', currentSeason)

  // Transfer ownership to labs multisig
  if (network.name !== 'avalanche') return
  await (
    await OwnershipFacet.transferOwnership(addresses.teamMultisig['43113'])
  ).wait()
  console.log('Ownership transferred')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
