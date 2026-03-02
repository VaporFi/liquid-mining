import { createPublicClient, http, formatUnits, parseUnits, type Address } from 'viem'
import { avalanche } from 'viem/chains'

const LIQUID_MINING_DIAMOND = '0xAe950fdd0CC79DDE64d3Fffd40fabec3f7ba368B' as Address
const VAPE_TOKEN = '0x7bddaF6DbAB30224AA2116c4291521C7a60D5f55' as Address

const REFERENCE_VAPE_PRICE = 0.606

const TIER_DEPOSIT_LIMITS: Record<number, bigint> = {
    0: parseUnits('5000', 18),
    1: parseUnits('10000', 18),
    2: parseUnits('25000', 18),
    3: parseUnits('60000', 18),
    4: parseUnits('150000', 18),
    5: parseUnits('350000', 18),
    6: parseUnits('800000', 18),
    7: parseUnits('1800000', 18),
    8: parseUnits('4500000', 18),
    9: parseUnits('12000000', 18),
    10: BigInt('115792089237316195423570985008687907853269984665640564039457584007913129639935'),
}

const ORIGINAL_TIER_FEES_USDC: Record<number, number> = {
    0: 0,
    1: 0.5,
    2: 1,
    3: 2,
    4: 4,
    5: 8,
    6: 15,
    7: 30,
    8: 50,
    9: 75,
    10: 100,
}

const diamondAbi = [
    {
        inputs: [],
        name: 'getCurrentSeasonId',
        outputs: [{ type: 'uint256' }],
        stateMutability: 'view',
        type: 'function',
    },
    {
        inputs: [{ name: 'seasonId', type: 'uint256' }],
        name: 'getSeasonData',
        outputs: [
            {
                components: [
                    { name: 'id', type: 'uint256' },
                    { name: 'startTimestamp', type: 'uint256' },
                    { name: 'endTimestamp', type: 'uint256' },
                    { name: 'rewardTokensToDistribute', type: 'uint256' },
                    { name: 'rewardTokenBalance', type: 'uint256' },
                    { name: 'totalDepositAmount', type: 'uint256' },
                    { name: 'totalClaimAmount', type: 'uint256' },
                    { name: 'totalPoints', type: 'uint256' },
                ],
                type: 'tuple',
            },
        ],
        stateMutability: 'view',
        type: 'function',
    },
    {
        inputs: [{ name: 'seasonId', type: 'uint256' }],
        name: 'getSeasonTotalPoints',
        outputs: [{ type: 'uint256' }],
        stateMutability: 'view',
        type: 'function',
    },
    {
        inputs: [{ name: 'seasonId', type: 'uint256' }],
        name: 'getTotalDepositAmountOfSeason',
        outputs: [{ type: 'uint256' }],
        stateMutability: 'view',
        type: 'function',
    },
    {
        inputs: [{ name: 'seasonId', type: 'uint256' }],
        name: 'getRewardTokensToDistribute',
        outputs: [{ type: 'uint256' }],
        stateMutability: 'view',
        type: 'function',
    },
] as const

interface SeasonData {
    id: number
    startTimestamp: number
    endTimestamp: number
    rewardTokensToDistribute: bigint
    rewardTokenBalance: bigint
    totalDepositAmount: bigint
    totalClaimAmount: bigint
    totalPoints: bigint
    durationDays: number
}

interface PriceSimulationResult {
    tier: number
    originalPriceUSDC: number
    dynamicPriceUSDC: number
    expectedVAPE: number
    expectedValueUSD: number
    estimatedROI: number
    depositLimitVPND: string
}

interface SeasonSimulation {
    seasonId: number
    seasonData: SeasonData
    vapePrice: number
    targetROI: number
    historicalAvgPoints: bigint
    tierPrices: PriceSimulationResult[]
}

async function fetchVAPEPrice(): Promise<number> {
    try {
        const response = await fetch(
            'https://api.coingecko.com/api/v3/simple/price?ids=vaporfi&vs_currencies=usd'
        )
        const data = await response.json()
        return data.vaporfi?.usd || 0.16
    } catch {
        console.log('Failed to fetch VAPE price, using default $0.16')
        return 0.16
    }
}

