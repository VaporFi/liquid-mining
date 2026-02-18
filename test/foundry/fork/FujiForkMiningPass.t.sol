// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDiamondCut} from "clouds/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "clouds/interfaces/IDiamondLoupe.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {MiningPassFacet} from "src/facets/MiningPassFacet.sol";
import {BoostFacet} from "src/facets/BoostFacet.sol";
import {DepositFacet} from "src/facets/DepositFacet.sol";
import {ClaimFacet} from "src/facets/ClaimFacet.sol";
import {UnlockFacet} from "src/facets/UnlockFacet.sol";
import {WithdrawFacet} from "src/facets/WithdrawFacet.sol";
import {FeeCollectorFacet} from "src/facets/FeeCollectorFacet.sol";
import {AuthorizationFacet} from "src/facets/AuthorizationFacet.sol";
import {PausationFacet} from "src/facets/PausationFacet.sol";
import {FujiMigrationInit} from "src/upgradeInitializers/FujiMigrationInit.sol";

/// @title FujiForkMiningPassTest
/// @notice Fork test against the real Fuji diamond to verify the storage
///         migration from the 14f06c0 layout to the production layout.
///
///         Fuji was deployed at commit 14f06c0 which placed GENERAL fields
///         (depositToken, rewardToken, feeToken) at slots 25-27. Production
///         has them at slots 21-23.
///
///         The migration initializer reads scalars from old slots 25-30,
///         writes them to production slots 21-26, then re-initializes all
///         mapping/array config data that moved between slot numbers.
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
    //                   PRE-MIGRATION STORAGE CHECK
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Confirm that on-chain Fuji storage has GENERAL fields at
    ///         the OLD 14f06c0 slots (25-28), not production slots (21-24).
    function test_Fork_PreMigration_OldSlotLayout() public {
        // Old Fuji 14f06c0 layout: GENERAL at slots 25-28
        address slot25 = _readAddress(25);
        address slot26 = _readAddress(26);
        address slot27 = _readAddress(27);
        address slot28 = _readAddress(28);

        console.log("Pre-migration (old Fuji slots 25-28):");
        console.log("  slot 25:", slot25);
        console.log("  slot 26:", slot26);
        console.log("  slot 27:", slot27);
        console.log("  slot 28:", slot28);

        assertEq(slot25, VPND, "old slot 25 should be VPND (depositToken)");
        assertEq(slot26, VAPE, "old slot 26 should be VAPE (rewardToken)");
        assertEq(slot27, USDC, "old slot 27 should be USDC (feeToken)");
        assertEq(slot28, STRATOSPHERE, "old slot 28 should be stratosphere");

        // Production slots 21-24 should NOT have these values yet
        address slot21 = _readAddress(21);
        address slot23 = _readAddress(23);
        assertTrue(slot21 != VPND, "prod slot 21 should NOT have VPND yet");
        assertTrue(slot23 != USDC, "prod slot 23 should NOT have USDC yet");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                    POST-MIGRATION STORAGE CHECK
    // ═══════════════════════════════════════════════════════════════════

    /// @notice After the full migration, GENERAL fields should be at
    ///         production slots (21-26) and facet reads should work.
    function test_Fork_AfterMigration_FeeTokenIsUSDC() public {
        _upgradeAndMigrate();

        // Verify raw storage at production slots
        assertEq(_readAddress(21), VPND, "prod slot 21 = depositToken = VPND");
        assertEq(_readAddress(22), VAPE, "prod slot 22 = rewardToken = VAPE");
        assertEq(_readAddress(23), USDC, "prod slot 23 = feeToken = USDC");
        assertEq(_readAddress(24), STRATOSPHERE, "prod slot 24 = stratosphere");

        // Old Fuji slot 27 should be cleared (was USDC/feeToken before migration)
        assertEq(_readAddress(27), address(0), "old slot 27 should be cleared");
        // Slot 28 is now miningPassFeeFloorBps (= 2500), NOT an old address slot
        assertEq(uint256(vm.load(DIAMOND, bytes32(uint256(28)))), 2500, "slot 28 = miningPassFeeFloorBps = 2500");

        // Verify via facet getters
        assertEq(diamond.getStratosphereAddress(), STRATOSPHERE, "stratosphere getter works");

        // Verify mining pass fees were re-initialized
        uint256 tier1Fee = diamond.getMiningPassTierFee(1);
        console.log("Tier 1 fee:", tier1Fee);
        assertEq(tier1Fee, 0.5 * 1e6, "tier 1 fee should be 0.5 USDC");

        uint256 floorBps = diamond.getMiningPassFeeFloorBps();
        assertEq(floorBps, 2500, "floor should be 2500 bps");
    }

    /// @notice Full e2e: migrate -> purchase mining pass -> only USDC is spent
    function test_Fork_AfterMigration_PurchaseUsesUSDC() public {
        _upgradeAndMigrate();
        _ensureActiveSeason();

        uint256 fee = diamond.getMiningPassTierFee(1);
        require(fee > 0, "fee is 0");
        console.log("Tier 1 fee:", fee);

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

    /// @dev Upgrade ALL facets + run the FujiMigrationInit initializer in a
    ///      single diamondCut call — exactly how the real upgrade will work.
    function _upgradeAndMigrate() internal {
        // Deploy the migration initializer
        FujiMigrationInit migrationInit = new FujiMigrationInit();

        // Build cuts array: deploy new facets, look up old facet via loupe, replace
        IDiamondCut.FacetCut[] memory cuts = _buildAllFacetCuts();

        // Encode the migration initializer call
        FujiMigrationInit.Args memory migArgs = _buildMigrationArgs();

        vm.prank(owner);
        IDiamondCut(DIAMOND)
            .diamondCut(cuts, address(migrationInit), abi.encodeWithSelector(FujiMigrationInit.init.selector, migArgs));
    }

    function _buildAllFacetCuts() internal returns (IDiamondCut.FacetCut[] memory cuts) {
        cuts = new IDiamondCut.FacetCut[](10);
        cuts[0] = _deployAndReplace(address(new DiamondManagerFacet()), DiamondManagerFacet.setDepositToken.selector);
        cuts[1] = _deployAndReplace(address(new MiningPassFacet()), MiningPassFacet.purchase.selector);
        cuts[2] = _deployAndReplace(address(new BoostFacet()), BoostFacet.claimBoost.selector);
        cuts[3] = _deployAndReplace(address(new DepositFacet()), DepositFacet.deposit.selector);
        cuts[4] = _deployAndReplace(address(new ClaimFacet()), ClaimFacet.automatedClaim.selector);
        cuts[5] = _deployAndReplace(address(new UnlockFacet()), UnlockFacet.unlock.selector);
        cuts[6] = _deployAndReplace(address(new WithdrawFacet()), WithdrawFacet.withdrawUnlocked.selector);
        cuts[7] = _deployAndReplace(address(new FeeCollectorFacet()), FeeCollectorFacet.collectBoostFees.selector);
        cuts[8] = _deployAndReplace(address(new AuthorizationFacet()), AuthorizationFacet.authorize.selector);
        cuts[9] = _deployAndReplace(address(new PausationFacet()), PausationFacet.pause.selector);
    }

    function _deployAndReplace(address newFacet, bytes4 knownSelector)
        internal
        view
        returns (IDiamondCut.FacetCut memory)
    {
        address oldFacet = loupe.facetAddress(knownSelector);
        bytes4[] memory selectors = loupe.facetFunctionSelectors(oldFacet);
        return IDiamondCut.FacetCut({
            facetAddress: newFacet, action: IDiamondCut.FacetCutAction.Replace, functionSelectors: selectors
        });
    }

    function _buildMigrationArgs() internal returns (FujiMigrationInit.Args memory migArgs) {
        migArgs.unlockFeeReceivers = new address[](1);
        migArgs.unlockFeeReceivers[0] = makeAddr("unlockFeeReceiver");
        migArgs.unlockFeeReceiversShares = new uint256[](1);
        migArgs.unlockFeeReceiversShares[0] = 10000;

        migArgs.boostFeeReceivers = new address[](1);
        migArgs.boostFeeReceivers[0] = makeAddr("boostFeeReceiver");
        migArgs.boostFeeReceiversShares = new uint256[](1);
        migArgs.boostFeeReceiversShares[0] = 10000;

        migArgs.miningPassFeeReceivers = new address[](1);
        migArgs.miningPassFeeReceivers[0] = makeAddr("miningPassFeeReceiver");
        migArgs.miningPassFeeReceiversShares = new uint256[](1);
        migArgs.miningPassFeeReceiversShares[0] = 10000;
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
