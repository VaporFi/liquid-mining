import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { logTx } from '../utils'

const REFERENCE_VAPE_PRICE = 0.606
const FLOOR_BPS = 2500 // 25%
const NUM_TIERS = 11

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

task(
    'mining-pass:update-fees',
    'Update mining pass fees based on current VAPE price'
)
    .addOptionalParam('vapePrice', 'Override VAPE price (USD) instead of fetching')
    .addFlag('dryRun', 'Print what would happen without sending transactions')
    .setAction(async ({ vapePrice, dryRun }, { ethers, network }) => {
        const diamondAddress =
            LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
                .address

        const DiamondManagerFacet = await ethers.getContractAt(
            'DiamondManagerFacet',
            diamondAddress
        )

        // ── 1. Fetch VAPE price ──────────────────────────────────────────
        const currentVAPEPrice = vapePrice
            ? parseFloat(vapePrice)
            : await fetchVAPEPrice()

        console.log(`\n💰 VAPE Price: $${currentVAPEPrice.toFixed(4)}`)
        console.log(
            `📐 Multiplier: ${((currentVAPEPrice / REFERENCE_VAPE_PRICE) * 100).toFixed(1)}% of reference ($${REFERENCE_VAPE_PRICE})`
        )

        // ── 2. Read base fees from contract ──────────────────────────────
        const baseFees: bigint[] = []
        for (let i = 0; i < NUM_TIERS; i++) {
            const fee = await DiamondManagerFacet.getBaseMiningPassTierFee(i)
            baseFees.push(fee)
        }

        // ── 3. Read current fees from contract ───────────────────────────
        const currentFees: bigint[] = []
        for (let i = 0; i < NUM_TIERS; i++) {
            const fee = await DiamondManagerFacet.getMiningPassTierFee(i)
            currentFees.push(fee)
        }

        // ── 4. Calculate dynamic fees ────────────────────────────────────
        const dynamicFees = calculateDynamicFees(
            baseFees,
            currentVAPEPrice,
            FLOOR_BPS
        )

        console.log('\n📋 Mining Pass Fee Update:')
        console.log('Tier | Base Fee ($) | Current ($) | New Fee ($) | Change')
        console.log('-----|-------------|-------------|-------------|-------')
        for (let i = 0; i < NUM_TIERS; i++) {
            const base = Number(baseFees[i]) / 1e6
            const current = Number(currentFees[i]) / 1e6
            const dynamic = Number(dynamicFees[i]) / 1e6
            const change =
                base > 0 ? `${(((dynamic - base) / base) * 100).toFixed(0)}%` : '-'
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
        const feesTx = await DiamondManagerFacet.setMiningPassFees(dynamicFees)
        await logTx(feesTx)
        console.log('✅ Mining pass fees updated')
    })
