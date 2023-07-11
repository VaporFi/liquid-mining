import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'

task(
  'season:changeBoostPoints',
  'Changes boost point to provided value'
).setAction(async ({}, { ethers, network }) => {
  const [addresses, amounts] = await addressesWithWrongPoints()
  if (addresses?.length !== amounts?.length)
    throw new Error('Amounts and address mismatch')

  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  const DiamondManagerFacet = await ethers.getContractAt(
    'DiamondManagerFacet',
    diamondAddress
  )

  const addressesWithPointsBeforeBoost = await Promise.all(
    addresses?.map(async (address) => {
      await DiamondManagerFacet?.getUserPoints(address)
    })
  )
  console.log(addressesWithPointsBeforeBoost)
})

const addressesWithWrongPoints = async (): Promise<[string[], string[]]> => {
  const [minimumBlock, maximumBlock] = [32439484, 32454282]
  const subgraphUrl =
    'https://api.thegraph.com/subgraphs/name/vaporfi/liquid-mining'

  const query = `query {
    claimBoosts(first: 1000, orderBy:blockNumber, orderDirection:desc, where:{blockNumber_gt:32439484, blockNumber_lt:32454282}) {
     id
    _user
    _seasonId
    _boostPoints
    tier
}
}`
  const result = await fetch(subgraphUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      query,
    }),
  }).then(async (res) => await res.json())
  const allBoostEventsInRange = result?.data?.claimBoosts
  if (allBoostEventsInRange && allBoostEventsInRange?.length > 0) {
    const allAddresses = allBoostEventsInRange?.map(
      ({ _user }: { _user: string }) => _user
    )
    const allAmounts = allBoostEventsInRange?.map(
      ({ _boostPoints }: { _boostPoints: BigInt }) => _boostPoints?.toString()
    )
    return [allAddresses, allAmounts]
  }
  return [[], []]
}
