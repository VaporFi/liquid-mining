// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDiamondCut} from "clouds/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "clouds/interfaces/IDiamondLoupe.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {MiningPassFacet} from "src/facets/MiningPassFacet.sol";

/// @title ProdForkUpgradeTest
/// @notice Fork test against the real Avalanche mainnet diamond.
///         Simulates upgrading DiamondManagerFacet with the new dynamic-pricing
///         version and verifies:
///         1. All existing storage slots are preserved (no corruption)
///         2. New getters work after upgrade
///         3. Owner can initialise dynamic pricing config
///         4. Mining pass purchase still works with USDC
contract ProdForkUpgradeTest is Test {
    // ──── Real mainnet addresses ────
    address constant DIAMOND = 0xAe950fdd0CC79DDE64d3Fffd40fabec3f7ba368B;
    address constant VPND = 0x83a283641C6B4DF383BCDDf807193284C84c5342;
    address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address constant VAPE = 0x7bddaF6DbAB30224AA2116c4291521C7a60D5f55;
    address constant STRAT = 0x08e287adCf9BF6773a87e1a278aa9042BEF44b60;
    address constant EMISSIONS = 0x9f0EDB45c2DC0f56bA7C48368c26426f366Bb788;

    // Fee receivers (from DiamondInit / config)
    address constant xVAPE = 0x0fA2CCC39Cc3B225A7649eD84ec76Ee5217d07c4;
    address constant LABS_MULTISIG = 0x6769DB4e3E94A63089f258B9500e0695586315bA;
    address constant PASSPORT = 0x125177daa21AF2277A2B735212B115c2A302940F;

    // Base mining pass fees (from DiamondInit)
    uint256[11] BASE_FEES =
        [uint256(0), 0.5 * 1e6, 1 * 1e6, 2 * 1e6, 4 * 1e6, 8 * 1e6, 15 * 1e6, 30 * 1e6, 50 * 1e6, 75 * 1e6, 100 * 1e6];

    DiamondManagerFacet diamond;
    MiningPassFacet miningPass;
    IDiamondLoupe loupe;
    address owner;
    address user;

    // ── Pre-upgrade snapshots ──
    bytes32[31] slotsBefore;
    uint256 seasonIdBefore;
    address stratBefore;

    function setUp() public {
        vm.createSelectFork("avalanche");

        diamond = DiamondManagerFacet(DIAMOND);
        miningPass = MiningPassFacet(DIAMOND);
        loupe = IDiamondLoupe(DIAMOND);
        user = makeAddr("testUser");

        (bool ok, bytes memory data) = DIAMOND.staticcall(abi.encodeWithSignature("owner()"));
        require(ok, "owner() call failed");
        owner = abi.decode(data, (address));

        // ── Snapshot all scalar slots 0-30 before upgrade ──
        for (uint256 i; i < 31; i++) {
            slotsBefore[i] = vm.load(DIAMOND, bytes32(i));
        }

        // ── Snapshot via getters ──
        seasonIdBefore = diamond.getCurrentSeasonId();
        stratBefore = diamond.getStratosphereAddress();
    }

    // ═══════════════════════════════════════════════════════════════════
    //              PRE-UPGRADE SANITY: EXISTING LAYOUT
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify the current production layout before we touch anything
    function test_ProdFork_PreUpgrade_StorageLayout() public {
        assertEq(_readAddress(21), VPND, "slot 21 = depositToken = VPND");
        assertEq(_readAddress(22), VAPE, "slot 22 = rewardToken = VAPE");
        assertEq(_readAddress(23), USDC, "slot 23 = feeToken = USDC");
        assertEq(_readAddress(24), STRAT, "slot 24 = stratosphere");
        assertEq(_readAddress(26), EMISSIONS, "slot 26 = emissionsManager");

        console.log("Pre-upgrade: currentSeasonId =", seasonIdBefore);
        console.log("Pre-upgrade: owner           =", owner);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: STORAGE PRESERVATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice After upgrading DiamondManagerFacet, ALL existing storage
    ///         slots must be identical. The upgrade only adds new selectors
    ///         — no initializer, no storage writes.
    function test_ProdFork_PostUpgrade_SlotsPreserved() public {
        _upgradeDiamondManagerFacet();

        // Verify all 31 scalar slots are unchanged
        for (uint256 i; i < 31; i++) {
            bytes32 slotAfter = vm.load(DIAMOND, bytes32(i));
            assertEq(slotAfter, slotsBefore[i], string.concat("slot ", vm.toString(i), " changed after upgrade"));
        }

        // Verify getters still return the same values
        assertEq(diamond.getCurrentSeasonId(), seasonIdBefore, "seasonId changed");
        assertEq(diamond.getStratosphereAddress(), stratBefore, "stratosphere changed");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: getMiningPassTierFee RETURNS EXISTING FEES
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Immediately after upgrade (before any admin init),
    ///         getMiningPassTierFee must return the same fees that were
    ///         already set via DiamondInit. The UI can call this safely.
    function test_ProdFork_PostUpgrade_GetMiningPassTierFeeReturnsExisting() public {
        // Snapshot existing fees BEFORE upgrade via raw storage (slot 17 mapping)
        uint256[11] memory feesBefore;
        for (uint256 i; i < 11; i++) {
            // mapping slot = keccak256(abi.encode(key, baseSlot))
            bytes32 slot = keccak256(abi.encode(i, uint256(17)));
            feesBefore[i] = uint256(vm.load(DIAMOND, slot));
        }

        // Perform upgrade
        _upgradeDiamondManagerFacet();

        // Verify getMiningPassTierFee returns identical values
        for (uint256 i; i < 11; i++) {
            uint256 feeAfter = diamond.getMiningPassTierFee(i);
            assertEq(feeAfter, feesBefore[i], string.concat("tier ", vm.toString(i), " fee changed"));
        }

        // Log for visibility
        console.log("Post-upgrade getMiningPassTierFee sanity:");
        for (uint256 i; i < 11; i++) {
            console.log("  Tier", i, ":", diamond.getMiningPassTierFee(i));
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: miningPassFeeFloorBps VALUE
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Log and verify the miningPassFeeFloorBps value after upgrade.
    ///         On a fresh prod upgrade (no init), slot 28 should be 0.
    function test_ProdFork_PostUpgrade_MiningPassFeeFloorBps() public {
        // Read raw slot 28 before upgrade
        uint256 rawBefore = uint256(vm.load(DIAMOND, bytes32(uint256(28))));
        console.log("miningPassFeeFloorBps (raw slot 28) BEFORE upgrade:", rawBefore);

        _upgradeDiamondManagerFacet();

        // Read via getter after upgrade
        uint256 floorBps = diamond.getMiningPassFeeFloorBps();
        console.log("miningPassFeeFloorBps (getter)      AFTER  upgrade:", floorBps);

        // Read raw slot 28 after upgrade (should be unchanged)
        uint256 rawAfter = uint256(vm.load(DIAMOND, bytes32(uint256(28))));
        console.log("miningPassFeeFloorBps (raw slot 28) AFTER  upgrade:", rawAfter);

        assertEq(rawAfter, rawBefore, "slot 28 should not change during upgrade");
        assertEq(floorBps, rawAfter, "getter should match raw slot");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: GENERAL SLOT INTEGRITY
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify GENERAL section (slots 21-26) is intact after upgrade
    function test_ProdFork_PostUpgrade_GeneralSlots() public {
        _upgradeDiamondManagerFacet();

        assertEq(_readAddress(21), VPND, "slot 21 = depositToken");
        assertEq(_readAddress(22), VAPE, "slot 22 = rewardToken");
        assertEq(_readAddress(23), USDC, "slot 23 = feeToken");
        assertEq(_readAddress(24), STRAT, "slot 24 = stratosphere");
        assertEq(_readAddress(26), EMISSIONS, "slot 26 = emissionsManager");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: NEW GETTERS (UNINITIALISED)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice New dynamic pricing getters should work but return zero/defaults
    ///         since production hasn't initialised baseMiningPassTierToFee yet.
    function test_ProdFork_PostUpgrade_NewGettersDefaults() public {
        _upgradeDiamondManagerFacet();

        // baseMiningPassTierToFee (slot 27 mapping) — uninitialised → 0
        for (uint256 i; i < 11; i++) {
            assertEq(diamond.getBaseMiningPassTierFee(i), 0, "base fee should be 0 before init");
        }

        // miningPassFeeFloorBps (slot 28) — uninitialised → 0
        assertEq(diamond.getMiningPassFeeFloorBps(), 0, "floor bps should be 0 before init");

        // getAllMiningPassFees should return the EXISTING fees (they were
        // already set in miningPassTierToFee mapping at slot 17)
        uint256[] memory fees = diamond.getAllMiningPassFees();
        assertEq(fees.length, 11, "should have 11 tiers");
        // Existing fees should be present (production had them set via DiamondInit)
        console.log("Existing tier 1 fee:", fees[1]);
        console.log("Existing tier 10 fee:", fees[10]);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: INITIALISE DYNAMIC PRICING
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Owner sets base fees, floor, then updates dynamic fees.
    ///         Simulates the exact post-upgrade admin sequence.
    function test_ProdFork_PostUpgrade_InitialiseDynamicPricing() public {
        _upgradeDiamondManagerFacet();

        vm.startPrank(owner);

        // 1. Set base fees
        uint256[] memory baseFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            baseFees[i] = BASE_FEES[i];
        }
        diamond.setBaseMiningPassFees(baseFees);

        // Verify base fees stored
        for (uint256 i; i < 11; i++) {
            assertEq(diamond.getBaseMiningPassTierFee(i), BASE_FEES[i], "base fee mismatch");
        }

        // 2. Set floor to 25%
        diamond.setMiningPassFeeFloor(2500);
        assertEq(diamond.getMiningPassFeeFloorBps(), 2500, "floor not set");

        // 3. Verify floor fee calculation
        // Floor for tier 10: 100 USDC * 25% = 25 USDC
        assertEq(diamond.getMiningPassTierFloorFee(10), 25 * 1e6, "tier 10 floor fee");

        // 4. Set dynamic fees (e.g. at 80% of base)
        uint256[] memory dynamicFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            dynamicFees[i] = (BASE_FEES[i] * 8000) / 10000; // 80%
        }
        diamond.setMiningPassFees(dynamicFees);

        // Verify dynamic fees
        for (uint256 i; i < 11; i++) {
            assertEq(diamond.getMiningPassTierFee(i), dynamicFees[i], "dynamic fee mismatch");
        }

        // 5. Try setting a single tier fee
        diamond.setMiningPassTierFee(5, 6 * 1e6); // $6
        assertEq(diamond.getMiningPassTierFee(5), 6 * 1e6, "single tier fee");

        // 6. Verify floor enforcement: try setting below floor
        vm.expectRevert(abi.encodeWithSignature("DiamondManagerFacet__FeeBelowFloor()"));
        diamond.setMiningPassTierFee(10, 20 * 1e6); // $20 < $25 floor

        // 7. Verify floor elevation enforcement
        // Lower fees to 30%, then try to raise floor to 50%
        for (uint256 i; i < 11; i++) {
            dynamicFees[i] = (BASE_FEES[i] * 3000) / 10000; // 30%
        }
        diamond.setMiningPassFees(dynamicFees);

        vm.expectRevert(abi.encodeWithSignature("DiamondManagerFacet__FeeBelowFloor()"));
        diamond.setMiningPassFeeFloor(5000); // 50% > current 30% → should revert

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: E2E PURCHASE
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full e2e: upgrade → init pricing → purchase → verify USDC spent
    function test_ProdFork_PostUpgrade_PurchaseUsesUSDC() public {
        _upgradeDiamondManagerFacet();
        _initDynamicPricing();
        _ensureActiveSeason();

        uint256 fee = miningPass.getMiningPassFee(user, 1);
        require(fee > 0, "tier 1 fee is 0");
        console.log("Tier 1 purchase fee:", fee);

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

        assertEq(usdcSpent, fee, "USDC should be spent");
        assertEq(vpndSpent, 0, "VPND should NOT be spent");

        // Verify mining pass assigned
        (uint256 tier,) = miningPass.miningPassOf(user);
        assertEq(tier, 1, "user should have tier 1 pass");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              POST-UPGRADE: EVENT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify the new MiningPassTierFeeUpdated event is emitted
    function test_ProdFork_PostUpgrade_TierFeeEvent() public {
        _upgradeDiamondManagerFacet();
        _initDynamicPricing();

        vm.startPrank(owner);

        vm.expectEmit(true, false, false, true, DIAMOND);
        emit MiningPassTierFeeUpdated(5, 6 * 1e6);
        diamond.setMiningPassTierFee(5, 6 * 1e6);

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                         HELPERS
    // ═══════════════════════════════════════════════════════════════════

    event MiningPassTierFeeUpdated(uint256 indexed tier, uint256 fee);

    function _readAddress(uint256 slot) internal view returns (address) {
        return address(uint160(uint256(vm.load(DIAMOND, bytes32(slot)))));
    }

    /// @dev Deploy a new DiamondManagerFacet and replace its selectors via diamondCut
    function _upgradeDiamondManagerFacet() internal {
        DiamondManagerFacet newFacet = new DiamondManagerFacet();

        // Use a known selector to find the old facet address
        address oldFacet = loupe.facetAddress(DiamondManagerFacet.setDepositToken.selector);
        bytes4[] memory oldSelectors = loupe.facetFunctionSelectors(oldFacet);

        // Build a Replace cut for existing selectors
        IDiamondCut.FacetCut[] memory cuts;

        // Check if new facet has MORE selectors than old (new getters added)
        // We do Replace for existing, Add for new
        bytes4[] memory newSelectors = _getNewFacetSelectors(address(newFacet), oldSelectors);

        if (newSelectors.length > 0) {
            cuts = new IDiamondCut.FacetCut[](2);
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: address(newFacet),
                action: IDiamondCut.FacetCutAction.Replace,
                functionSelectors: oldSelectors
            });
            cuts[1] = IDiamondCut.FacetCut({
                facetAddress: address(newFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: newSelectors
            });
        } else {
            cuts = new IDiamondCut.FacetCut[](1);
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: address(newFacet),
                action: IDiamondCut.FacetCutAction.Replace,
                functionSelectors: oldSelectors
            });
        }

        vm.prank(owner);
        IDiamondCut(DIAMOND).diamondCut(cuts, address(0), "");
    }

    /// @dev Discover selectors on the new facet that don't exist on the old facet
    function _getNewFacetSelectors(address, bytes4[] memory oldSelectors) internal pure returns (bytes4[] memory) {
        // Get ALL selectors from the new facet by querying the loupe for what
        // the new facet exposes. Since it's not registered yet, we use a
        // brute-force approach: check known new selectors.
        bytes4[] memory candidates = new bytes4[](10);
        uint256 count;

        // New selectors added by the dynamic pricing PR
        bytes4[10] memory potentialNew = [
            DiamondManagerFacet.setMiningPassFees.selector,
            DiamondManagerFacet.setMiningPassTierFee.selector,
            DiamondManagerFacet.setBaseMiningPassFees.selector,
            DiamondManagerFacet.setMiningPassFeeFloor.selector,
            DiamondManagerFacet.getMiningPassTierFee.selector,
            DiamondManagerFacet.getBaseMiningPassTierFee.selector,
            DiamondManagerFacet.getMiningPassTierFloorFee.selector,
            DiamondManagerFacet.getMiningPassFeeFloorBps.selector,
            DiamondManagerFacet.getAllMiningPassFees.selector,
            DiamondManagerFacet.getMiningPassTierDepositLimit.selector
        ];

        for (uint256 i; i < 10; i++) {
            bool isOld;
            for (uint256 j; j < oldSelectors.length; j++) {
                if (potentialNew[i] == oldSelectors[j]) {
                    isOld = true;
                    break;
                }
            }
            if (!isOld) {
                candidates[count] = potentialNew[i];
                count++;
            }
        }

        // Also check getSeasonIsClaimed
        bytes4 seasonClaimedSel = DiamondManagerFacet.getSeasonIsClaimed.selector;
        {
            bool isOld;
            for (uint256 j; j < oldSelectors.length; j++) {
                if (seasonClaimedSel == oldSelectors[j]) {
                    isOld = true;
                    break;
                }
            }
            if (!isOld) {
                candidates[count] = seasonClaimedSel;
                count++;
            }
        }

        bytes4[] memory result = new bytes4[](count);
        for (uint256 i; i < count; i++) {
            result[i] = candidates[i];
        }
        return result;
    }

    /// @dev Initialise dynamic pricing config (simulates post-upgrade admin actions)
    function _initDynamicPricing() internal {
        vm.startPrank(owner);

        uint256[] memory baseFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            baseFees[i] = BASE_FEES[i];
        }
        diamond.setBaseMiningPassFees(baseFees);
        diamond.setMiningPassFeeFloor(2500);

        vm.stopPrank();
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
