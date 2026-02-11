import { createPublicClient, http, formatUnits, parseUnits, type Address } from 'viem'
import { avalanche } from 'viem/chains'

const LIQUID_MINING_DIAMOND = '0xAe950fdd0CC79DDE64d3Fffd40fabec3f7ba368B' as Address
const SUBGRAPH_URL = 'https://liquid-mining-indexer-production.up.railway.app/'

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

interface SubgraphUser {
    id: string
    totalDeposited: string
    walletPoints: string
    totalClaimed: string
    combinedPoints: string
    seasonId: string
}

interface UserAnalysis {
    address: string
    seasonId: number
    depositedVPND: number
    tier: number
    originalFee: number
    dynamicFee: number
    claimedVAPE: number
    claimedValueUSD: number
    originalROI: number
    dynamicROI: number
}

interface SeasonSummary {
    seasonId: number
    userCount: number
    totalDeposited: number
    totalClaimed: number
    avgOriginalROI: number
    avgDynamicROI: number
    medianOriginalROI: number
    medianDynamicROI: number
    positiveROICountOriginal: number
    positiveROICountDynamic: number
    vapePrice: number
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
] as const

async function fetchUsersForSeason(seasonId: number): Promise<SubgraphUser[]> {
    const query = `
        query Season {
            users(orderBy: "walletPoints", orderDirection: "desc", where: {seasonId: "${seasonId}"}, limit: 1000) {
                items {
                    id
                    totalDeposited
                    walletPoints
                    totalClaimed
                    combinedPoints
                    seasonId
                }
            }
        }
    `

    try {
        const response = await fetch(SUBGRAPH_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ query }),
        })
        const data = await response.json()
        return data.data?.users?.items || []
    } catch (e) {
        console.log(`Failed to fetch users for season ${seasonId}:`, e)
        return []
    }
}

async function fetchVAPEPrice(): Promise<number> {
    try {
        const response = await fetch(
            'https://api.coingecko.com/api/v3/simple/price?ids=vaporfi&vs_currencies=usd'
        )
        const data = await response.json()
        return data.vaporfi?.usd || 0.16
    } catch {
        return 0.16
    }
}

function getTierFromDeposit(depositedVPND: bigint): number {
    for (let tier = 0; tier <= 10; tier++) {
        if (depositedVPND <= TIER_DEPOSIT_LIMITS[tier]) {
            return tier
        }
    }
    return 10
}

function calculateDynamicFee(tier: number, vapePrice: number): number {
    const originalFee = ORIGINAL_TIER_FEES_USDC[tier]
    const multiplier = vapePrice / REFERENCE_VAPE_PRICE
    return Math.max(originalFee * multiplier, 0.01)
}

function median(values: number[]): number {
    if (values.length === 0) return 0
    const sorted = [...values].sort((a, b) => a - b)
    const mid = Math.floor(sorted.length / 2)
    return sorted.length % 2 !== 0 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2
}

