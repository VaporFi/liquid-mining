import { Interface } from '@ethersproject/abi'
import { readdirSync, readFileSync, writeFileSync } from 'fs'

export function generateFullABI() {
  const folders = readdirSync('./abis/')
  let fullAbi: Interface[] = []
  for (const folder of folders) {
    const fileName = `${folder}`.split('.')[0] + '.json'
    const fileData = readFileSync(`./abis/${folder}/${fileName}`, 'utf8')
    const abi = JSON.parse(fileData).abi
    abi?.map((i: Interface) => (fullAbi?.includes(i) ? null : fullAbi?.push(i)))
  }
  writeFileSync('./abi/fullDiamond.json', JSON.stringify(fullAbi, null, 4))
}

generateFullABI()
