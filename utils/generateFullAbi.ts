import { Interface } from '@ethersproject/abi'
import { writeFileSync } from 'fs'
import getFacets from './getFacets'
import { artifacts } from 'hardhat'

export async function generateFullABI() {
  const combinedABI: Interface[] = []
  const facets = getFacets()
  for (const facet of facets) {
    const artifact = await artifacts.readArtifact(facet)
    writeFileSync(`./abis/${facet}.json`, JSON.stringify(artifact.abi, null, 4))
    combinedABI.push(...artifact.abi)
  }
  writeFileSync('./abi/fullDiamond.json', JSON.stringify(combinedABI, null, 4))
}

generateFullABI()
