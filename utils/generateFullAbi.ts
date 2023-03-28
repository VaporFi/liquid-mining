import { Interface } from '@ethersproject/abi'
import { readdirSync, readFileSync, writeFileSync } from 'fs'

export function generateFullABI() {
  const fileNames = readdirSync('./deployments')
  let fullAbi: Interface[] = []
  for (const fileName of fileNames) {
    const fileData = readFileSync(`./deployments/${fileName}`, 'utf8')
    const abi = JSON.parse(fileData)?.avalanche?.artifact?.abi
    abi?.map((i: Interface) => (fullAbi?.includes(i) ? null : fullAbi?.push(i)))
  }
  writeFileSync('./abi/fullDiamond.json', JSON.stringify(fullAbi, null, 4))
}
