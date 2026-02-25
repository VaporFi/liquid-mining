import { ethers, network } from 'hardhat'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'
import { deployContract } from '../utils/deployContract'
import { addOrReplaceFacets } from '../utils/diamond'
import getFacets from '../utils/getFacets'
import { addresses, ChainId } from '../config/addresses'
import { BURN_WALLET } from '../config/constants'

/**
 * Fuji Migration Script
 *
 * Mirrors exactly what the fork test's `_upgradeAndMigrate()` does:
 *  1. Deploy FujiMigrationInit
 *  2. Deploy all facets (except DiamondCutFacet & DiamondLoupeFacet)
 *  3. Encode init(Args) with real Fuji fee receiver addresses
 *  4. Call addOrReplaceFacets with the init contract + calldata
 *
 * The migration initializer:
 *  - Reads GENERAL scalars from old Fuji slots 25-30
 *  - Writes them to production slots 21-26
 *  - Re-initializes all mapping/array config data
 *
 * Usage:
 *   yarn hardhat run --network fuji scripts/migrateFuji.ts
 */
async function main() {
    if (network.name !== 'fuji') {
        throw new Error(
            `This script is ONLY for fuji. Current network: ${network.name}`
        )
    }

    const CHAIN_ID = ChainId.AVALANCHE_TESTNET.toString()

    const diamondAddress =
        LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
            .address

    console.log(`💎 Diamond address: ${diamondAddress}`)
    console.log(`📡 Network: ${network.name}`)

    // ─── 1. Deploy FujiMigrationInit ───
    console.log('\n1️⃣  Deploying FujiMigrationInit...')
    const migrationInit = await deployContract('FujiMigrationInit', {
        args: [],
        log: true,
        skipIfAlreadyDeployed: false, // always deploy fresh
    })
    const migrationInitAddress = await migrationInit.getAddress()
    console.log(`   FujiMigrationInit deployed at: ${migrationInitAddress}`)

    // ─── 2. Deploy all facets ───
    console.log('\n2️⃣  Deploying facets...')
    const FacetNames = getFacets(['DiamondCutFacet', 'DiamondLoupeFacet'])
    console.log(`   Facets to deploy: ${FacetNames.join(', ')}`)

    const Facets = []
    for (const name of FacetNames) {
        Facets.push(await deployContract(name))
    }

    // ─── 3. Build migration init calldata ───
    console.log('\n3️⃣  Building migration init calldata...')

    // Real Fuji fee receiver addresses (same as DiamondInit / deployDiamond.ts)
    const labsMultisig = addresses.teamMultisig[CHAIN_ID]
    const replenishmentPool = addresses.vpndReplenishmentPool[CHAIN_ID]
    const xVAPE = addresses.xVAPE[CHAIN_ID]
    const passport = addresses.passportPool[CHAIN_ID]

    console.log(`   labsMultisig:      ${labsMultisig}`)
    console.log(`   replenishmentPool: ${replenishmentPool}`)
    console.log(`   xVAPE:             ${xVAPE}`)
    console.log(`   passport:          ${passport}`)
    console.log(`   burnWallet:        ${BURN_WALLET}`)

    // Match DiamondInit.sol fee receiver structure exactly
    const migrationArgs = {
        // Unlock: replenishmentPool 80%, labsMultisig 10%, burnWallet 10%
        unlockFeeReceivers: [replenishmentPool, labsMultisig, BURN_WALLET],
        unlockFeeReceiversShares: [8000, 1000, 1000],
        // Boost: labsMultisig 60%, xVAPE 30%, passport 10%
        boostFeeReceivers: [labsMultisig, xVAPE, passport],
        boostFeeReceiversShares: [6000, 3000, 1000],
        // Mining pass: xVAPE 65%, labsMultisig 30%, passport 5%
        miningPassFeeReceivers: [xVAPE, labsMultisig, passport],
        miningPassFeeReceiversShares: [6500, 3000, 500],
    }

    const initCalldata = migrationInit.interface.encodeFunctionData('init', [
        migrationArgs,
    ])

    console.log(`   Calldata length: ${initCalldata.length} chars`)

    // ─── 4. Execute diamondCut with migration init ───
    console.log('\n4️⃣  Executing diamondCut (addOrReplaceFacets + migration init)...')
    await addOrReplaceFacets(
        Facets,
        diamondAddress,
        migrationInitAddress,
        initCalldata,
        undefined // no Safe — direct EOA tx
    )

    console.log('\n✅ Fuji migration complete!')
    console.log(
        '   Storage has been migrated from 14f06c0 layout to production layout.'
    )
    console.log(
        '   All facets replaced and mapping/array data re-initialized.'
    )
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error('❌ Migration failed:', error)
        process.exit(1)
    })
