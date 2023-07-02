import { expect } from 'chai'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

describe('LiquidMiningDiamond', function () {
  async function deployLiquidMiningDiamond() {
    const LiquidMiningDiamond = await ethers.getContractFactory(
      'LiquidMiningDiamond'
    )
    const liquidMiningDiamond = await LiquidMiningDiamond.deploy()
    await liquidMiningDiamond.deployed()
    return liquidMiningDiamond
  }

  it('Should deploy LiquidMiningDiamond', async function () {
    const liquidMiningDiamond = await loadFixture(deployLiquidMiningDiamond)
    expect(liquidMiningDiamond.address).to.not.equal(0)
  })
})