async function fetchHistoricalVAPEPrice(timestamp: number): Promise<number> {
    try {
        const date = new Date(timestamp * 1000)
        const dateStr = `${date.getDate().toString().padStart(2, '0')}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getFullYear()}`
        const response = await fetch(
            `https://api.coingecko.com/api/v3/coins/vaporfi/history?date=${dateStr}`
        )
        const data = await response.json()
        return data.market_data?.current_price?.usd || 0.16
    } catch {
        return 0.16
    }
}

function calculateDynamicPrice(
    tier: number,
    vapePrice: number,
    seasonVAPERewards: bigint,
    historicalAvgPoints: bigint,
    targetROI: number,
    seasonDurationDays: number
): PriceSimulationResult {
    const depositLimit = TIER_DEPOSIT_LIMITS[tier]
    const originalPrice = ORIGINAL_TIER_FEES_USDC[tier]

    const maxPointsRaw = tier === 10
        ? parseUnits('50000000', 18) * BigInt(seasonDurationDays)
        : depositLimit * BigInt(seasonDurationDays)

    const maxPoints = maxPointsRaw

    if (historicalAvgPoints === 0n) {
        return {
            tier,
            originalPriceUSDC: originalPrice,
            dynamicPriceUSDC: originalPrice,
            expectedVAPE: 0,
            expectedValueUSD: 0,
            estimatedROI: 0,
            depositLimitVPND: tier === 10 ? 'Unlimited' : formatUnits(depositLimit, 18),
        }
    }

    const shareNumerator = maxPoints * BigInt(1e18)
    const shareDenominator = historicalAvgPoints
    const expectedVAPE = (seasonVAPERewards * shareNumerator) / shareDenominator / BigInt(1e18)

    const expectedVAPENumber = Number(formatUnits(expectedVAPE, 18))
    const expectedValueUSD = expectedVAPENumber * vapePrice

    const dynamicPriceUSDC = expectedValueUSD / targetROI

    const actualROI = dynamicPriceUSDC > 0 ? expectedValueUSD / dynamicPriceUSDC : 0

    return {
        tier,
        originalPriceUSDC: originalPrice,
        dynamicPriceUSDC: Math.max(dynamicPriceUSDC, 0.01),
        expectedVAPE: expectedVAPENumber,
        expectedValueUSD,
        estimatedROI: actualROI,
        depositLimitVPND: tier === 10 ? 'Unlimited (using 50M for calc)' : formatUnits(depositLimit, 18),
    }
}

function calculateSimpleDynamicPrice(
    tier: number,
    vapePrice: number,
    referenceVAPEPrice: number = 1.0
): { originalPrice: number; dynamicPrice: number; multiplier: number } {
    const originalPrice = ORIGINAL_TIER_FEES_USDC[tier]
    const multiplier = vapePrice / referenceVAPEPrice
    const dynamicPrice = originalPrice * multiplier

    return {
        originalPrice,
        dynamicPrice: Math.max(dynamicPrice, 0.01),
        multiplier,
    }
}

