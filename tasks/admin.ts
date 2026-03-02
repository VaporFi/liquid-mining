import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { addresses } from '../config/addresses'
import { BURN_WALLET } from '../config/constants'

task('admin:authorize', 'Authorize an address to perform admin actions')
  .addParam('address')
  .setAction(async ({ address }, { ethers, network }) => {
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const AuthorizationFacet = await ethers.getContractAt(
      'AuthorizationFacet',
      diamondAddress
    )

    await AuthorizationFacet.authorize(address)
  })

task('admin:set-boost-fee-receivers', 'Set boost fee receivers').setAction(
  async (params, { ethers, network }) => {
    const CHAIN_ID = ['avalanche', 'fuji'].includes(network.name)
      ? network.config?.chainId || '43113'
      : '43113'
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const DiamondManagerFacet = await ethers.getContractAt(
      'DiamondManagerFacet',
      diamondAddress
    )

    const args = {
      receivers: [
        addresses.teamMultisig[CHAIN_ID],
        addresses.xVAPE[CHAIN_ID],
        addresses.passportPool[CHAIN_ID],
      ],
      proportion: [6000, 3000, 1000], // 100% == 10_000
    }

    await DiamondManagerFacet.setBoostFeeReceivers(
      args.receivers,
      args.proportion
    )
  }
)

task(
  'admin:set-mining-pass-fee-receivers',
  'Set mining pass fee receivers'
).setAction(async (params, { ethers, network }) => {
  const CHAIN_ID = ['avalanche', 'fuji'].includes(network.name)
    ? network.config?.chainId || '43113'
    : '43113'
  const diamondAddress =
    LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
      .address
  const DiamondManagerFacet = await ethers.getContractAt(
    'DiamondManagerFacet',
    diamondAddress
  )

  const args = {
    receivers: [
      addresses.xVAPE[CHAIN_ID],
      addresses.teamMultisig[CHAIN_ID],
      addresses.passportPool[CHAIN_ID],
    ],
    proportion: [6500, 3000, 500], // 100% == 10_000
  }

  await DiamondManagerFacet.setMiningPassFeeReceivers(
    args.receivers,
    args.proportion
  )
})

task('admin:set-unlock-fee-receivers', 'Set unlock fee receivers').setAction(
  async (params, { ethers, network }) => {
    const CHAIN_ID = ['avalanche', 'fuji'].includes(network.name)
      ? network.config?.chainId || '43113'
      : '43113'
    const diamondAddress =
      LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
        .address
    const DiamondManagerFacet = await ethers.getContractAt(
      'DiamondManagerFacet',
      diamondAddress
    )

    await DiamondManagerFacet.setUnlockFeeReceivers(
      [
        addresses.vpndReplenishmentPool[CHAIN_ID],
        addresses.teamMultisig[CHAIN_ID],
        BURN_WALLET,
      ],
      [8000, 1000, 1000] // 100% == 10_000
    )
  }
)
