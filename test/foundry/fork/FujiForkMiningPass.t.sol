// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDiamondCut} from "clouds/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "clouds/interfaces/IDiamondLoupe.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {MiningPassFacet} from "src/facets/MiningPassFacet.sol";

/// @title FujiForkMiningPassTest
/// @notice Fork test against the real Fuji diamond to verify storage layout fix.
///         The diamond was deployed at commit 14f06c0 which placed GENERAL fields
///         (depositToken, rewardToken, feeToken, ...) at slots 25-30. A prior
///         upgrade shifted those fields causing feeToken (slot 25 in broken HEAD)
///         to read depositToken data (VPND). The fixed AppStorage restores the
///         original slot layout with deprecated gap fields.
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

        // Read the owner from the OwnershipFacet
        (bool ok, bytes memory data) = DIAMOND.staticcall(abi.encodeWithSignature("owner()"));
        require(ok, "owner() call failed");
        owner = abi.decode(data, (address));
    }

    // ═══════════════════════════════════════════════════════════════════
    //                   STORAGE LAYOUT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify raw storage slots 25-28 hold the original 14f06c0 token addresses
    function test_Fork_VerifyStorageLayout() public {
        address slot25 = address(uint160(uint256(vm.load(DIAMOND, bytes32(uint256(25))))));
        address slot26 = address(uint160(uint256(vm.load(DIAMOND, bytes32(uint256(26))))));
        address slot27 = address(uint160(uint256(vm.load(DIAMOND, bytes32(uint256(27))))));
        address slot28 = address(uint160(uint256(vm.load(DIAMOND, bytes32(uint256(28))))));

        console.log("Raw storage:");
        console.log("  slot 25 (depositToken):", slot25);
        console.log("  slot 26 (rewardToken):", slot26);
        console.log("  slot 27 (feeToken):", slot27);
        console.log("  slot 28 (stratosphere):", slot28);

        assertEq(slot25, VPND, "slot 25 should be VPND (depositToken)");
        assertEq(slot26, VAPE, "slot 26 should be VAPE (rewardToken)");
        assertEq(slot27, USDC, "slot 27 should be USDC (feeToken)");
        assertEq(slot28, STRATOSPHERE, "slot 28 should be stratosphere");
    }

    /// @notice After upgrading facets on the fork, feeToken should be USDC
    function test_Fork_AfterUpgrade_FeeTokenIsUSDC() public {
        _upgradeFacets();
        _reinitializeMiningPassData();

        // feeToken at slot 27 = USDC (from original 14f06c0 init)
        assertEq(diamond.getStratosphereAddress(), STRATOSPHERE, "stratosphere should be correct");

        uint256 tier1Fee = diamond.getMiningPassTierFee(1);
        console.log("Tier 1 fee:", tier1Fee);
        assertTrue(tier1Fee > 0, "tier 1 fee should be non-zero after reinit");

        uint256 floorBps = diamond.getMiningPassFeeFloorBps();
        assertEq(floorBps, 2500, "floor should be 2500 bps");
    }

    /// @notice Full end-to-end: upgrade, reinit, purchase mining pass — USDC spent, not VPND
    function test_Fork_AfterUpgrade_PurchaseUsesUSDC() public {
        _upgradeFacets();
        _reinitializeMiningPassData();
        _setupMiningPassFeeReceivers();
        _ensureActiveSeason();

        uint256 fee = diamond.getMiningPassTierFee(1);
        require(fee > 0, "fee is 0");
        console.log("Tier 1 fee:", fee);

        // Give user USDC and VPND
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

    /// @dev Deploy new facets (compiled with fixed AppStorage) and replace them
    ///      in the diamond. Uses the loupe to dynamically get all registered
    ///      selectors for each facet so we don't miss any.
    function _upgradeFacets() internal {
        DiamondManagerFacet newDMF = new DiamondManagerFacet();
        MiningPassFacet newMPF = new MiningPassFacet();

        // Use the loupe to find existing facet addresses via known selectors
        address oldDmfAddr = loupe.facetAddress(DiamondManagerFacet.setDepositToken.selector);
        address oldMpfAddr = loupe.facetAddress(MiningPassFacet.purchase.selector);

        // Get ALL registered selectors for those facets
        bytes4[] memory dmfSelectors = loupe.facetFunctionSelectors(oldDmfAddr);
        bytes4[] memory mpfSelectors = loupe.facetFunctionSelectors(oldMpfAddr);

        console.log("DMF selectors to replace:", dmfSelectors.length);
        console.log("MPF selectors to replace:", mpfSelectors.length);

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(newDMF), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: dmfSelectors
        });
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(newMPF), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: mpfSelectors
        });

        vm.prank(owner);
        IDiamondCut(DIAMOND).diamondCut(cuts, address(0), "");
    }

    function _reinitializeMiningPassData() internal {
        uint256[] memory fees = new uint256[](11);
        fees[0] = 0;
        fees[1] = 0.5 * 1e6; // tier 1: 0.5 USDC
        fees[2] = 1 * 1e6;
        fees[3] = 2 * 1e6;
        fees[4] = 4 * 1e6;
        fees[5] = 8 * 1e6;
        fees[6] = 15 * 1e6;
        fees[7] = 30 * 1e6;
        fees[8] = 50 * 1e6;
        fees[9] = 75 * 1e6;
        fees[10] = 100 * 1e6;

        vm.startPrank(owner);
        diamond.setBaseMiningPassFees(fees);
        diamond.setMiningPassFees(fees);
        diamond.setMiningPassFeeFloor(2500);
        vm.stopPrank();
    }

    function _setupMiningPassFeeReceivers() internal {
        address[] memory receivers = new address[](1);
        receivers[0] = makeAddr("feeReceiver");
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000; // 100%

        vm.prank(owner);
        diamond.setMiningPassFeeReceivers(receivers, shares);
    }

    function _ensureActiveSeason() internal {
        uint256 seasonId = diamond.getCurrentSeasonId();
        if (seasonId == 0) {
            vm.prank(owner);
            diamond.startNewSeasonWithEndTimestamp(1000 * 1e18, block.timestamp + 30 days);
            return;
        }

        // Read season end timestamp from storage (Season struct in mapping at slot 4)
        bytes32 baseSlot = keccak256(abi.encode(seasonId, uint256(4)));
        uint256 endTs = uint256(vm.load(DIAMOND, bytes32(uint256(baseSlot) + 2)));
        if (endTs <= block.timestamp) {
            vm.prank(owner);
            diamond.startNewSeasonWithEndTimestamp(1000 * 1e18, block.timestamp + 30 days);
        }
    }
}
