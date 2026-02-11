import * as fs from 'fs'

const csv = fs.readFileSync('scripts/simulation/VaporFi_LiquidMining_Season30_Analysis_2026-01-30.csv', 'utf-8')
const lines = csv.split('\n').slice(1)

const tierLimits: Record<string, number> = {
    '5,000': 5000,
    '10,000': 10000,
    '25,000': 25000,
    '60,000': 60000,
    '150,000': 150000,
    '350,000': 350000,
    '800,000': 800000,
    '1,800,000': 1800000,
    '4,500,000': 4500000,
    '12,000,000': 12000000,
}

interface UnprofitableUser {
    wallet: string
    tier: number
    tierLimit: string
    deposited: number
    depositedStr: string
    utilization: number
    vapeValueUSD: number
    originalFee: number
    roi: number
    loss: number
}

const unprofitableUsers: UnprofitableUser[] = []

for (const line of lines) {
    if (!line.includes('0x')) continue

    const cols = line.match(/"([^"]*)"/g)?.map((c) => c.replace(/"/g, '')) || []
    if (cols.length < 16) continue

    const [wallet, tier, limitStr, depositedStr, , , , vapeValueStr, origFeeStr, , origROI, , origProfitLoss, , origProfitable] = cols

    if (tier === '0' || origProfitable === 'Free Tier') continue
    if (origProfitable === 'Yes') continue

    const limit = tierLimits[limitStr] || 0
    const deposited = parseFloat(depositedStr.replace(/,/g, ''))
    const utilization = (deposited / limit) * 100
    const vapeValueUSD = parseFloat(vapeValueStr)
    const originalFee = parseFloat(origFeeStr)
    const roi = parseFloat(origROI)
    const loss = parseFloat(origProfitLoss)

    unprofitableUsers.push({
        wallet,
        tier: parseInt(tier),
        tierLimit: limitStr,
        deposited,
        depositedStr,
        utilization,
        vapeValueUSD,
        originalFee,
        roi,
        loss,
    })
}

console.log('═'.repeat(80))
console.log('📊 UNPROFITABLE USERS ANALYSIS - SEASON 30')
console.log('═'.repeat(80))

console.log(`\nTotal Unprofitable Users: ${unprofitableUsers.length}`)

// Tier breakdown
console.log('\n' + '─'.repeat(80))
console.log('BREAKDOWN BY TIER')
console.log('─'.repeat(80))

const tierStats: Record<number, { count: number; totalLoss: number; avgROI: number; avgUtil: number; rois: number[]; utils: number[] }> = {}

for (const user of unprofitableUsers) {
    if (!tierStats[user.tier]) {
        tierStats[user.tier] = { count: 0, totalLoss: 0, avgROI: 0, avgUtil: 0, rois: [], utils: [] }
    }
    tierStats[user.tier].count++
    tierStats[user.tier].totalLoss += Math.abs(user.loss)
    tierStats[user.tier].rois.push(user.roi)
    tierStats[user.tier].utils.push(user.utilization)
}

console.log('\nTier | Users | Total Loss | Avg Loss | Avg ROI | Avg Utilization')
console.log('─'.repeat(70))

let grandTotalLoss = 0
for (const tier of Object.keys(tierStats).map(Number).sort((a, b) => a - b)) {
    const stats = tierStats[tier]
    const avgROI = (stats.rois.reduce((a, b) => a + b, 0) / stats.count).toFixed(2)
    const avgUtil = (stats.utils.reduce((a, b) => a + b, 0) / stats.count).toFixed(1)
    const avgLoss = (stats.totalLoss / stats.count).toFixed(2)
    grandTotalLoss += stats.totalLoss
    console.log(`  ${tier}  |   ${String(stats.count).padStart(2)}  |   $${stats.totalLoss.toFixed(2).padStart(7)} |  $${avgLoss.padStart(5)} |  ${avgROI}x  |    ${avgUtil}%`)
}

console.log('─'.repeat(70))
console.log(`TOTAL |   ${unprofitableUsers.length}  |   $${grandTotalLoss.toFixed(2).padStart(7)} |  $${(grandTotalLoss / unprofitableUsers.length).toFixed(2).padStart(5)} |`)

// Utilization breakdown
console.log('\n' + '─'.repeat(80))
console.log('BREAKDOWN BY UTILIZATION')
console.log('─'.repeat(80))

const utilizationBuckets = {
    '100% (maxed)': unprofitableUsers.filter(u => u.utilization >= 99),
    '90-99%': unprofitableUsers.filter(u => u.utilization >= 90 && u.utilization < 99),
    '75-90%': unprofitableUsers.filter(u => u.utilization >= 75 && u.utilization < 90),
    '50-75%': unprofitableUsers.filter(u => u.utilization >= 50 && u.utilization < 75),
    '<50%': unprofitableUsers.filter(u => u.utilization < 50),
}

console.log('\nUtilization  | Users | % of Total | Total Loss | Avg ROI')
console.log('─'.repeat(65))

