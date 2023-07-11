import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import wait from '../utils/wait'
import data from './data/pointsMismatchAddress.json'
import { AddressLike, BigNumberish } from 'ethers'
import { writeFileSync } from 'fs'
task(
  'season:changeBoostPoints',
  'Changes boost point to provided value'
).setAction(async ({}, { ethers, network }) => {
  await getAddressesWithWrongPoints()

  const [addresses, amounts, boostFractions] = data as [
    string[],
    string[],
    number[]
  ]

  if (
    addresses?.length !== amounts?.length ||
    boostFractions?.length !== amounts?.length ||
    boostFractions?.length !== addresses?.length
  )
    throw new Error('Amounts and address mismatch')

  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  const DiamondManagerFacet = await ethers.getContractAt(
    'DiamondManagerFacet',
    diamondAddress
  )

  const addressWithCorrectBoostPoints = {} as { [address: string]: BigInt }

  const seasonEndTimestamp = +(
    await DiamondManagerFacet.getSeasonEndTimestamp(1)
  )?.toString()

  const currentTimestamp = Math.floor(Date.now() / 1000)

  const daysUntilSeasonEnd = parseInt(
    ((seasonEndTimestamp - currentTimestamp) / 86400)?.toString()
  )

  for (let i = 0; i < addresses?.length; i++) {
    const address = addresses[i]

    const { boostPoints, depositAmount, depositPoints } =
      await DiamondManagerFacet?.getUserDataForCurrentSeason(address)

    //if this was first boost, difference will be 0
    const differenceInBoostPoints = +boostPoints?.toString() - +amounts[i]

    const oldTotalPoints = +depositPoints?.toString() + differenceInBoostPoints

    const oldCurrentTotalPoints =
      oldTotalPoints - +depositAmount?.toString() * daysUntilSeasonEnd //from the time of fix deployment

    const newBoostPoint =
      differenceInBoostPoints + oldCurrentTotalPoints * boostFractions[i]

    addressWithCorrectBoostPoints[address] = BigInt(newBoostPoint)

    await wait(500)
  }

  const txnArgs: [AddressLike[], BigNumberish[]] = [
    Object.keys(addressWithCorrectBoostPoints),
    //@ts-ignore
    Object.values(addressWithCorrectBoostPoints),
  ]
  //txn part
  // const response = await DiamondManagerFacet.changeBoostPoints(
  //   txnArgs[0],
  //   txnArgs[1]
  // )
  // console.log(response?.hash)
})

const getAddressesWithWrongPoints = async (): Promise<
  [string[], string[], number[]]
> => {
  const [minimumBlock, maximumBlock] = [32439484, 32454282]
  const subgraphUrl =
    'https://api.thegraph.com/subgraphs/name/vaporfi/liquid-mining'
  //1000 limit is sufficient, in fact there's less than 50 miscalculations
  const query = `query {
    claimBoosts(first: 1000, orderBy:blockNumber, orderDirection:desc, where:{blockNumber_gt:${minimumBlock}, blockNumber_lt:${maximumBlock}}) {
     id
    _user
    _seasonId
    _boostPoints
    boostLevel
    isStratosphereMember
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
    const boostFractions = allBoostEventsInRange?.map(
      ({
        boostLevel,
        isStratosphereMember,
      }: {
        boostLevel: number
        isStratosphereMember: boolean
      }) => {
        if (!isStratosphereMember) return 0.001 //0.1%
        return { [0]: 0.002, [1]: 0.0022, [2]: 0.0024, [3]: 0.0028 }[boostLevel]
      }
    )
    writeFileSync(
      './tasks/data/pointsMismatchAddress.json',
      JSON.stringify([allAddresses, allAmounts, boostFractions])
    )
    return [allAddresses, allAmounts, boostFractions]
  }
  return [[], [], []]
}
