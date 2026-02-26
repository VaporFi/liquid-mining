// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDiamondLoupe} from "clouds/interfaces/IDiamondLoupe.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {MiningPassFacet} from "src/facets/MiningPassFacet.sol";

/// @title FujiForkMiningPassTest
/// @notice Post-migration fork tests against the live Fuji diamond.
///         Verifies that the storage layout matches production (GENERAL at
///         slots 21-26), dynamic pricing getters work, and mining pass
///         purchases use USDC (not VPND).
contract FujiForkMiningPassTest is Test {
    // ──── Real Fuji addresses ────
    address constant DIAMOND = 0xEd98549D4dE52811b3b417A717E3d74AC90F9Ffe;
    address constant VPND = 0x096F22B7891DeA0e9340365Be2021eEa562D0b55;
    address constant USDC = 0xeA42E3030ab1406a0b6aAd077Caa927673a2c302;
    address constant VAPE = 0x0914aFfEbBAe91fB410A3Cd85a0C7AC740b030cF;
    address constant STRATOSPHERE = 0x26b794235422e7c6f3ac6c717b10598C2a144203;

    DiamondManagerFacet diamond;
    MiningPassFacet miningPass;
    IDiamondLoupe loupe;
    address owner;
    address user;

    function setUp() public {
        vm.createSelectFork("fuji");

        diamond = DiamondManagerFacet(DIAMOND);
        miningPass = MiningPassFacet(DIAMOND);
        loupe = IDiamondLoupe(DIAMOND);
        user = makeAddr("testUser");

        (bool ok, bytes memory data) = DIAMOND.staticcall(abi.encodeWithSignature("owner()"));
        require(ok, "owner() call failed");
        owner = abi.decode(data, (address));
    }

    // ═══════════════════════════════════════════════════════════════════
    //                 STORAGE SLOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify GENERAL fields are at production-compatible slots 21-26
    function test_Fork_StorageSlots_GeneralSection() public {
        assertEq(_readAddress(21), VPND, "slot 21 = depositToken = VPND");
        assertEq(_readAddress(22), VAPE, "slot 22 = rewardToken = VAPE");
        assertEq(_readAddress(23), USDC, "slot 23 = feeToken = USDC");
        assertEq(_readAddress(24), STRATOSPHERE, "slot 24 = stratosphere");

        // slot 25 = reentrancyGuardStatus (uint256, should be 0 or 1)
        uint256 reentrancy = uint256(vm.load(DIAMOND, bytes32(uint256(25))));
        assertTrue(reentrancy <= 2, "slot 25 = reentrancyGuardStatus <= 2");

        // slot 28 = miningPassFeeFloorBps
        uint256 floorBps = uint256(vm.load(DIAMOND, bytes32(uint256(28))));
        assertEq(floorBps, 2500, "slot 28 = miningPassFeeFloorBps = 2500");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                FACET GETTER VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify facet getters return correct values after migration
    function test_Fork_FacetGetters() public {
        // General getters
        assertEq(diamond.getStratosphereAddress(), STRATOSPHERE, "stratosphere getter");

        // Dynamic pricing getters
        uint256 floorBps = diamond.getMiningPassFeeFloorBps();
        assertEq(floorBps, 2500, "floor should be 2500 bps");

        // Mining pass tier fees should be set (tier 0 = free, tier 1+ > 0)
        assertEq(diamond.getMiningPassTierFee(0), 0, "tier 0 is free");
        assertTrue(diamond.getMiningPassTierFee(1) > 0, "tier 1 fee > 0");

        // Base fees should match current fees (initially equal)
        uint256 baseFee1 = diamond.getBaseMiningPassTierFee(1);
        assertTrue(baseFee1 > 0, "base fee tier 1 > 0");

        // Floor fee should be baseFee * floorBps / 10000
        uint256 floorFee1 = diamond.getMiningPassTierFloorFee(1);
        assertEq(floorFee1, (baseFee1 * floorBps) / 10000, "floor fee = baseFee * 2500 / 10000");

        // getAllMiningPassFees should return 11 entries
        uint256[] memory allFees = diamond.getAllMiningPassFees();
        assertEq(allFees.length, 11, "should have 11 tiers");
        assertEq(allFees[0], 0, "tier 0 free in array");

        // Deposit limits
        uint256 limit0 = diamond.getMiningPassTierDepositLimit(0);
        uint256 limit1 = diamond.getMiningPassTierDepositLimit(1);
        assertTrue(limit0 > 0, "tier 0 deposit limit > 0");
        assertTrue(limit1 > limit0, "tier 1 limit > tier 0 limit");

        console.log("Tier 1 fee:", diamond.getMiningPassTierFee(1));
        console.log("Tier 1 base fee:", baseFee1);
        console.log("Tier 1 floor fee:", floorFee1);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     E2E PURCHASE TEST
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Purchase a mining pass and verify USDC is spent (not VPND)
    function test_Fork_PurchaseUsesUSDC() public {
        _ensureActiveSeason();

        // Use getMiningPassFee which accounts for time-based discounts
        uint256 fee = miningPass.getMiningPassFee(user, 1);
        require(fee > 0, "fee is 0");

        deal(USDC, user, fee * 10);
        deal(VPND, user, fee * 10);

        uint256 usdcBefore = IERC20(USDC).balanceOf(user);
        uint256 vpndBefore = IERC20(VPND).balanceOf(user);

        vm.startPrank(user);
        IERC20(USDC).approve(DIAMOND, type(uint256).max);
        IERC20(VPND).approve(DIAMOND, type(uint256).max);
        miningPass.purchase(1);
        vm.stopPrank();

        uint256 usdcSpent = usdcBefore - IERC20(USDC).balanceOf(user);
        uint256 vpndSpent = vpndBefore - IERC20(VPND).balanceOf(user);

        console.log("USDC spent:", usdcSpent);
        console.log("VPND spent:", vpndSpent);

        assertEq(usdcSpent, fee, "USDC should be spent for the fee");
        assertEq(vpndSpent, 0, "VPND should NOT be spent");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                         HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _readAddress(uint256 slot) internal view returns (address) {
        return address(uint160(uint256(vm.load(DIAMOND, bytes32(slot)))));
    }

    function _ensureActiveSeason() internal {
        uint256 seasonId = diamond.getCurrentSeasonId();
        if (seasonId == 0) {
            vm.prank(owner);
            diamond.startNewSeasonWithEndTimestamp(1000 * 1e18, block.timestamp + 30 days);
            return;
        }

        try diamond.getSeasonEndTimestamp(seasonId) returns (uint256 endTs) {
            if (endTs <= block.timestamp) {
                vm.prank(owner);
                diamond.startNewSeasonWithEndTimestamp(1000 * 1e18, block.timestamp + 30 days);
            }
        } catch {
            vm.prank(owner);
            diamond.startNewSeasonWithEndTimestamp(1000 * 1e18, block.timestamp + 30 days);
        }
    }
}