for (const [bucket, users] of Object.entries(utilizationBuckets)) {
    if (users.length === 0) continue
    const totalLoss = users.reduce((sum, u) => sum + Math.abs(u.loss), 0)
    const avgROI = (users.reduce((sum, u) => sum + u.roi, 0) / users.length).toFixed(2)
    const pct = ((users.length / unprofitableUsers.length) * 100).toFixed(1)
    console.log(`${bucket.padEnd(12)} |   ${String(users.length).padStart(2)}  |   ${pct.padStart(5)}%  |   $${totalLoss.toFixed(2).padStart(7)} |  ${avgROI}x`)
}

// ROI breakdown
console.log('\n' + '─'.repeat(80))
console.log('BREAKDOWN BY ROI (How close to break-even)')
console.log('─'.repeat(80))

const roiBuckets = {
    '0.9-0.99x (very close)': unprofitableUsers.filter(u => u.roi >= 0.9),
    '0.7-0.89x (moderate)': unprofitableUsers.filter(u => u.roi >= 0.7 && u.roi < 0.9),
    '0.5-0.69x (significant)': unprofitableUsers.filter(u => u.roi >= 0.5 && u.roi < 0.7),
    '0.3-0.49x (heavy)': unprofitableUsers.filter(u => u.roi >= 0.3 && u.roi < 0.5),
    '<0.3x (severe)': unprofitableUsers.filter(u => u.roi < 0.3),
}

console.log('\nROI Range            | Users | % of Total | Avg Loss | Would be profitable w/ dynamic?')
console.log('─'.repeat(85))

const VAPE_PRICE = 0.16
const REF_PRICE = 0.606

for (const [bucket, users] of Object.entries(roiBuckets)) {
    if (users.length === 0) continue
    const avgLoss = (users.reduce((sum, u) => sum + Math.abs(u.loss), 0) / users.length).toFixed(2)
    const pct = ((users.length / unprofitableUsers.length) * 100).toFixed(1)

    // Check how many would be profitable with dynamic pricing
    const wouldBeProfit = users.filter(u => {
        const dynamicFee = u.originalFee * (VAPE_PRICE / REF_PRICE)
        return u.vapeValueUSD >= dynamicFee
    }).length

    console.log(`${bucket.padEnd(20)} |   ${String(users.length).padStart(2)}  |   ${pct.padStart(5)}%  |  $${avgLoss.padStart(5)} |     ${wouldBeProfit}/${users.length} (${((wouldBeProfit / users.length) * 100).toFixed(0)}%)`)
}

// Worst losses
console.log('\n' + '─'.repeat(80))
console.log('TOP 10 BIGGEST LOSSES')
console.log('─'.repeat(80))

const sorted = [...unprofitableUsers].sort((a, b) => a.loss - b.loss)
console.log('\nWallet                                     | Tier | Deposited       | VAPE Value | Fee    | Loss    | ROI')
console.log('─'.repeat(105))

for (const user of sorted.slice(0, 10)) {
    console.log(
        `${user.wallet.slice(0, 42)} | ${String(user.tier).padStart(4)} | ${user.depositedStr.padStart(15)} | $${user.vapeValueUSD.toFixed(2).padStart(7)} | $${user.originalFee.toFixed(2).padStart(5)} | -$${Math.abs(user.loss).toFixed(2).padStart(5)} | ${user.roi.toFixed(2)}x`
    )
}

// Summary
console.log('\n' + '═'.repeat(80))
console.log('KEY INSIGHTS')
console.log('═'.repeat(80))

const maxedUsers = unprofitableUsers.filter(u => u.utilization >= 95)
const underUsers = unprofitableUsers.filter(u => u.utilization < 95)
const wouldBeProfitDynamic = unprofitableUsers.filter(u => {
    const dynamicFee = u.originalFee * (VAPE_PRICE / REF_PRICE)
    return u.vapeValueUSD >= dynamicFee
}).length

console.log(`
1. UTILIZATION IS NOT THE PROBLEM
   • ${maxedUsers.length}/${unprofitableUsers.length} (${((maxedUsers.length / unprofitableUsers.length) * 100).toFixed(0)}%) unprofitable users MAXED their tier deposit
   • Even 100% utilization doesn't guarantee profit at current VAPE price

2. LOWER TIERS HIT HARDEST
   • Tier 1-4 account for ${unprofitableUsers.filter(u => u.tier <= 4).length}/${unprofitableUsers.length} unprofitable users
   • These users pay $0.50-$4 fees for small deposits that can't generate enough rewards

3. DYNAMIC PRICING WOULD FIX ${((wouldBeProfitDynamic / unprofitableUsers.length) * 100).toFixed(0)}% OF CASES
   • ${wouldBeProfitDynamic}/${unprofitableUsers.length} unprofitable users would become profitable
   • Only ${unprofitableUsers.length - wouldBeProfitDynamic} would remain unprofitable (very low engagement)

4. TOTAL LOSSES: $${grandTotalLoss.toFixed(2)}
   • Average loss per user: $${(grandTotalLoss / unprofitableUsers.length).toFixed(2)}
   • This is money users lost to fees they couldn't recover
`)
