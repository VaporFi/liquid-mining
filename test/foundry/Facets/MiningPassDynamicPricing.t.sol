// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {DiamondTest, LiquidMiningDiamond} from "../utils/DiamondTest.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import "src/facets/MiningPassFacet.sol";

error DiamondManagerFacet__Not_Owner();
error DiamondManagerFacet__Invalid_Input();
error DiamondManagerFacet__FeeBelowFloor();
error DiamondManagerFacet__InvalidTier();

contract MiningPassDynamicPricingTest is DiamondTest {
    LiquidMiningDiamond internal diamond;
    DiamondManagerFacet internal diamondManagerFacet;
    MiningPassFacet internal miningPassFacet;

    address internal owner = makeAddr("diamondOwner");
    address internal user = makeAddr("user");

    // Original fees in USDC (6 decimals)
    uint256[] internal originalFees = [
        0, // Tier 0
        0.5 * 1e6, // Tier 1
        1 * 1e6, // Tier 2
        2 * 1e6, // Tier 3
        4 * 1e6, // Tier 4
        8 * 1e6, // Tier 5
        15 * 1e6, // Tier 6
        30 * 1e6, // Tier 7
        50 * 1e6, // Tier 8
        75 * 1e6, // Tier 9
        100 * 1e6 // Tier 10
    ];

    function setUp() public {
        vm.startPrank(owner);

        diamond = createDiamond();
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        miningPassFacet = MiningPassFacet(address(diamond));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                         GETTER TESTS
    // ═══════════════════════════════════════════════════════════════════

    function test_GetBaseMiningPassTierFee() public {
        for (uint256 i; i < 11; i++) {
            assertEq(diamondManagerFacet.getBaseMiningPassTierFee(i), originalFees[i]);
        }
    }

    function test_GetMiningPassTierFee() public {
        // Initially, current fees should equal base fees
        for (uint256 i; i < 11; i++) {
            assertEq(diamondManagerFacet.getMiningPassTierFee(i), originalFees[i]);
        }
    }

    function test_GetMiningPassFeeFloorBps() public {
        // Default floor is 25% = 2500 bps
        assertEq(diamondManagerFacet.getMiningPassFeeFloorBps(), 2500);
    }

    function test_GetMiningPassTierFloorFee() public {
        // Floor fee = baseFee * 25% = baseFee / 4
        assertEq(diamondManagerFacet.getMiningPassTierFloorFee(0), 0);
        assertEq(diamondManagerFacet.getMiningPassTierFloorFee(1), 0.125 * 1e6); // 0.5 * 0.25
        assertEq(diamondManagerFacet.getMiningPassTierFloorFee(5), 2 * 1e6); // 8 * 0.25
        assertEq(diamondManagerFacet.getMiningPassTierFloorFee(10), 25 * 1e6); // 100 * 0.25
    }

    function test_GetAllMiningPassFees() public {
        uint256[] memory fees = diamondManagerFacet.getAllMiningPassFees();
        assertEq(fees.length, 11);
        for (uint256 i; i < 11; i++) {
            assertEq(fees[i], originalFees[i]);
        }
    }

    function test_GetMiningPassTierDepositLimit() public {
        assertEq(diamondManagerFacet.getMiningPassTierDepositLimit(0), 5_000 * 1e18);
        assertEq(diamondManagerFacet.getMiningPassTierDepositLimit(1), 10_000 * 1e18);
        assertEq(diamondManagerFacet.getMiningPassTierDepositLimit(10), type(uint256).max);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                         SET FEES TESTS
    // ═══════════════════════════════════════════════════════════════════

    function test_SetMiningPassFees() public {
        vm.startPrank(owner);

        // Simulate dynamic pricing: fees at 50% of original (above 25% floor)
        uint256[] memory newFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            newFees[i] = originalFees[i] / 2; // 50% of original
        }

        diamondManagerFacet.setMiningPassFees(newFees);

        // Verify fees were updated
        for (uint256 i; i < 11; i++) {
            assertEq(diamondManagerFacet.getMiningPassTierFee(i), newFees[i]);
        }

        // Base fees should remain unchanged
        for (uint256 i; i < 11; i++) {
            assertEq(diamondManagerFacet.getBaseMiningPassTierFee(i), originalFees[i]);
        }

        vm.stopPrank();
    }

    function test_SetMiningPassFees_AtFloor() public {
        vm.startPrank(owner);

        // Set fees exactly at floor (25% of original)
        uint256[] memory floorFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            floorFees[i] = (originalFees[i] * 2500) / 10000; // 25% of original
        }

        diamondManagerFacet.setMiningPassFees(floorFees);

        for (uint256 i; i < 11; i++) {
            assertEq(diamondManagerFacet.getMiningPassTierFee(i), floorFees[i]);
        }

        vm.stopPrank();
    }

    function test_SetMiningPassFees_RevertIf_BelowFloor() public {
        vm.startPrank(owner);

        // Try to set fees below floor (24% of original)
        uint256[] memory lowFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            lowFees[i] = (originalFees[i] * 2400) / 10000; // 24% of original
        }

        vm.expectRevert(DiamondManagerFacet__FeeBelowFloor.selector);
        diamondManagerFacet.setMiningPassFees(lowFees);

        vm.stopPrank();
    }

    function test_SetMiningPassFees_RevertIf_InvalidLength() public {
        vm.startPrank(owner);

        uint256[] memory shortFees = new uint256[](5);

        vm.expectRevert(DiamondManagerFacet__Invalid_Input.selector);
        diamondManagerFacet.setMiningPassFees(shortFees);

        vm.stopPrank();
    }

    function test_SetMiningPassFees_RevertIf_NotOwner() public {
        vm.startPrank(user);

        uint256[] memory newFees = new uint256[](11);

        vm.expectRevert(DiamondManagerFacet__Not_Owner.selector);
        diamondManagerFacet.setMiningPassFees(newFees);

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      SET SINGLE TIER FEE TESTS
    // ═══════════════════════════════════════════════════════════════════

    function test_SetMiningPassTierFee() public {
        vm.startPrank(owner);

        // Update tier 5 to 50% of original
        uint256 newFee = originalFees[5] / 2; // $4 instead of $8
        diamondManagerFacet.setMiningPassTierFee(5, newFee);

        assertEq(diamondManagerFacet.getMiningPassTierFee(5), newFee);
        // Other tiers unchanged
        assertEq(diamondManagerFacet.getMiningPassTierFee(4), originalFees[4]);
        assertEq(diamondManagerFacet.getMiningPassTierFee(6), originalFees[6]);

        vm.stopPrank();
    }

    function test_SetMiningPassTierFee_RevertIf_BelowFloor() public {
        vm.startPrank(owner);

        // Try to set tier 5 below floor
        uint256 belowFloorFee = 1.9 * 1e6; // Below $2 floor (25% of $8)

        vm.expectRevert(DiamondManagerFacet__FeeBelowFloor.selector);
        diamondManagerFacet.setMiningPassTierFee(5, belowFloorFee);

        vm.stopPrank();
    }

    function test_SetMiningPassTierFee_RevertIf_InvalidTier() public {
        vm.startPrank(owner);

        vm.expectRevert(DiamondManagerFacet__InvalidTier.selector);
        diamondManagerFacet.setMiningPassTierFee(11, 1e6);

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      SET FLOOR TESTS
    // ═══════════════════════════════════════════════════════════════════

    function test_SetMiningPassFeeFloor() public {
        vm.startPrank(owner);

        // Change floor to 50%
        diamondManagerFacet.setMiningPassFeeFloor(5000);
        assertEq(diamondManagerFacet.getMiningPassFeeFloorBps(), 5000);

        // Verify floor fee calculation changed
        assertEq(diamondManagerFacet.getMiningPassTierFloorFee(10), 50 * 1e6); // 50% of $100

        vm.stopPrank();
    }

    function test_SetMiningPassFeeFloor_RevertIf_InvalidValue() public {
        vm.startPrank(owner);

        // Cannot exceed 100%
        vm.expectRevert(DiamondManagerFacet__Invalid_Input.selector);
        diamondManagerFacet.setMiningPassFeeFloor(10001);

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                   PURCHASE WITH DYNAMIC FEES TESTS
    // ═══════════════════════════════════════════════════════════════════

    function test_Purchase_WithDynamicFees() public {
        vm.startPrank(owner);

        // Set fees to 50% of original
        uint256[] memory newFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            newFees[i] = originalFees[i] / 2;
        }
        diamondManagerFacet.setMiningPassFees(newFees);

        vm.stopPrank();

        vm.startPrank(user);
        _approveAndMintFeeToken(100 * 1e6);

        // Purchase tier 1 - should cost $0.25 instead of $0.50
        miningPassFacet.purchase(1);

        (uint256 _passTier,) = miningPassFacet.miningPassOf(user);
        assertEq(_passTier, 1);
        assertEq(feeToken.balanceOf(address(diamond)), 0.25 * 1e6);

        vm.stopPrank();
    }

    function test_Purchase_WithDynamicFees_Upgrade() public {
        vm.startPrank(owner);

        // Set fees to 50% of original
        uint256[] memory newFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            newFees[i] = originalFees[i] / 2;
        }
        diamondManagerFacet.setMiningPassFees(newFees);

        vm.stopPrank();

        vm.startPrank(user);
        _approveAndMintFeeToken(100 * 1e6);

        // Purchase tier 1 then upgrade to tier 2
        miningPassFacet.purchase(1);
        miningPassFacet.purchase(2);

        (uint256 _passTier,) = miningPassFacet.miningPassOf(user);
        assertEq(_passTier, 2);

        // Total paid: $0.25 (tier 1) + $0.25 (upgrade to tier 2) = $0.50
        assertEq(feeToken.balanceOf(address(diamond)), 0.5 * 1e6);

        vm.stopPrank();
    }

    function test_Purchase_AtFloorPrice() public {
        vm.startPrank(owner);

        // Set fees at floor (25% of original)
        uint256[] memory floorFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            floorFees[i] = (originalFees[i] * 2500) / 10000;
        }
        diamondManagerFacet.setMiningPassFees(floorFees);

        vm.stopPrank();

        vm.startPrank(user);
        _approveAndMintFeeToken(100 * 1e6);

        // Purchase tier 10 at floor price - should cost $25 instead of $100
        miningPassFacet.purchase(10);

        (uint256 _passTier,) = miningPassFacet.miningPassOf(user);
        assertEq(_passTier, 10);
        assertEq(feeToken.balanceOf(address(diamond)), 25 * 1e6);

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      DYNAMIC PRICING SIMULATION
    // ═══════════════════════════════════════════════════════════════════

    function test_DynamicPricing_SimulateVAPEPriceChange() public {
        vm.startPrank(owner);

        // Simulate VAPE price drop: $0.606 -> $0.16 (26.4% of original)
        // Formula: newFee = originalFee * (currentVAPEPrice / referenceVAPEPrice)
        // At floor (25%), fees would be capped

        uint256 referenceVAPEPrice = 606; // $0.606 scaled by 1000
        uint256 currentVAPEPrice = 160; // $0.16 scaled by 1000

        uint256[] memory dynamicFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            uint256 calculatedFee = (originalFees[i] * currentVAPEPrice) / referenceVAPEPrice;
            uint256 floorFee = (originalFees[i] * 2500) / 10000;
            // Apply floor
            dynamicFees[i] = calculatedFee > floorFee ? calculatedFee : floorFee;
        }

        diamondManagerFacet.setMiningPassFees(dynamicFees);

        // Verify tier 10: (100 * 1e6 * 160) / 606 = 26402640 (integer division)
        // This is above floor (25 * 1e6), so dynamic price applies
        uint256 expectedTier10Fee = (100 * 1e6 * currentVAPEPrice) / referenceVAPEPrice;
        assertEq(diamondManagerFacet.getMiningPassTierFee(10), expectedTier10Fee);
        assertTrue(expectedTier10Fee > 25 * 1e6, "Fee should be above floor");

        vm.stopPrank();
    }

    function test_DynamicPricing_FloorProtection() public {
        vm.startPrank(owner);

        // Simulate extreme VAPE price drop: $0.606 -> $0.10 (16.5% of original)
        // This is below floor (25%), so fees should be capped at floor

        uint256 referenceVAPEPrice = 606;
        uint256 currentVAPEPrice = 100; // $0.10

        uint256[] memory dynamicFees = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            uint256 calculatedFee = (originalFees[i] * currentVAPEPrice) / referenceVAPEPrice;
            uint256 floorFee = (originalFees[i] * 2500) / 10000;
            // Apply floor
            dynamicFees[i] = calculatedFee > floorFee ? calculatedFee : floorFee;
        }

        diamondManagerFacet.setMiningPassFees(dynamicFees);

        // All fees should be at floor (25% of original)
        assertEq(diamondManagerFacet.getMiningPassTierFee(10), 25 * 1e6); // Floor: $25

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      SET BASE FEES TESTS
    // ═══════════════════════════════════════════════════════════════════

    function test_SetBaseMiningPassFees() public {
        vm.startPrank(owner);

        uint256[] memory newBaseFees = new uint256[](11);
        newBaseFees[0] = 0;
        newBaseFees[1] = 1 * 1e6;
        newBaseFees[2] = 2 * 1e6;
        newBaseFees[3] = 4 * 1e6;
        newBaseFees[4] = 8 * 1e6;
        newBaseFees[5] = 16 * 1e6;
        newBaseFees[6] = 30 * 1e6;
        newBaseFees[7] = 60 * 1e6;
        newBaseFees[8] = 100 * 1e6;
        newBaseFees[9] = 150 * 1e6;
        newBaseFees[10] = 200 * 1e6;

        diamondManagerFacet.setBaseMiningPassFees(newBaseFees);

        // Verify base fees updated
        for (uint256 i; i < 11; i++) {
            assertEq(diamondManagerFacet.getBaseMiningPassTierFee(i), newBaseFees[i]);
        }

        // Floor fee should reflect new base
        assertEq(diamondManagerFacet.getMiningPassTierFloorFee(10), 50 * 1e6); // 25% of $200

        vm.stopPrank();
    }

    function test_SetBaseMiningPassFees_RevertIf_InvalidLength() public {
        vm.startPrank(owner);

        uint256[] memory shortFees = new uint256[](5);
        vm.expectRevert(DiamondManagerFacet__Invalid_Input.selector);
        diamondManagerFacet.setBaseMiningPassFees(shortFees);

        vm.stopPrank();
    }

    function test_SetBaseMiningPassFees_RevertIf_NotOwner() public {
        vm.startPrank(user);

        uint256[] memory newFees = new uint256[](11);
        vm.expectRevert(DiamondManagerFacet__Not_Owner.selector);
        diamondManagerFacet.setBaseMiningPassFees(newFees);

        vm.stopPrank();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                          HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _approveAndMintFeeToken(uint256 _amount) internal {
        feeToken.mint(user, _amount);
        feeToken.increaseAllowance(address(miningPassFacet), _amount);
    }
}
