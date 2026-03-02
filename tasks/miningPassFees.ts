import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { logTx } from '../utils'

const REFERENCE_VAPE_PRICE = 0.606
const FLOOR_BPS = 2500 // 25%
const NUM_TIERS = 11

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function fetchVAPEPrice(): Promise<number> {
    const response = await fetch(
        'https://api.coingecko.com/api/v3/simple/price?ids=vaporfi&vs_currencies=usd'
    )
    const data = (await response.json()) as { vaporfi?: { usd?: number } }
    const price = data.vaporfi?.usd
    if (!price) throw new Error('Failed to fetch VAPE price from CoinGecko')
    return price
}

function calculateDynamicFees(
    baseFees: bigint[],
    vapePrice: number,
    floorBps: number
): bigint[] {
    const multiplierBps = Math.floor((vapePrice / REFERENCE_VAPE_PRICE) * 10000)

    return baseFees.map((baseFee) => {
        const floorFee = (baseFee * BigInt(floorBps)) / 10000n
        const dynamicFee = (baseFee * BigInt(multiplierBps)) / 10000n
        return dynamicFee > floorFee ? dynamicFee : floorFee
    })
}

function getDiamondAddress(networkName: string): string {
    return LiquidMiningDiamond[networkName as keyof typeof LiquidMiningDiamond]
        .address
}

function fmtUSDC(val: bigint | number): string {
    return (Number(val) / 1e6).toFixed(2)
}

// ─── Read Task ───────────────────────────────────────────────────────────────

task(
    'mining-pass:read',
    'Read current dynamic mining pass pricing parameters from the contract'
)
    .addOptionalParam('tier', 'Read a specific tier only (0-10)')
    .setAction(async ({ tier }, { ethers, network }) => {
        const diamondAddress = getDiamondAddress(network.name)
        const manager = await ethers.getContractAt(
            'DiamondManagerFacet',
            diamondAddress
        )

        console.log(`\n💎 Diamond: ${diamondAddress} (${network.name})`)

        // Floor BPS
        const floorBps = await manager.getMiningPassFeeFloorBps()
        console.log(
            `\n📐 Fee Floor: ${Number(floorBps)} bps (${(Number(floorBps) / 100).toFixed(1)}%)`
        )

        // Single tier
        if (tier !== undefined) {
            const t = parseInt(tier)
            if (t < 0 || t > 10) throw new Error('Tier must be 0-10')

            const currentFee = await manager.getMiningPassTierFee(t)
            const baseFee = await manager.getBaseMiningPassTierFee(t)
            const floorFee = await manager.getMiningPassTierFloorFee(t)
            const depositLimit = await manager.getMiningPassTierDepositLimit(t)

            console.log(`\n── Tier ${t} ──`)
            console.log(`  Base Fee:      $${fmtUSDC(baseFee)}`)
            console.log(`  Current Fee:   $${fmtUSDC(currentFee)}`)
            console.log(`  Floor Fee:     $${fmtUSDC(floorFee)}`)
            console.log(
                `  Deposit Limit: ${depositLimit === BigInt(2) ** BigInt(256) - BigInt(1) ? '∞' : `${(Number(depositLimit) / 1e18).toLocaleString()} VPND`}`
            )
            return
        }

        // All tiers
        console.log(
            '\nTier | Base Fee ($) | Current ($) | Floor ($)   | Deposit Limit'
        )
        console.log(
            '-----|-------------|-------------|-------------|--------------------'
        )

        for (let i = 0; i < NUM_TIERS; i++) {
            const baseFee = await manager.getBaseMiningPassTierFee(i)
            const currentFee = await manager.getMiningPassTierFee(i)
            const floorFee = await manager.getMiningPassTierFloorFee(i)
            const depositLimit = await manager.getMiningPassTierDepositLimit(i)
            const limitStr =
                depositLimit === BigInt(2) ** BigInt(256) - BigInt(1)
                    ? '∞'
                    : `${(Number(depositLimit) / 1e18).toLocaleString()} VPND`

            console.log(
                `  ${i.toString().padStart(2)} | ${fmtUSDC(baseFee).padStart(11)} | ${fmtUSDC(currentFee).padStart(11)} | ${fmtUSDC(floorFee).padStart(11)} | ${limitStr}`
            )
        }
    })

// ─── Update Fees Task ────────────────────────────────────────────────────────

