// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { MiningPassFacet } from "src/facets/MiningPassFacet.sol";

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

        feeToken.increaseAllowance(address(miningPassFacet), 1000000);
        feeToken.mint(makeAddr("user"), 1000);

        miningPassFacet.purchase(1);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 1);

        vm.stopPrank();
    }

    function test_Upgrade() public {
        vm.startPrank(makeAddr("user"));

        feeToken.increaseAllowance(address(miningPassFacet), 1000000);
        feeToken.mint(makeAddr("user"), 1000);

        miningPassFacet.purchase(1);

        (uint256 _passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 1);

        miningPassFacet.upgrade(2);

        (_passTier, ) = miningPassFacet.miningPassOf(makeAddr("user"));
        assertEq(_passTier, 2);

        vm.stopPrank();
    }
}
