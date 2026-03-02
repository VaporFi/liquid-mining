import { createPublicClient, http, formatUnits, parseUnits, type Address } from 'viem'
import { avalanche } from 'viem/chains'
import * as fs from 'fs'

const LIQUID_MINING_DIAMOND = '0xAe950fdd0CC79DDE64d3Fffd40fabec3f7ba368B' as Address
const SUBGRAPH_URL = 'https://liquid-mining-indexer-production.up.railway.app/'

const REFERENCE_VAPE_PRICE = 0.606
const SEASON_ID = 30
const VAPE_PRICE_AT_SEASON = 0.16

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

const TIER_DEPOSIT_LIMITS_DISPLAY: Record<number, string> = {
    0: '5,000',
    1: '10,000',
    2: '25,000',
    3: '60,000',
    4: '150,000',
    5: '350,000',
    6: '800,000',
    7: '1,800,000',
    8: '4,500,000',
    9: '12,000,000',
    10: 'Unlimited',
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

async function fetchAllUsersForSeason(seasonId: number): Promise<SubgraphUser[]> {
    let allUsers: SubgraphUser[] = []
    let hasMore = true
    let offset = 0
    const limit = 1000

    while (hasMore) {
        const query = `
            query Season {
                users(
                    orderBy: "totalClaimed", 
                    orderDirection: "desc", 
                    where: {seasonId: "${seasonId}"},
                    limit: ${limit},
                    offset: ${offset}
                ) {
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
            const users = data.data?.users?.items || []

            if (users.length === 0) {
                hasMore = false
            } else {
                allUsers = allUsers.concat(users)
                offset += limit
                if (users.length < limit) hasMore = false
            }
        } catch (e) {
            console.log(`Failed to fetch users:`, e)
            hasMore = false
        }
    }

    return allUsers
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
    return Math.max(originalFee * multiplier, 0)
}

async function main() {
    console.log('📊 VaporFi Liquid Mining - Season 30 User Analysis')
    console.log('═'.repeat(60))
    console.log(`\nFetching all users for Season ${SEASON_ID}...\n`)

    const users = await fetchAllUsersForSeason(SEASON_ID)
    console.log(`Found ${users.length} total users\n`)

    const rows: string[][] = []

    rows.push([
        'Wallet Address',
        'Tier',
        'Tier Deposit Limit (VPND)',
        'Deposited VPND',
        'Wallet Points',
        'Combined Points',
        'VAPE Claimed',
        'VAPE Value (USD)',
        'Original Fee (USD)',
        'Dynamic Fee (USD)',
        'Original ROI (x)',
        'Dynamic ROI (x)',
        'Original Profit/Loss (USD)',
        'Dynamic Profit/Loss (USD)',
        'Original Profitable?',
        'Dynamic Profitable?',
    ])

    let totalOriginalFees = 0
    let totalDynamicFees = 0
    let totalVAPEValue = 0
    let usersWithPaidPass = 0
    let originalProfitable = 0
    let dynamicProfitable = 0

    for (const user of users) {
        const walletAddress = user.id.split('-')[0]
        const depositedVPND = BigInt(user.totalDeposited || '0')
        const walletPoints = BigInt(user.walletPoints || '0')
        const combinedPoints = BigInt(user.combinedPoints || '0')
        const claimedVAPE = Number(formatUnits(BigInt(user.totalClaimed || '0'), 18))

        const tier = getTierFromDeposit(depositedVPND)
        const originalFee = ORIGINAL_TIER_FEES_USDC[tier]
        const dynamicFee = calculateDynamicFee(tier, VAPE_PRICE_AT_SEASON)
        const vapeValueUSD = claimedVAPE * VAPE_PRICE_AT_SEASON

        const originalROI = originalFee > 0 ? vapeValueUSD / originalFee : 0
        const dynamicROI = dynamicFee > 0 ? vapeValueUSD / dynamicFee : 0

        const originalProfitLoss = vapeValueUSD - originalFee
        const dynamicProfitLoss = vapeValueUSD - dynamicFee

        const isOriginalProfitable = originalFee > 0 && originalROI >= 1
        const isDynamicProfitable = dynamicFee > 0 && dynamicROI >= 1

        if (originalFee > 0) {
            usersWithPaidPass++
            totalOriginalFees += originalFee
            totalDynamicFees += dynamicFee
            totalVAPEValue += vapeValueUSD
            if (isOriginalProfitable) originalProfitable++
            if (isDynamicProfitable) dynamicProfitable++
        }

        rows.push([
            walletAddress,
            tier.toString(),
            TIER_DEPOSIT_LIMITS_DISPLAY[tier],
            Number(formatUnits(depositedVPND, 18)).toLocaleString('en-US', { maximumFractionDigits: 2 }),
            Number(formatUnits(walletPoints, 18)).toLocaleString('en-US', { maximumFractionDigits: 2 }),
            Number(formatUnits(combinedPoints, 18)).toLocaleString('en-US', { maximumFractionDigits: 2 }),
            claimedVAPE.toFixed(4),
            vapeValueUSD.toFixed(2),
            originalFee.toFixed(2),
            dynamicFee.toFixed(2),
            originalFee > 0 ? originalROI.toFixed(2) : 'N/A',
            dynamicFee > 0 ? dynamicROI.toFixed(2) : 'N/A',
            originalFee > 0 ? originalProfitLoss.toFixed(2) : 'N/A',
            dynamicFee > 0 ? dynamicProfitLoss.toFixed(2) : 'N/A',
            originalFee > 0 ? (isOriginalProfitable ? 'Yes' : 'No') : 'Free Tier',
            dynamicFee > 0 ? (isDynamicProfitable ? 'Yes' : 'No') : 'Free Tier',
        ])
    }

    rows.push([])
    rows.push(['SUMMARY STATISTICS'])
    rows.push([])
    rows.push(['Metric', 'Value'])
    rows.push(['Season', SEASON_ID.toString()])
    rows.push(['VAPE Price at Season', `$${VAPE_PRICE_AT_SEASON.toFixed(4)}`])
    rows.push(['Reference VAPE Price (Original Fee Design)', `$${REFERENCE_VAPE_PRICE.toFixed(4)}`])
    rows.push(['Price Multiplier', (VAPE_PRICE_AT_SEASON / REFERENCE_VAPE_PRICE).toFixed(4)])
    rows.push([])
    rows.push(['Total Users', users.length.toString()])
    rows.push(['Users with Paid Pass (Tier 1+)', usersWithPaidPass.toString()])
    rows.push(['Users on Free Tier (Tier 0)', (users.length - usersWithPaidPass).toString()])
    rows.push([])
    rows.push(['Total Original Fees Collected', `$${totalOriginalFees.toFixed(2)}`])
    rows.push(['Total Dynamic Fees (Proposed)', `$${totalDynamicFees.toFixed(2)}`])
    rows.push(['Fee Reduction', `${((1 - totalDynamicFees / totalOriginalFees) * 100).toFixed(1)}%`])
    rows.push([])
    rows.push(['Total VAPE Value Distributed', `$${totalVAPEValue.toFixed(2)}`])
    rows.push([])
    rows.push(['PROFITABILITY ANALYSIS (Paid Pass Users Only)'])
    rows.push(['Original Pricing - Profitable Users', `${originalProfitable} / ${usersWithPaidPass} (${(originalProfitable / usersWithPaidPass * 100).toFixed(1)}%)`])
    rows.push(['Dynamic Pricing - Profitable Users', `${dynamicProfitable} / ${usersWithPaidPass} (${(dynamicProfitable / usersWithPaidPass * 100).toFixed(1)}%)`])
    rows.push(['Improvement', `+${dynamicProfitable - originalProfitable} users (+${((dynamicProfitable - originalProfitable) / usersWithPaidPass * 100).toFixed(1)}%)`])
    rows.push([])
    rows.push(['Average Original ROI', `${(totalVAPEValue / totalOriginalFees).toFixed(2)}x`])
    rows.push(['Average Dynamic ROI', `${(totalVAPEValue / totalDynamicFees).toFixed(2)}x`])
    rows.push([])
    rows.push(['PRICING MODEL'])
    rows.push(['Formula', 'Dynamic Fee = Original Fee × (Current VAPE Price / Reference VAPE Price)'])
    rows.push(['Example (Tier 10)', `$100 × ($${VAPE_PRICE_AT_SEASON} / $${REFERENCE_VAPE_PRICE}) = $${calculateDynamicFee(10, VAPE_PRICE_AT_SEASON).toFixed(2)}`])
    rows.push([])
    rows.push(['TIER FEE COMPARISON'])
    rows.push(['Tier', 'Deposit Limit', 'Original Fee', 'Dynamic Fee', 'Reduction'])

    for (let tier = 0; tier <= 10; tier++) {
        const origFee = ORIGINAL_TIER_FEES_USDC[tier]
        const dynFee = calculateDynamicFee(tier, VAPE_PRICE_AT_SEASON)
        const reduction = origFee > 0 ? `${((1 - dynFee / origFee) * 100).toFixed(0)}%` : 'N/A'
        rows.push([
            tier.toString(),
            TIER_DEPOSIT_LIMITS_DISPLAY[tier] + ' VPND',
            `$${origFee.toFixed(2)}`,
            `$${dynFee.toFixed(2)}`,
            reduction,
        ])
    }

    const csvContent = rows.map(row => row.map(cell => `"${cell}"`).join(',')).join('\n')

    const filename = `VaporFi_LiquidMining_Season${SEASON_ID}_Analysis_${new Date().toISOString().split('T')[0]}.csv`
    const filepath = `scripts/simulation/${filename}`

    fs.writeFileSync(filepath, csvContent)

    console.log('✅ Export Complete!')
    console.log(`📁 File saved: ${filepath}`)
    console.log('')
    console.log('Summary:')
    console.log(`  • Total Users: ${users.length}`)
    console.log(`  • Users with Paid Pass: ${usersWithPaidPass}`)
    console.log(`  • Original Profitable: ${originalProfitable}/${usersWithPaidPass} (${(originalProfitable / usersWithPaidPass * 100).toFixed(1)}%)`)
    console.log(`  • Dynamic Profitable: ${dynamicProfitable}/${usersWithPaidPass} (${(dynamicProfitable / usersWithPaidPass * 100).toFixed(1)}%)`)
    console.log(`  • Fee Reduction: ${((1 - totalDynamicFees / totalOriginalFees) * 100).toFixed(1)}%`)
}

main().catch(console.error)
