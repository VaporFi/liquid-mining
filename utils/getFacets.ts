import fs from 'fs'
import path from 'path'

// Load facets from the src/facets folder, return an array of facet names
function getFacets() {
  const facets = fs
    .readdirSync('./src/facets')
    .map((file) => path.parse(file).name)

  // return array, filter out "DiamondCutFacet"
  return facets.filter((facet) => facet !== 'DiamondCutFacet')
}

export default getFacets
