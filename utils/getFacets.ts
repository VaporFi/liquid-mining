import fs from 'fs'
import path from 'path'

// Load facets from the src/facets folder, return an array of facet names
function getFacets() {
  return fs.readdirSync('./src/facets').map((file) => path.parse(file).name)
}

export default getFacets