task(
    'mining-pass:update-fees',
    'Update mining pass fees based on current VAPE price'
)
    .addOptionalParam(
        'vapePrice',
        'Override VAPE price (USD) instead of fetching'
    )
    .addFlag('dryRun', 'Print what would happen without sending transactions')
    .setAction(async ({ vapePrice, dryRun }, { ethers, network }) => {
        const diamondAddress = getDiamondAddress(network.name)
        const manager = await ethers.getContractAt(
            'DiamondManagerFacet',
            diamondAddress
        )

        // ── 1. Fetch VAPE price ──────────────────────────────────────────
        let currentVAPEPrice: number
        if (vapePrice) {
            const parsed = parseFloat(vapePrice)
            if (!Number.isFinite(parsed) || parsed <= 0) {
                throw new Error(
                    `Invalid --vape-price "${vapePrice}": must be a finite number > 0`
                )
            }
            currentVAPEPrice = parsed
        } else {
            currentVAPEPrice = await fetchVAPEPrice()
        }

        console.log(`\n💰 VAPE Price: $${currentVAPEPrice.toFixed(4)}`)
        console.log(
            `📐 Multiplier: ${((currentVAPEPrice / REFERENCE_VAPE_PRICE) * 100).toFixed(1)}% of reference ($${REFERENCE_VAPE_PRICE})`
        )

        // ── 2. Read base fees from contract ──────────────────────────────
        const baseFees: bigint[] = []
        for (let i = 0; i < NUM_TIERS; i++) {
            const fee = await manager.getBaseMiningPassTierFee(i)
            baseFees.push(fee)
        }

        // ── 3. Read current fees from contract ───────────────────────────
        const currentFees: bigint[] = []
        for (let i = 0; i < NUM_TIERS; i++) {
            const fee = await manager.getMiningPassTierFee(i)
            currentFees.push(fee)
        }

        // ── 4. Read on-chain floor & calculate dynamic fees ─────────────
        const onChainFloorBps = Number(await manager.getMiningPassFeeFloorBps())
        const effectiveFloorBps =
            onChainFloorBps > 0 ? onChainFloorBps : FLOOR_BPS
        console.log(
            `🛡️  Floor: ${effectiveFloorBps} bps (${(effectiveFloorBps / 100).toFixed(1)}%)${onChainFloorBps === 0 ? ' [fallback — on-chain not set]' : ''}`
        )

        const dynamicFees = calculateDynamicFees(
            baseFees,
            currentVAPEPrice,
            effectiveFloorBps
        )

        console.log('\n📋 Mining Pass Fee Update:')
        console.log(
            'Tier | Base Fee ($) | Current ($) | New Fee ($) | Change'
        )
        console.log(
            '-----|-------------|-------------|-------------|-------'
        )
        for (let i = 0; i < NUM_TIERS; i++) {
            const base = Number(baseFees[i]) / 1e6
            const current = Number(currentFees[i]) / 1e6
            const dynamic = Number(dynamicFees[i]) / 1e6
            const change =
                base > 0
                    ? `${(((dynamic - base) / base) * 100).toFixed(0)}%`
                    : '-'
            console.log(
                `  ${i.toString().padStart(2)} | ${base.toFixed(2).padStart(11)} | ${current.toFixed(2).padStart(11)} | ${dynamic.toFixed(2).padStart(11)} | ${change}`
            )
        }

        if (dryRun) {
            console.log('\n🏁 Dry run complete — no transactions sent.')
            return
        }

        // ── 5. Update mining pass fees ───────────────────────────────────
        console.log('\n⏳ Updating mining pass fees...')
        const feesTx = await manager.setMiningPassFees(dynamicFees)
        await logTx(feesTx)
        console.log('✅ Mining pass fees updated')
    })

// ─── Set Base Fees Task ──────────────────────────────────────────────────────

task(
    'mining-pass:set-base-fees',
    'Set the base (reference) mining pass fees on-chain'
)
    .addFlag('dryRun', 'Print what would be set without sending transactions')
    .setAction(async ({ dryRun }, { ethers, network }) => {
        const diamondAddress = getDiamondAddress(network.name)
        const manager = await ethers.getContractAt(
            'DiamondManagerFacet',
            diamondAddress
        )

        const BASE_FEES = [
            0n, // Tier 0
            500_000n, // Tier 1  – $0.50
            1_000_000n, // Tier 2  – $1
            2_000_000n, // Tier 3  – $2
            4_000_000n, // Tier 4  – $4
            8_000_000n, // Tier 5  – $8
            15_000_000n, // Tier 6  – $15
            30_000_000n, // Tier 7  – $30
            50_000_000n, // Tier 8  – $50
            75_000_000n, // Tier 9  – $75
            100_000_000n, // Tier 10 – $100
        ]

        console.log(`\n💎 Diamond: ${diamondAddress} (${network.name})`)
        console.log('\n📋 Base fees to set:')
        for (let i = 0; i < NUM_TIERS; i++) {
            console.log(`  Tier ${i.toString().padStart(2)}: $${fmtUSDC(BASE_FEES[i])}`)
        }

        if (dryRun) {
            console.log('\n🏁 Dry run complete — no transactions sent.')
            return
        }

        console.log('\n⏳ Setting base mining pass fees...')
        const tx = await manager.setBaseMiningPassFees(BASE_FEES)
        await logTx(tx)
        console.log('✅ Base mining pass fees set')
    })

