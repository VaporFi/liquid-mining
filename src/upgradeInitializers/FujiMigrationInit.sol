// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {AppStorage} from "../libraries/AppStorage.sol";

/// @title FujiMigrationInit
/// @notice One-time migration initializer for the Fuji testnet diamond.
///
/// Problem: Fuji was deployed at commit 14f06c0 which had a different AppStorage
/// layout (extra unlock discount mappings at slots 8-10 and restake fields at
/// slots 19-21) compared to production. This shifted the GENERAL section
/// (depositToken, rewardToken, feeToken, etc.) to slots 25-30 on Fuji, whereas
/// production has them at slots 21-26.
///
/// This initializer:
///  1. Reads the 6 GENERAL scalar values from old Fuji slots 25-30
///  2. Writes them to production-compatible slots 21-26
///  3. Clears the old slots 27-30 to avoid stale data
///  4. Re-initializes all mapping/array-based config (fees, receivers, etc.)
///     since mapping data is keyed by keccak256(key, slot) and won't carry over
///
/// After running this, the Fuji diamond's storage layout matches production,
/// and all facets compiled against the production AppStorage will work correctly.
contract FujiMigrationInit {
    AppStorage s;

    struct Args {
        // Fee receivers for unlock
        address[] unlockFeeReceivers;
        uint256[] unlockFeeReceiversShares;
        // Fee receivers for boost
        address[] boostFeeReceivers;
        uint256[] boostFeeReceiversShares;
        // Fee receivers for mining pass
        address[] miningPassFeeReceivers;
        uint256[] miningPassFeeReceiversShares;
    }

    /// @notice Migrate Fuji storage from 14f06c0 layout to production layout.
    /// @dev Must be called via diamondCut delegatecall exactly once.
    function init(Args memory _args) external {
        // ─── Step 1: Migrate GENERAL scalars from old Fuji slots to prod slots ───
        //
        // Old Fuji layout (14f06c0):     Production layout:
        //   slot 25 = depositToken        slot 21 = depositToken
        //   slot 26 = rewardToken         slot 22 = rewardToken
        //   slot 27 = feeToken            slot 23 = feeToken
        //   slot 28 = stratosphereAddress slot 24 = stratosphereAddress
        //   slot 29 = reentrancyGuardStatus slot 25 = reentrancyGuardStatus
        //   slot 30 = emissionsManager    slot 26 = emissionsManager
        //
        // We read from old slots and write to new slots using assembly.
        // New slots 21-24 were previously mapping base slots (pendingWithdrawals,
        // miningPassTierToFee, etc.) which are always 0, so overwriting is safe.

        address depositToken;
        address rewardToken;
        address feeToken;
        address stratosphereAddress;
        uint256 reentrancyGuardStatus;
        address emissionsManager;

        assembly {
            depositToken := sload(25)
            rewardToken := sload(26)
            feeToken := sload(27)
            stratosphereAddress := sload(28)
            reentrancyGuardStatus := sload(29)
            emissionsManager := sload(30)
        }

        // Verify we read valid data (sanity check)
        require(depositToken != address(0), "FujiMigration: depositToken is zero");
        require(feeToken != address(0), "FujiMigration: feeToken is zero");

        assembly {
            // Write to production slots (21-26)
            sstore(21, depositToken)
            sstore(22, rewardToken)
            sstore(23, feeToken)
            sstore(24, stratosphereAddress)
            sstore(25, reentrancyGuardStatus)
            sstore(26, emissionsManager)

            // Clear old slots that are no longer used as scalars
            // Slot 27 is now baseMiningPassTierToFee (mapping base = 0)
            sstore(27, 0)
            // Slot 28 is now miningPassFeeFloorBps (will be set below)
            // Slot 29 is now gelatoExecutor (address, leave 0 for now)
            sstore(29, 0)
            // Slot 30 is now isSeasonClaimed (mapping base = 0)
            sstore(30, 0)
        }

        // ─── Step 2: Re-initialize mapping/array data ───
        // Mappings use keccak256(key, slot) for storage, so data written under
        // old slot numbers is now inaccessible. We must re-set everything.

        // Unlock fee receivers (prod slots 9-10, old Fuji slots 12-13)
        // Clear any stale length at slots 9-10 first
        _clearArray(9);
        _clearArray(10);
        for (uint256 i = 0; i < _args.unlockFeeReceivers.length; i++) {
            s.unlockFeeReceivers.push(_args.unlockFeeReceivers[i]);
            s.unlockFeeReceiversShares.push(_args.unlockFeeReceiversShares[i]);
        }

        // Boost fee receivers (prod slots 14-15, old Fuji slots 17-18)
        _clearArray(14);
        _clearArray(15);
        for (uint256 i = 0; i < _args.boostFeeReceivers.length; i++) {
            s.boostFeeReceivers.push(_args.boostFeeReceivers[i]);
            s.boostFeeReceiversShares.push(_args.boostFeeReceiversShares[i]);
        }

        // Mining pass fee receivers (prod slots 19-20, never existed in 14f06c0)
        _clearArray(19);
        _clearArray(20);
        for (uint256 i = 0; i < _args.miningPassFeeReceivers.length; i++) {
            s.miningPassFeeReceivers.push(_args.miningPassFeeReceivers[i]);
            s.miningPassFeeReceiversShares.push(_args.miningPassFeeReceiversShares[i]);
        }

        // Re-initialize mining pass fees (prod slot 17, old Fuji slot 23)
        s.miningPassTierToFee[0] = 0;
        s.miningPassTierToFee[1] = 0.5 * 1e6;
        s.miningPassTierToFee[2] = 1 * 1e6;
        s.miningPassTierToFee[3] = 2 * 1e6;
        s.miningPassTierToFee[4] = 4 * 1e6;
        s.miningPassTierToFee[5] = 8 * 1e6;
        s.miningPassTierToFee[6] = 15 * 1e6;
        s.miningPassTierToFee[7] = 30 * 1e6;
        s.miningPassTierToFee[8] = 50 * 1e6;
        s.miningPassTierToFee[9] = 75 * 1e6;
        s.miningPassTierToFee[10] = 100 * 1e6;

        // Base mining pass fees (prod slot 27, new field)
        s.baseMiningPassTierToFee[0] = 0;
        s.baseMiningPassTierToFee[1] = 0.5 * 1e6;
        s.baseMiningPassTierToFee[2] = 1 * 1e6;
        s.baseMiningPassTierToFee[3] = 2 * 1e6;
        s.baseMiningPassTierToFee[4] = 4 * 1e6;
        s.baseMiningPassTierToFee[5] = 8 * 1e6;
        s.baseMiningPassTierToFee[6] = 15 * 1e6;
        s.baseMiningPassTierToFee[7] = 30 * 1e6;
        s.baseMiningPassTierToFee[8] = 50 * 1e6;
        s.baseMiningPassTierToFee[9] = 75 * 1e6;
        s.baseMiningPassTierToFee[10] = 100 * 1e6;

        // Mining pass deposit limits (prod slot 18, old Fuji slot 24)
        s.miningPassTierToDepositLimit[0] = 5_000 * 1e18;
        s.miningPassTierToDepositLimit[1] = 10_000 * 1e18;
        s.miningPassTierToDepositLimit[2] = 25_000 * 1e18;
        s.miningPassTierToDepositLimit[3] = 60_000 * 1e18;
        s.miningPassTierToDepositLimit[4] = 150_000 * 1e18;
        s.miningPassTierToDepositLimit[5] = 350_000 * 1e18;
        s.miningPassTierToDepositLimit[6] = 800_000 * 1e18;
        s.miningPassTierToDepositLimit[7] = 1_800_000 * 1e18;
        s.miningPassTierToDepositLimit[8] = 4_500_000 * 1e18;
        s.miningPassTierToDepositLimit[9] = 12_000_000 * 1e18;
        s.miningPassTierToDepositLimit[10] = type(uint256).max;

        // Mining pass fee floor (25% = 2500 bps)
        s.miningPassFeeFloorBps = 2500;

        // Re-initialize unlock timestamp discounts (prod slot 7, same slot in Fuji)
        // These mappings are at the SAME slot (7) in both layouts, so data is still
        // accessible. But let's ensure they're set correctly:
        s.unlockTimestampDiscountForStratosphereMembers[0] = 500;
        s.unlockTimestampDiscountForStratosphereMembers[1] = 550;
        s.unlockTimestampDiscountForStratosphereMembers[2] = 650;
        s.unlockTimestampDiscountForStratosphereMembers[3] = 800;
        s.unlockTimestampDiscountForStratosphereMembers[4] = 1000;
        s.unlockTimestampDiscountForStratosphereMembers[5] = 1500;

        // Re-initialize boost fees (prod slot 12, old Fuji slot 15)
        s.boostLevelToFee[0] = 0;
        s.boostLevelToFee[1] = 2 * 1e6;
        s.boostLevelToFee[2] = 3 * 1e6;
        s.boostLevelToFee[3] = 4 * 1e6;

        // Re-initialize boost percent tiers (prod slot 13, old Fuji slot 16)
        s.boostPercentFromTierToLevel[0][0] = 20;
        s.boostPercentFromTierToLevel[1][0] = 25;
        s.boostPercentFromTierToLevel[2][0] = 33;
        s.boostPercentFromTierToLevel[3][0] = 45;
        s.boostPercentFromTierToLevel[4][0] = 65;
        s.boostPercentFromTierToLevel[5][0] = 100;
        s.boostPercentFromTierToLevel[0][1] = 22;
        s.boostPercentFromTierToLevel[1][1] = 28;
        s.boostPercentFromTierToLevel[2][1] = 37;
        s.boostPercentFromTierToLevel[3][1] = 51;
        s.boostPercentFromTierToLevel[4][1] = 74;
        s.boostPercentFromTierToLevel[5][1] = 115;
        s.boostPercentFromTierToLevel[0][2] = 24;
        s.boostPercentFromTierToLevel[1][2] = 30;
        s.boostPercentFromTierToLevel[2][2] = 40;
        s.boostPercentFromTierToLevel[3][2] = 55;
        s.boostPercentFromTierToLevel[4][2] = 81;
        s.boostPercentFromTierToLevel[5][2] = 125;
        s.boostPercentFromTierToLevel[0][3] = 28;
        s.boostPercentFromTierToLevel[1][3] = 35;
        s.boostPercentFromTierToLevel[2][3] = 47;
        s.boostPercentFromTierToLevel[3][3] = 64;
        s.boostPercentFromTierToLevel[4][3] = 94;
        s.boostPercentFromTierToLevel[5][3] = 145;

        // boostForNonStratMembers (prod slot 11, old Fuji slot 14 — different slot, re-set)
        s.boostForNonStratMembers = 10;
    }

    /// @dev Clear a dynamic array's length so .push() starts fresh.
    ///      Array data at keccak256(slot) is orphaned but harmless.
    function _clearArray(uint256 slot) internal {
        assembly {
            sstore(slot, 0)
        }
    }
}