async function main() {
    const client = createPublicClient({
        chain: avalanche,
        transport: http(),
    })

    console.log('🔍 Fetching current season data...\n')

    const currentSeasonId = await client.readContract({
        address: LIQUID_MINING_DIAMOND,
        abi: diamondAbi,
        functionName: 'getCurrentSeasonId',
    })

    console.log(`Current Season ID: ${currentSeasonId}\n`)

    const seasons: SeasonData[] = []
    const maxSeasonsToFetch = Math.min(Number(currentSeasonId), 10)

    console.log('📊 Fetching historical season data...\n')

    for (let i = 1; i <= maxSeasonsToFetch; i++) {
        try {
            const seasonData = await client.readContract({
                address: LIQUID_MINING_DIAMOND,
                abi: diamondAbi,
                functionName: 'getSeasonData',
                args: [BigInt(i)],
            })

            const durationSeconds = Number(seasonData.endTimestamp - seasonData.startTimestamp)
            const durationDays = Math.ceil(durationSeconds / 86400)

            seasons.push({
                id: i,
                startTimestamp: Number(seasonData.startTimestamp),
                endTimestamp: Number(seasonData.endTimestamp),
                rewardTokensToDistribute: seasonData.rewardTokensToDistribute,
                rewardTokenBalance: seasonData.rewardTokenBalance,
                totalDepositAmount: seasonData.totalDepositAmount,
                totalClaimAmount: seasonData.totalClaimAmount,
                totalPoints: seasonData.totalPoints,
                durationDays,
            })
        } catch (e) {
            console.log(`Failed to fetch season ${i}`)
        }
    }

    console.log('═══════════════════════════════════════════════════════════════════')
    console.log('                    HISTORICAL SEASON DATA                          ')
    console.log('═══════════════════════════════════════════════════════════════════\n')

    for (const season of seasons) {
        const startDate = new Date(season.startTimestamp * 1000).toISOString().split('T')[0]
        const endDate = new Date(season.endTimestamp * 1000).toISOString().split('T')[0]

        console.log(`Season ${season.id}:`)
        console.log(`  Duration: ${startDate} to ${endDate} (${season.durationDays} days)`)
        console.log(`  VAPE Rewards: ${formatUnits(season.rewardTokensToDistribute, 18)} VAPE`)
        console.log(`  Total Deposits: ${formatUnits(season.totalDepositAmount, 18)} VPND`)
        console.log(`  Total Points: ${formatUnits(season.totalPoints, 18)}`)
        console.log('')
    }

    const currentVAPEPrice = await fetchVAPEPrice()
    console.log(`\n💰 Current VAPE Price: $${currentVAPEPrice.toFixed(4)}\n`)

    console.log('═══════════════════════════════════════════════════════════════════')
    console.log('           SIMPLE DYNAMIC PRICING (VAPE MULTIPLIER)                 ')
    console.log('═══════════════════════════════════════════════════════════════════\n')

    console.log(`Formula: newPrice = originalPrice × (currentVAPEPrice / $${REFERENCE_VAPE_PRICE.toFixed(2)})\n`)
    console.log(`Reference VAPE Price (Season 1 start, Jul 7 2023): $${REFERENCE_VAPE_PRICE.toFixed(2)}\n`)

    const simpleResults: { tier: number; original: number; dynamic: number }[] = []
    for (let tier = 0; tier <= 10; tier++) {
        const result = calculateSimpleDynamicPrice(tier, currentVAPEPrice, REFERENCE_VAPE_PRICE)
        simpleResults.push({ tier, original: result.originalPrice, dynamic: result.dynamicPrice })
    }

    console.log('Tier | Original ($) | Dynamic ($) | Reduction')
    console.log('-----|--------------|-------------|----------')
    for (const r of simpleResults) {
        const reduction = r.original > 0 ? ((r.original - r.dynamic) / r.original * 100).toFixed(0) : 0
        console.log(
            `  ${r.tier.toString().padStart(2)} | ${r.original.toFixed(2).padStart(12)} | ${r.dynamic.toFixed(2).padStart(11)} | ${reduction}%`
        )
    }

    console.log('\n═══════════════════════════════════════════════════════════════════')
    console.log('           ROI-CONTROLLED DYNAMIC PRICING                           ')
    console.log('═══════════════════════════════════════════════════════════════════\n')

    const completedSeasons = seasons.filter(s => s.totalPoints > 0n && s.endTimestamp < Date.now() / 1000)

    if (completedSeasons.length === 0) {
        console.log('No completed seasons with data available for ROI-based simulation.\n')
    } else {
        const recentSeasons = completedSeasons.slice(-3)
        const avgTotalPoints = recentSeasons.reduce((sum, s) => sum + s.totalPoints, 0n) / BigInt(recentSeasons.length)

        console.log(`Historical Average Total Points (last ${recentSeasons.length} seasons): ${formatUnits(avgTotalPoints, 18)}\n`)

        const targetROIs = [5, 10, 20]
        const currentSeason = seasons[seasons.length - 1]

        for (const targetROI of targetROIs) {
            console.log(`\n📈 TARGET ROI: ${targetROI}x (Mining pass = ${(100 / targetROI).toFixed(1)}% of expected value)`)
            console.log('─'.repeat(70))

            const tierResults: PriceSimulationResult[] = []
            for (let tier = 1; tier <= 10; tier++) {
                const result = calculateDynamicPrice(
                    tier,
                    currentVAPEPrice,
                    currentSeason.rewardTokensToDistribute,
                    avgTotalPoints,
                    targetROI,
                    currentSeason.durationDays || 25
                )
                tierResults.push(result)
            }

            console.log('\nTier | Orig($) | Dynamic($) | Exp.VAPE   | Exp.Value($) | Est.ROI')
            console.log('-----|---------|------------|------------|--------------|--------')

            for (const r of tierResults) {
                console.log(
                    `  ${r.tier.toString().padStart(2)} | ${r.originalPriceUSDC.toFixed(2).padStart(7)} | ${r.dynamicPriceUSDC.toFixed(2).padStart(10)} | ${r.expectedVAPE.toFixed(0).padStart(10)} | ${r.expectedValueUSD.toFixed(2).padStart(12)} | ${r.estimatedROI.toFixed(1)}x`
                )
            }
        }
    }

    console.log('\n═══════════════════════════════════════════════════════════════════')
    console.log('           HISTORICAL SIMULATION - WHAT IF ANALYSIS                 ')
    console.log('═══════════════════════════════════════════════════════════════════\n')

    console.log('Simulating what prices WOULD HAVE BEEN if dynamic pricing was active:\n')

    for (let i = 1; i < completedSeasons.length; i++) {
        const season = completedSeasons[i]
        const prevSeasons = completedSeasons.slice(Math.max(0, i - 3), i)
        const avgPoints = prevSeasons.reduce((sum, s) => sum + s.totalPoints, 0n) / BigInt(prevSeasons.length)

        const historicalPrice = await fetchHistoricalVAPEPrice(season.startTimestamp)

        console.log(`\n📅 Season ${season.id} (started ${new Date(season.startTimestamp * 1000).toISOString().split('T')[0]})`)
        console.log(`   VAPE Price at start: $${historicalPrice.toFixed(4)}`)
        console.log(`   VAPE Rewards: ${formatUnits(season.rewardTokensToDistribute, 18)} VAPE`)
        console.log(`   Avg Historical Points: ${formatUnits(avgPoints, 18)}`)
        console.log('')

        const targetROI = 10

        console.log(`   Tier | Original | Simple Dyn. | ROI-Based (${targetROI}x)`)
        console.log('   -----|----------|-------------|---------------')

        for (const tier of [1, 5, 10]) {
            const original = ORIGINAL_TIER_FEES_USDC[tier]
            const simpleDynamic = calculateSimpleDynamicPrice(tier, historicalPrice, REFERENCE_VAPE_PRICE)
            const roiBased = calculateDynamicPrice(
                tier,
                historicalPrice,
                season.rewardTokensToDistribute,
                avgPoints,
                targetROI,
                season.durationDays
            )

            console.log(
                `     ${tier.toString().padStart(2)} | $${original.toFixed(2).padStart(7)} | $${simpleDynamic.dynamicPrice.toFixed(2).padStart(10)} | $${roiBased.dynamicPriceUSDC.toFixed(2).padStart(13)}`
            )
        }
    }

    console.log('\n═══════════════════════════════════════════════════════════════════')
    console.log('                         SUMMARY                                    ')
    console.log('═══════════════════════════════════════════════════════════════════\n')

    console.log('Two pricing strategies available:\n')

    console.log('1️⃣  SIMPLE VAPE MULTIPLIER:')
    console.log(`    - Formula: price = originalPrice × (vapePrice / $${REFERENCE_VAPE_PRICE.toFixed(2)})`)
    console.log('    - Pros: Simple, predictable, same formula for all tiers')
    console.log('    - Cons: Doesn\'t account for participation levels or expected rewards')
    console.log('')

    console.log('2️⃣  ROI-CONTROLLED PRICING:')
    console.log('    - Formula: price = expectedRewardValue / targetROI')
    console.log('    - Uses historical average points to estimate user\'s share')
    console.log('    - Pros: Guarantees target ROI, adapts to participation')
    console.log('    - Cons: More complex, prices vary significantly by tier')
    console.log('')

    console.log('📌 Recommendation: Start with Simple VAPE Multiplier for quick deployment,')
    console.log('   then consider ROI-Controlled for long-term if more precision needed.\n')
}

main().catch(console.error)
