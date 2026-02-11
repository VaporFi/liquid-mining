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

let notProfitableMaxed = 0
let notProfitableNotMaxed = 0
let profitableMaxed = 0
let profitableNotMaxed = 0

console.log('USERS NOT PROFITABLE (Original Pricing):\n')
console.log('Wallet                                     | Tier | Limit       | Deposited       | % of Limit | ROI')
console.log('-'.repeat(110))

for (const line of lines) {
    if (!line.includes('0x')) continue

    const cols = line.match(/"([^"]*)"/g)?.map((c) => c.replace(/"/g, '')) || []
    if (cols.length < 16) continue

    const [wallet, tier, limitStr, depositedStr, , , , , , , origROI, , , , origProfitable] = cols

    if (tier === '0' || origProfitable === 'Free Tier') continue

    const limit = tierLimits[limitStr] || 0
    const deposited = parseFloat(depositedStr.replace(/,/g, ''))
    const pctOfLimit = ((deposited / limit) * 100).toFixed(1)
    const isMaxed = deposited >= limit * 0.95
    const isProfitable = origProfitable === 'Yes'

    if (!isProfitable) {
        console.log(
            `${wallet.padEnd(42)} | ${tier.padEnd(4)} | ${limitStr.padEnd(11)} | ${depositedStr.padEnd(15)} | ${pctOfLimit.padStart(6)}% | ${origROI}x`
        )
        if (isMaxed) notProfitableMaxed++
        else notProfitableNotMaxed++
    } else {
        if (isMaxed) profitableMaxed++
        else profitableNotMaxed++
    }
}

console.log('\n' + '='.repeat(110))
console.log('\nSUMMARY (Paid Pass Users Only):')
console.log('─'.repeat(50))
console.log(`NOT Profitable + Maxed Deposit (≥95%):     ${notProfitableMaxed}`)
console.log(`NOT Profitable + Under Deposit (<95%):    ${notProfitableNotMaxed}`)
console.log(`Profitable + Maxed Deposit (≥95%):        ${profitableMaxed}`)
console.log(`Profitable + Under Deposit (<95%):        ${profitableNotMaxed}`)
console.log('─'.repeat(50))
console.log(`\nTotal Not Profitable: ${notProfitableMaxed + notProfitableNotMaxed}`)
console.log(`Total Profitable: ${profitableMaxed + profitableNotMaxed}`)

const totalNotProfit = notProfitableMaxed + notProfitableNotMaxed
const pctNotMaxed = ((notProfitableNotMaxed / totalNotProfit) * 100).toFixed(1)
console.log(`\n📊 Of ${totalNotProfit} unprofitable users, ${notProfitableNotMaxed} (${pctNotMaxed}%) did NOT max their tier limit`)
