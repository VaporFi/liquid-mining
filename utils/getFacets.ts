import fs from 'fs'
import path from 'path'

// Load facets from the src/facets folder, return an array of facet names
function getFacets(omit: string[] = ['DiamondCutFacet']) {
  const facets = fs
    .readdirSync('./src/facets')
    .map((file) => path.parse(file).name)

  // return array, filter out "DiamondCutFacet" and any omitted facets
  return facets.filter((facet) => !omit.includes(facet))
}

export default getFacets
