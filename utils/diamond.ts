import {
  BaseContract,
  Contract,
  ZeroAddress,
  Fragment,
  FunctionFragment,
} from 'ethers'
import { ethers } from 'hardhat'
import { IDiamondLoupe } from '../typechain-types'

export type FacetCut = {
  facetAddress: string
  action: number
  functionSelectors: string[]
}

export enum FacetCutAction {
  Add = 0,
  Replace = 1,
  Remove = 2,
}

export function getSelectors(contract: BaseContract): string[] {
  const selectors: string[] = []
  contract.interface.forEachFunction((func) => {
    selectors.push(func.selector)
  })
  return selectors
}

export async function addOrReplaceFacets(
  facets: BaseContract[],
  diamondAddress: string,
  initContract: string = ZeroAddress,
  initData = '0x'
): Promise<void> {
  const loupe = <IDiamondLoupe>(
    await ethers.getContractAt('IDiamondLoupe', diamondAddress)
  )

  const cut = []
  for (const f of facets) {
    const replaceSelectors = []
    const addSelectors = []
    const facetAddress = await f.getAddress()

    const selectors = getSelectors(f)

    for (const s of selectors) {
      const addr = await loupe.facetAddress(s.toString())

      if (addr === ZeroAddress) {
        addSelectors.push(s)
        continue
      }

      if (addr.toLowerCase() !== (await f.getAddress()).toLowerCase()) {
        replaceSelectors.push(s)
      }
    }

    if (replaceSelectors.length) {
      cut.push({
        facetAddress,
        action: FacetCutAction.Replace,
        functionSelectors: replaceSelectors,
      })
    }
    if (addSelectors.length) {
      cut.push({
        facetAddress,
        action: FacetCutAction.Add,
        functionSelectors: addSelectors,
      })
    }
  }

  if (!cut.length) {
    console.log('No facets to add or replace.')
    return
  }

  console.log('Adding/Replacing facet(s)...', diamondAddress, cut)
  await doCut(diamondAddress, cut, initContract, initData)

  console.log('Done.')
}

export async function addFacets(
  facets: BaseContract[],
  diamondAddress: string,
  initContract: string = ZeroAddress,
  initData = '0x'
): Promise<void> {
  const cut = []
  for (const f of facets) {
    const selectors = getSelectors(f)
    const facetAddress = await f.getAddress()

    cut.push({
      facetAddress,
      action: FacetCutAction.Add,
      functionSelectors: selectors,
    })
  }

  if (!cut.length) {
    console.log('No facets to add or replace.')
    return
  }

  console.log('Adding facet(s)...')
  await doCut(diamondAddress, cut, initContract, initData)

  console.log('Done.')
}

export async function removeFacet(
  selectors: string[],
  diamondAddress: string
): Promise<void> {
  const cut = [
    {
      facetAddress: ZeroAddress,
      action: FacetCutAction.Remove,
      functionSelectors: selectors,
    },
  ]

  console.log('Removing facet...')
  await doCut(diamondAddress, cut, ZeroAddress, '0x')

  console.log('Done.')
}

export async function replaceFacet(
  facet: Contract,
  diamondAddress: string,
  initContract: string = ZeroAddress,
  initData = '0x'
): Promise<void> {
  const selectors = getSelectors(facet)

  const cut = [
    {
      facetAddress: facet.address,
      action: FacetCutAction.Replace,
      functionSelectors: selectors,
    },
  ]

  console.log('Replacing facet...')
  await doCut(diamondAddress, cut, initContract, initData)

  console.log('Done.')
}

async function doCut(
  diamondAddress: string,
  cut: any[],
  initContract: string,
  initData: string
): Promise<void> {
  const cutter = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
  console.log('Cutting diamond...')

  console.log(
    '🚀 ~ file: diamond.ts:168 ~ cut, initContract, initData:',
    cut,
    initContract,
    initData
  )
  const tx = await cutter.diamondCut(cut, initContract, initData)
  const receipt = await tx.wait()
  if (!receipt?.status) {
    throw Error(`Diamond upgrade failed: ${tx.data}`)
  }
}