async function analyzeSeasonROI(
    seasonId: number,
    vapePrice: number
): Promise<{ users: UserAnalysis[]; summary: SeasonSummary }> {
    const subgraphUsers = await fetchUsersForSeason(seasonId)

    if (subgraphUsers.length === 0) {
        return {
            users: [],
            summary: {
                seasonId,
                userCount: 0,
                totalDeposited: 0,
                totalClaimed: 0,
                avgOriginalROI: 0,
                avgDynamicROI: 0,
                medianOriginalROI: 0,
                medianDynamicROI: 0,
                positiveROICountOriginal: 0,
                positiveROICountDynamic: 0,
                vapePrice,
            },
        }
    }

    const userAnalyses: UserAnalysis[] = []

    for (const user of subgraphUsers) {
        const depositedVPND = BigInt(user.totalDeposited || '0')
        const claimedVAPE = Number(formatUnits(BigInt(user.totalClaimed || '0'), 18))

        if (depositedVPND === 0n) continue

        const tier = getTierFromDeposit(depositedVPND)
        const originalFee = ORIGINAL_TIER_FEES_USDC[tier]
        const dynamicFee = calculateDynamicFee(tier, vapePrice)
        const claimedValueUSD = claimedVAPE * vapePrice

        const originalROI = originalFee > 0 ? claimedValueUSD / originalFee : Infinity
        const dynamicROI = dynamicFee > 0 ? claimedValueUSD / dynamicFee : Infinity

        userAnalyses.push({
            address: user.id.split('-')[0],
            seasonId,
            depositedVPND: Number(formatUnits(depositedVPND, 18)),
            tier,
            originalFee,
            dynamicFee,
            claimedVAPE,
            claimedValueUSD,
            originalROI: isFinite(originalROI) ? originalROI : 0,
            dynamicROI: isFinite(dynamicROI) ? dynamicROI : 0,
        })
    }

    const validUsers = userAnalyses.filter(u => u.originalFee > 0 && u.claimedVAPE > 0)

    const originalROIs = validUsers.map(u => u.originalROI)
    const dynamicROIs = validUsers.map(u => u.dynamicROI)

    const summary: SeasonSummary = {
        seasonId,
        userCount: validUsers.length,
        totalDeposited: userAnalyses.reduce((sum, u) => sum + u.depositedVPND, 0),
        totalClaimed: userAnalyses.reduce((sum, u) => sum + u.claimedVAPE, 0),
        avgOriginalROI: originalROIs.length > 0 ? originalROIs.reduce((a, b) => a + b, 0) / originalROIs.length : 0,
        avgDynamicROI: dynamicROIs.length > 0 ? dynamicROIs.reduce((a, b) => a + b, 0) / dynamicROIs.length : 0,
        medianOriginalROI: median(originalROIs),
        medianDynamicROI: median(dynamicROIs),
        positiveROICountOriginal: originalROIs.filter(r => r >= 1).length,
        positiveROICountDynamic: dynamicROIs.filter(r => r >= 1).length,
        vapePrice,
    }

    return { users: userAnalyses, summary }
}

function printTierBreakdown(users: UserAnalysis[], vapePrice: number) {
    const tierStats: Record<number, { count: number; totalOriginalROI: number; totalDynamicROI: number; users: UserAnalysis[] }> = {}

    for (let tier = 0; tier <= 10; tier++) {
        tierStats[tier] = { count: 0, totalOriginalROI: 0, totalDynamicROI: 0, users: [] }
    }

    for (const user of users) {
        if (user.originalFee > 0 && user.claimedVAPE > 0) {
            tierStats[user.tier].count++
            tierStats[user.tier].totalOriginalROI += user.originalROI
            tierStats[user.tier].totalDynamicROI += user.dynamicROI
            tierStats[user.tier].users.push(user)
        }
    }

    console.log('\n   Tier | Users | Orig Fee | Dyn Fee  | Avg Orig ROI | Avg Dyn ROI | Profitable (Orig→Dyn)')
    console.log('   -----|-------|----------|----------|--------------|-------------|----------------------')

    for (let tier = 1; tier <= 10; tier++) {
        const stats = tierStats[tier]
        if (stats.count === 0) continue

        const avgOrigROI = stats.totalOriginalROI / stats.count
        const avgDynROI = stats.totalDynamicROI / stats.count
        const origFee = ORIGINAL_TIER_FEES_USDC[tier]
        const dynFee = calculateDynamicFee(tier, vapePrice)
        const profitableOrig = stats.users.filter(u => u.originalROI >= 1).length
        const profitableDyn = stats.users.filter(u => u.dynamicROI >= 1).length

        console.log(
            `     ${tier.toString().padStart(2)} | ${stats.count.toString().padStart(5)} | $${origFee.toFixed(2).padStart(7)} | $${dynFee.toFixed(2).padStart(7)} | ${avgOrigROI.toFixed(2).padStart(12)}x | ${avgDynROI.toFixed(2).padStart(11)}x | ${profitableOrig}→${profitableDyn} (${((profitableDyn - profitableOrig) / stats.count * 100).toFixed(0)}%↑)`
        )
    }
}