// ─── Set Floor Task ──────────────────────────────────────────────────────────

task('mining-pass:set-floor', 'Set the mining pass fee floor in basis points')
    .addParam('bps', 'Floor in basis points (e.g. 2500 = 25%)')
    .addFlag('dryRun', 'Print what would be set without sending transactions')
    .setAction(async ({ bps, dryRun }, { ethers, network }) => {
        const diamondAddress = getDiamondAddress(network.name)
        const manager = await ethers.getContractAt(
            'DiamondManagerFacet',
            diamondAddress
        )

        const floorBps = parseInt(bps)
        if (isNaN(floorBps) || floorBps < 0 || floorBps > 10000) {
            throw new Error('bps must be between 0 and 10000')
        }

        const currentFloor = await manager.getMiningPassFeeFloorBps()

        console.log(`\n💎 Diamond: ${diamondAddress} (${network.name})`)
        console.log(
            `  Current floor: ${Number(currentFloor)} bps (${(Number(currentFloor) / 100).toFixed(1)}%)`
        )
        console.log(
            `  New floor:     ${floorBps} bps (${(floorBps / 100).toFixed(1)}%)`
        )

        if (dryRun) {
            console.log('\n🏁 Dry run complete — no transactions sent.')
            return
        }

        console.log('\n⏳ Setting mining pass fee floor...')
        const tx = await manager.setMiningPassFeeFloor(floorBps)
        await logTx(tx)
        console.log('✅ Mining pass fee floor updated')
    })

// ─── Init Dynamic Pricing Task ──────────────────────────────────────────────

task(
    'mining-pass:init',
    'Initialise dynamic pricing (set base fees + floor) — run once after upgrade'
)
    .addFlag('dryRun', 'Print what would be set without sending transactions')
    .setAction(async ({ dryRun }, { ethers, network }) => {
        const diamondAddress = getDiamondAddress(network.name)
        const manager = await ethers.getContractAt(
            'DiamondManagerFacet',
            diamondAddress
        )

        const BASE_FEES = [
            0n,
            500_000n,
            1_000_000n,
            2_000_000n,
            4_000_000n,
            8_000_000n,
            15_000_000n,
            30_000_000n,
            50_000_000n,
            75_000_000n,
            100_000_000n,
        ]

        console.log(`\n💎 Diamond: ${diamondAddress} (${network.name})`)

        // Check current state
        const currentFloor = await manager.getMiningPassFeeFloorBps()
        const currentBase5 = await manager.getBaseMiningPassTierFee(5)
        console.log(
            `  Current floor: ${Number(currentFloor)} bps | Base tier 5: $${fmtUSDC(currentBase5)}`
        )

        if (Number(currentFloor) !== 0 || Number(currentBase5) !== 0) {
            console.log(
                '\n⚠️  Dynamic pricing appears already initialised. Use individual tasks to update.'
            )
            return
        }

        console.log('\n📋 Will set:')
        console.log('  Base fees (11 tiers) + Floor = 2500 bps (25%)')
        for (let i = 0; i < NUM_TIERS; i++) {
            console.log(`  Tier ${i.toString().padStart(2)}: $${fmtUSDC(BASE_FEES[i])}`)
        }

        if (dryRun) {
            console.log('\n🏁 Dry run complete — no transactions sent.')
            return
        }

        console.log('\n⏳ Setting base mining pass fees...')
        const baseFeeTx = await manager.setBaseMiningPassFees(BASE_FEES)
        await logTx(baseFeeTx)

        console.log('⏳ Setting mining pass fee floor to 2500 bps (25%)...')
        const floorTx = await manager.setMiningPassFeeFloor(2500)
        await logTx(floorTx)

        // Verify
        const newFloor = await manager.getMiningPassFeeFloorBps()
        const newBase10 = await manager.getBaseMiningPassTierFee(10)
        console.log(`\n✅ Dynamic pricing initialised:`)
        console.log(`   Base fee tier 10: $${fmtUSDC(newBase10)}`)
        console.log(
            `   Floor: ${Number(newFloor)} bps (${(Number(newFloor) / 100).toFixed(1)}%)`
        )
    })
