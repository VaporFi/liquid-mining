import { expect } from 'chai'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import deployDiamond from '../scripts/deploy/deployDiamond'
import { ethers } from 'hardhat'
import { DepositFacet } from '../typechain-types'

describe('LiquidMiningDiamond', function () {
  async function deployLiquidMiningDiamond() {
    const diamond = await deployDiamond()
    const diamondAddress = await diamond.getAddress()
    const DepositFacet = await ethers.getContractAt(
      'DepositFacet',
      diamondAddress
    )
    const DiamondManagerFacet = await ethers.getContractAt(
      'DiamondManagerFacet',
      diamondAddress
    )
    const [deployer, user1, user2, user3] = await ethers.getSigners()

    return {
      diamond,
      diamondAddress,
      DepositFacet: DepositFacet as unknown as DepositFacet,
      DiamondManagerFacet,
      deployer,
      user1,
      user2,
      user3,
    }
  }

  before(async function () {})

  it('Should deploy LiquidMiningDiamond', async function () {
    const { diamondAddress } = await loadFixture(deployLiquidMiningDiamond)
    expect(diamondAddress).to.not.equal(0)
  })
})
