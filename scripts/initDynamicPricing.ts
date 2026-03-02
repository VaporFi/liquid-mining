import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { logTx } from '../utils'

const BASE_FEES = [
    0, // Tier 0
    0.5 * 1e6, // Tier 1
    1 * 1e6, // Tier 2
    2 * 1e6, // Tier 3
    4 * 1e6, // Tier 4
    8 * 1e6, // Tier 5
    15 * 1e6, // Tier 6
    30 * 1e6, // Tier 7
    50 * 1e6, // Tier 8
    75 * 1e6, // Tier 9
    100 * 1e6, // Tier 10
]

async function main() {
    const diamondAddress =
        LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
            .address

    console.log(`💎 Diamond: ${diamondAddress} on ${network.name}`)

    const manager = await ethers.getContractAt(
        'DiamondManagerFacet',
        diamondAddress
    )

    // Set base fees
    console.log('⏳ Setting base mining pass fees...')
    const baseFeeTx = await manager.setBaseMiningPassFees(BASE_FEES)
    await logTx(baseFeeTx)

    // Set floor
    console.log('⏳ Setting mining pass fee floor to 25%...')
    const floorTx = await manager.setMiningPassFeeFloor(2500)
    await logTx(floorTx)

    // Verify
    const baseFee10 = await manager.getBaseMiningPassTierFee(10)
    const floorBps = await manager.getMiningPassFeeFloorBps()
    console.log(`\n✅ Verified:`)
    console.log(`   Base fee tier 10: $${Number(baseFee10) / 1e6}`)
    console.log(`   Floor: ${Number(floorBps) / 100}%`)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
