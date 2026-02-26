import { task } from 'hardhat/config'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { calculateReward, getNextMonthTimestamp, logTx } from '../utils'

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
    'season:start',
    'Update mining pass prices based on VAPE price, then start a new season'
)
    .addOptionalParam('vapePrice', 'Override VAPE price (USD) instead of fetching')
    .addOptionalParam('endTimestamp', 'Custom season end timestamp')
    .addFlag('dryRun', 'Print what would happen without sending transactions')
    .addFlag('skipClaim', 'Skip the claimTokensForSeason step (useful for testnet)')
    .setAction(async ({ vapePrice, endTimestamp, dryRun, skipClaim }, { ethers, network }) => {
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

        // ── 3. Calculate dynamic fees ────────────────────────────────────
        const dynamicFees = calculateDynamicFees(
            baseFees,
            currentVAPEPrice,
            FLOOR_BPS
        )

        console.log('\n📋 Mining Pass Fee Update:')
        console.log('Tier | Base Fee ($) | New Fee ($) | Change')
        console.log('-----|-------------|-------------|-------')
        for (let i = 0; i < NUM_TIERS; i++) {
            const base = Number(baseFees[i]) / 1e6
            const dynamic = Number(dynamicFees[i]) / 1e6
            const change =
                base > 0 ? `${(((dynamic - base) / base) * 100).toFixed(0)}%` : '-'
            console.log(
                `  ${i.toString().padStart(2)} | ${base.toFixed(2).padStart(11)} | ${dynamic.toFixed(2).padStart(11)} | ${change}`
            )
        }

        // ── 4. Calculate season rewards ──────────────────────────────────
        const currentSeasonId = await DiamondManagerFacet.getCurrentSeasonId()
        const nextSeasonId = Number(currentSeasonId) + 1
        const rewards = calculateReward(nextSeasonId)
        const parsedRewards = ethers.parseEther(rewards.toString())
        const seasonEnd = endTimestamp
            ? parseInt(endTimestamp)
            : getNextMonthTimestamp()

        console.log(`\n🔄 Season ${nextSeasonId}:`)
        console.log(`   Rewards: ${rewards.toFixed(2)} VAPE`)
        console.log(
            `   End: ${new Date(seasonEnd * 1000).toISOString().split('T')[0]}`
        )

        if (dryRun) {
            console.log('\n🏁 Dry run complete — no transactions sent.')
            return
        }

        // ── 5. Update mining pass fees ───────────────────────────────────
        console.log('\n⏳ Updating mining pass fees...')
        const feesTx = await DiamondManagerFacet.setMiningPassFees(dynamicFees)
        await logTx(feesTx)
        console.log('✅ Mining pass fees updated')

        // ── 6. Start new season ──────────────────────────────────────────
        console.log('⏳ Starting new season...')
        const startTx = await DiamondManagerFacet.startNewSeasonWithEndTimestamp(
            parsedRewards.toString(),
            seasonEnd
        )
        await logTx(startTx)
        console.log('✅ New season started')

        // ── 7. Claim tokens for season ───────────────────────────────────
        if (skipClaim) {
            console.log('⏭️  Skipping claimTokensForSeason (--skip-claim)')
        } else {
            console.log('⏳ Claiming VAPE tokens for season...')
            const claimTx = await DiamondManagerFacet.claimTokensForSeason()
            await logTx(claimTx)
            console.log('✅ VAPE minted')
        }

        console.log('\n🎉 All done!')
    })
