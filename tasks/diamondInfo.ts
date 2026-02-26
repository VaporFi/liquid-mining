import { task } from 'hardhat/config'
import { formatEther, formatUnits } from 'ethers'
import LiquidMiningDiamond from '../deployments/LiquidMiningDiamond.json'

task(
    'diamond:info',
    'Read and display all key parameters from the DiamondManagerFacet'
)
    .addOptionalParam('user', 'Address to query user-specific data for')
    .setAction(async ({ user }, { ethers, network }) => {
        const diamondAddress =
            LiquidMiningDiamond[network.name as keyof typeof LiquidMiningDiamond]
                .address

        const dm = await ethers.getContractAt(
            'DiamondManagerFacet',
            diamondAddress
        )

        console.log(`\n💎 Diamond: ${diamondAddress} (${network.name})`)

        // ── General ────────────────────────────────────────────────────────
        const stratAddress = await dm.getStratosphereAddress()
        console.log(`\n═══ General ═══`)
        console.log(`  Stratosphere:  ${stratAddress}`)

        // ── Current Season ─────────────────────────────────────────────────
        const seasonId = await dm.getCurrentSeasonId()
        const seasonData = await dm.getSeasonData(seasonId)
        const seasonEnd = await dm.getSeasonEndTimestamp(seasonId)
        const isClaimed = await dm.getSeasonIsClaimed(seasonId)

        const endDate = new Date(Number(seasonEnd) * 1000)
        const now = new Date()
        const daysLeft = Math.max(
            0,
            Math.ceil((endDate.getTime() - now.getTime()) / 86400000)
        )

        console.log(`\n═══ Current Season (${seasonId}) ═══`)
        console.log(
            `  End:             ${endDate.toISOString().split('T')[0]} (${daysLeft} days left)`
        )
        console.log(
            `  Rewards:         ${formatEther(seasonData.rewardTokensToDistribute)} VAPE`
        )
        console.log(
            `  Reward Balance:  ${formatEther(seasonData.rewardTokenBalance)} VAPE`
        )
        console.log(
            `  Total Deposits:  ${formatEther(seasonData.totalDepositAmount)} VPND`
        )
        console.log(
            `  Total Points:    ${formatEther(seasonData.totalPoints)}`
        )
        console.log(
            `  Total Claimed:   ${formatEther(seasonData.totalClaimAmount)} VAPE`
        )
        console.log(`  Season Claimed:  ${isClaimed}`)

        // ── Mining Pass Fees ───────────────────────────────────────────────
        const floorBps = await dm.getMiningPassFeeFloorBps()

        console.log(`\n═══ Mining Pass Fees (Floor: ${Number(floorBps) / 100}%) ═══`)
        console.log(
            'Tier | Base Fee ($) | Current ($) | Floor ($)  | Deposit Limit'
        )
        console.log(
            '-----|-------------|-------------|------------|------------------'
        )

        for (let i = 0; i <= 10; i++) {
            const baseFee = await dm.getBaseMiningPassTierFee(i)
            const currentFee = await dm.getMiningPassTierFee(i)
            const floorFee = await dm.getMiningPassTierFloorFee(i)
            const depositLimit = await dm.getMiningPassTierDepositLimit(i)

            const limitStr =
                depositLimit === BigInt(2) ** BigInt(256) - BigInt(1)
                    ? 'Unlimited'
                    : `${formatEther(depositLimit)} VPND`

            console.log(
                `  ${i.toString().padStart(2)} | ${(Number(baseFee) / 1e6).toFixed(2).padStart(11)} | ${(Number(currentFee) / 1e6).toFixed(2).padStart(11)} | ${(Number(floorFee) / 1e6).toFixed(2).padStart(10)} | ${limitStr}`
            )
        }

        // ── Historical Seasons ─────────────────────────────────────────────
        const numSeasons = Number(seasonId)
        if (numSeasons > 1) {
            console.log(`\n═══ Season History ═══`)
            console.log(
                'Season | Rewards (VAPE) | Deposits (VPND)   | Total Points'
            )
            console.log(
                '-------|----------------|-------------------|------------------'
            )
            for (
                let i = Math.max(1, numSeasons - 4);
                i <= numSeasons;
                i++
            ) {
                const sd = await dm.getSeasonData(i)
                console.log(
                    `    ${i.toString().padStart(2)} | ${formatEther(sd.rewardTokensToDistribute).padStart(14)} | ${formatEther(sd.totalDepositAmount).padStart(17)} | ${formatEther(sd.totalPoints)}`
                )
            }
        }

        // ── User Data (optional) ───────────────────────────────────────────
        if (user) {
            console.log(`\n═══ User: ${user} ═══`)
            const userData = await dm.getUserDataForCurrentSeason(user)
            const [depositAmount, depositTimestamp] = await dm.getUserDepositAmount(
                user,
                seasonId
            )
            const [depositPoints, boostPoints] = await dm.getUserPoints(
                user,
                seasonId
            )
            const claimedRewards = await dm.getUserClaimedRewards(user, seasonId)
            const unlockAmount = await dm.getUnlockAmountOfUser(user, seasonId)
            const unlockTimestamp = await dm.getUnlockTimestampOfUser(user, seasonId)
            const restakeStatus = await dm.getWithdrawRestakeStatus(user, seasonId)

            console.log(
                `  Deposit:         ${formatEther(depositAmount)} VPND`
            )
            console.log(
                `  Deposit Points:  ${formatEther(depositPoints)}`
            )
            console.log(
                `  Boost Points:    ${formatEther(boostPoints)}`
            )
            console.log(
                `  Claimed Rewards: ${formatEther(claimedRewards)} VAPE`
            )
            console.log(
                `  Unlock Amount:   ${formatEther(unlockAmount)} VPND`
            )
            if (Number(unlockTimestamp) > 0) {
                console.log(
                    `  Unlock Time:     ${new Date(Number(unlockTimestamp) * 1000).toISOString()}`
                )
            }
            console.log(`  Restake Status:  ${restakeStatus}`)

            try {
                const details = await dm.getCurrentSeasonUserDetails(user)
                console.log(
                    `  Pool Share:      ${(Number(details.poolShareBips) / 100).toFixed(2)}%`
                )
                console.log(
                    `  Est. Rewards:    ${formatEther(details.estimatedRewards)} VAPE`
                )
            } catch {
                // totalPoints may be 0
            }
        }

        console.log('')
    })
