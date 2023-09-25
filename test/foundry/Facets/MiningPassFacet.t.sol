// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import "src/facets/MiningPassFacet.sol";

contract MiningPassFacetTest is DiamondTest {
    LiquidMiningDiamond internal diamond;
    DiamondManagerFacet internal diamondManagerFacet;
    MiningPassFacet internal miningPassFacet;

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        miningPassFacet = MiningPassFacet(address(diamond));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);

        vm.stopPrank();
    }

    function test_Purchase() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);

        miningPassFacet.purchase(1);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 1);
        assertEq(feeToken.balanceOf(address(diamond)), 0.5 * 1e6);

        vm.stopPrank();
    }

    function test_Purchase_After_14_days() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);
        skip(14 days + 100);

        miningPassFacet.purchase(1);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 1);
        assertEq(feeToken.balanceOf(address(diamond)), 0.25 * 1e6);
        vm.stopPrank();
    }

    function test_Purchase_After_7_days() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);
        skip(7 days + 100);

        miningPassFacet.purchase(1);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 1);
        assertEq(feeToken.balanceOf(address(diamond)), 0.50 * 1e6 - (0.50 * 1e6) / 4);

        vm.stopPrank();
    }

    function test_Purchase_After_14_days_As_Upgrade() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);
        miningPassFacet.purchase(1);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 1);
        assertEq(feeToken.balanceOf(address(diamond)), 0.50 * 1e6);

        skip(14 days + 100);
        miningPassFacet.purchase(2);

        (uint256 _passTierUpgraded, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTierUpgraded, 2);
        assertEq(feeToken.balanceOf(address(diamond)), (0.50 + (0.50 - 0.50 / 2)) * 1e6);

        vm.stopPrank();
    }

     function test_Purchase_After_7_days_As_Upgrade() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);
        miningPassFacet.purchase(1);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 1);
        assertEq(feeToken.balanceOf(address(diamond)), 0.50 * 1e6);

        skip(7 days + 100);
        miningPassFacet.purchase(2);

        (uint256 _passTierUpgraded, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTierUpgraded, 2);
        assertEq(feeToken.balanceOf(address(diamond)), (0.50 + (0.50 - 0.50 / 4)) * 1e6);

        vm.stopPrank();
    }

    function test_PurchaseHigherTier() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);

        miningPassFacet.purchase(1);
        miningPassFacet.purchase(2);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 2);
        assertEq(feeToken.balanceOf(address(diamond)), 1 * 1e6);

        vm.stopPrank();
    }

    function test_Purchase_RevertIf_TiersIsZero() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);

        vm.expectRevert(MiningPassFacet__InvalidTier.selector);
        miningPassFacet.purchase(0);

        vm.stopPrank();
    }

    function test_Purchase_RevertIf_TiersIsGreaterThanMaxTier() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);

        vm.expectRevert(MiningPassFacet__InvalidTier.selector);
        miningPassFacet.purchase(11);

        vm.stopPrank();
    }

    function test_Purchase_RevertIf_PurchaseSameTwice() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);

        miningPassFacet.purchase(1);

        vm.expectRevert(MiningPassFacet__InvalidTier.selector);
        miningPassFacet.purchase(1);

        vm.stopPrank();
    }

    function test_Purchase_RevertIf_NotEnoughBalance() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(50 * 1e6);

        vm.expectRevert(MiningPassFacet__InsufficientBalance.selector);
        miningPassFacet.purchase(9);

        vm.stopPrank();
    }

    function test_Purchase_RevertIf_NoActiveSeason() public {
        vm.startPrank(makeAddr("user"));

        vm.warp(block.timestamp + 31 days);

        _approveAndMintFeeToken(100 * 1e6);

        vm.expectRevert(MiningPassFacet__SeasonEnded.selector);
        miningPassFacet.purchase(1);

        vm.stopPrank();
    }

    function test_Purchase_RevertIf_PurchaseALowerTier() public {
        vm.startPrank(makeAddr("user"));

        _approveAndMintFeeToken(100 * 1e6);

        miningPassFacet.purchase(2);

        vm.expectRevert(MiningPassFacet__InvalidTier.selector);
        miningPassFacet.purchase(1);

        vm.stopPrank();
    }

    function _approveAndMintFeeToken(uint256 _amount) internal {
        feeToken.mint(makeAddr("user"), _amount);
        feeToken.increaseAllowance(address(miningPassFacet), _amount);
    }
}