async function main() {
    const client = createPublicClient({
        chain: avalanche,
        transport: http(),
    })

    console.log('🔍 Mining Pass ROI Analysis with Real User Data\n')
    console.log(`Reference VAPE Price (when fees were set): $${REFERENCE_VAPE_PRICE.toFixed(4)}`)
    console.log(`Formula: dynamicFee = originalFee × (currentVAPEPrice / $${REFERENCE_VAPE_PRICE.toFixed(2)})\n`)

    const currentSeasonId = await client.readContract({
        address: LIQUID_MINING_DIAMOND,
        abi: diamondAbi,
        functionName: 'getCurrentSeasonId',
    })

    console.log(`Current Season: ${currentSeasonId}\n`)

    const currentVAPEPrice = await fetchVAPEPrice()
    console.log(`💰 Current VAPE Price: $${currentVAPEPrice.toFixed(4)}\n`)

    const seasonsToAnalyze = [15, 20, 25, 30]
    const allSummaries: SeasonSummary[] = []

    const historicalVAPEPrices: Record<number, number> = {
        15: 0.18,
        20: 0.15,
        25: 0.14,
        30: 0.16,
    }

    console.log('═══════════════════════════════════════════════════════════════════')
    console.log('                    SEASON-BY-SEASON ANALYSIS                       ')
    console.log('═══════════════════════════════════════════════════════════════════')

    for (const seasonId of seasonsToAnalyze) {
        console.log(`\n📊 Fetching data for Season ${seasonId}...`)

        const vapePrice = historicalVAPEPrices[seasonId] || currentVAPEPrice
        const { users, summary } = await analyzeSeasonROI(seasonId, vapePrice)

        if (summary.userCount === 0) {
            console.log(`   No user data found for season ${seasonId}`)
            continue
        }

        allSummaries.push(summary)

        console.log(`\n   Season ${seasonId} Summary (VAPE Price: $${vapePrice.toFixed(4)}):`)
        console.log(`   ├─ Total Users with Paid Pass: ${summary.userCount}`)
        console.log(`   ├─ Total Deposited: ${summary.totalDeposited.toLocaleString()} VPND`)
        console.log(`   ├─ Total Claimed: ${summary.totalClaimed.toLocaleString()} VAPE`)
        console.log(`   │`)
        console.log(`   ├─ Original Pricing:`)
        console.log(`   │  ├─ Avg ROI: ${summary.avgOriginalROI.toFixed(2)}x`)
        console.log(`   │  ├─ Median ROI: ${summary.medianOriginalROI.toFixed(2)}x`)
        console.log(`   │  └─ Users with ROI ≥ 1x: ${summary.positiveROICountOriginal}/${summary.userCount} (${(summary.positiveROICountOriginal / summary.userCount * 100).toFixed(1)}%)`)
        console.log(`   │`)
        console.log(`   └─ Dynamic Pricing:`)
        console.log(`      ├─ Avg ROI: ${summary.avgDynamicROI.toFixed(2)}x`)
        console.log(`      ├─ Median ROI: ${summary.medianDynamicROI.toFixed(2)}x`)
        console.log(`      └─ Users with ROI ≥ 1x: ${summary.positiveROICountDynamic}/${summary.userCount} (${(summary.positiveROICountDynamic / summary.userCount * 100).toFixed(1)}%)`)

        printTierBreakdown(users, vapePrice)

        console.log('\n   Top 5 Users by Claimed VAPE:')
        const topUsers = users
            .filter(u => u.claimedVAPE > 0)
            .sort((a, b) => b.claimedVAPE - a.claimedVAPE)
            .slice(0, 5)

        console.log('   Address      | Tier | Deposited VPND | Claimed VAPE | Orig Fee | Dyn Fee | Orig ROI | Dyn ROI')
        console.log('   -------------|------|----------------|--------------|----------|---------|----------|--------')
        for (const u of topUsers) {
            console.log(
                `   ${u.address.slice(0, 10)}.. | ${u.tier.toString().padStart(4)} | ${u.depositedVPND.toLocaleString().padStart(14)} | ${u.claimedVAPE.toFixed(2).padStart(12)} | $${u.originalFee.toFixed(2).padStart(6)} | $${u.dynamicFee.toFixed(2).padStart(5)} | ${u.originalROI.toFixed(2).padStart(8)}x | ${u.dynamicROI.toFixed(2).padStart(6)}x`
            )
        }

        console.log('\n   Bottom 5 Users by ROI (paid pass, got rewards):')
        const bottomUsers = users
            .filter(u => u.claimedVAPE > 0 && u.originalFee > 0)
            .sort((a, b) => a.originalROI - b.originalROI)
            .slice(0, 5)

        for (const u of bottomUsers) {
            console.log(
                `   ${u.address.slice(0, 10)}.. | ${u.tier.toString().padStart(4)} | ${u.depositedVPND.toLocaleString().padStart(14)} | ${u.claimedVAPE.toFixed(2).padStart(12)} | $${u.originalFee.toFixed(2).padStart(6)} | $${u.dynamicFee.toFixed(2).padStart(5)} | ${u.originalROI.toFixed(2).padStart(8)}x | ${u.dynamicROI.toFixed(2).padStart(6)}x`
            )
        }
    }

    console.log('\n═══════════════════════════════════════════════════════════════════')
    console.log('                         OVERALL SUMMARY                            ')
    console.log('═══════════════════════════════════════════════════════════════════\n')

    if (allSummaries.length > 0) {
        const totalUsers = allSummaries.reduce((sum, s) => sum + s.userCount, 0)
        const avgOrigROI = allSummaries.reduce((sum, s) => sum + s.avgOriginalROI, 0) / allSummaries.length
        const avgDynROI = allSummaries.reduce((sum, s) => sum + s.avgDynamicROI, 0) / allSummaries.length
        const totalProfitableOrig = allSummaries.reduce((sum, s) => sum + s.positiveROICountOriginal, 0)
        const totalProfitableDyn = allSummaries.reduce((sum, s) => sum + s.positiveROICountDynamic, 0)

        console.log(`Total Users Analyzed: ${totalUsers}`)
        console.log(`Seasons Analyzed: ${allSummaries.map(s => s.seasonId).join(', ')}\n`)

        console.log('Comparison:')
        console.log('┌─────────────────────┬────────────────┬────────────────┐')
        console.log('│ Metric              │ Original Fees  │ Dynamic Fees   │')
        console.log('├─────────────────────┼────────────────┼────────────────┤')
        console.log(`│ Avg ROI             │ ${avgOrigROI.toFixed(2).padStart(13)}x │ ${avgDynROI.toFixed(2).padStart(13)}x │`)
        console.log(`│ Profitable Users    │ ${totalProfitableOrig.toString().padStart(14)} │ ${totalProfitableDyn.toString().padStart(14)} │`)
        console.log(`│ Profitable Rate     │ ${(totalProfitableOrig / totalUsers * 100).toFixed(1).padStart(13)}% │ ${(totalProfitableDyn / totalUsers * 100).toFixed(1).padStart(13)}% │`)
        console.log('└─────────────────────┴────────────────┴────────────────┘\n')

        const improvement = ((totalProfitableDyn - totalProfitableOrig) / totalProfitableOrig * 100).toFixed(1)
        console.log(`📈 Dynamic pricing would increase profitable user rate by ${improvement}%`)
        console.log(`   (${totalProfitableDyn - totalProfitableOrig} more users would have broken even or profited)\n`)
    }

    console.log('═══════════════════════════════════════════════════════════════════')
    console.log('                    FEE COMPARISON TABLE                            ')
    console.log('═══════════════════════════════════════════════════════════════════\n')

    console.log(`At current VAPE price ($${currentVAPEPrice.toFixed(4)}):\n`)
    console.log('Tier | Deposit Limit    | Original Fee | Dynamic Fee | Reduction')
    console.log('-----|------------------|--------------|-------------|----------')

    for (let tier = 1; tier <= 10; tier++) {
        const limit = tier === 10 ? 'Unlimited' : `${Number(formatUnits(TIER_DEPOSIT_LIMITS[tier], 18)).toLocaleString()} VPND`
        const origFee = ORIGINAL_TIER_FEES_USDC[tier]
        const dynFee = calculateDynamicFee(tier, currentVAPEPrice)
        const reduction = ((origFee - dynFee) / origFee * 100).toFixed(0)

        console.log(
            `  ${tier.toString().padStart(2)} | ${limit.padStart(16)} | $${origFee.toFixed(2).padStart(10)} | $${dynFee.toFixed(2).padStart(9)} | ${reduction}%`
        )
    }

    console.log('\n📌 Recommendation:')
    console.log('   The dynamic pricing model significantly improves user ROI by reducing')
    console.log('   fees proportionally to VAPE price decline. This maintains the original')
    console.log('   value proposition established when fees were set.\n')
}

main().catch(console.error)
