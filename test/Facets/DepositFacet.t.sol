// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded } from "src/facets/DepositFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { ERC20Mock } from "test/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/mocks/StratosphereMock.sol";

contract DepositFacetTest is DiamondTest {
    // StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidMiningDiamond internal diamond;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    address depositFeeReceiver1 = makeAddr("depositFeeReceiver1");
    address depositFeeReceiver2 = makeAddr("depositFeeReceiver2");

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        depositFacet = DepositFacet(address(diamond));
        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        vm.stopPrank();
    }

    function test_RevertIf_DepositorDoesNotHaveEnoughBalance() public {
        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 10);
        vm.expectRevert(DepositFacet__NotEnoughTokenBalance.selector);
        depositFacet.deposit(100);
    }

    function test_DepositWithoutBeingStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));

        vm.stopPrank();

        address user = makeAddr("user");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);
        depositFacet.deposit(1000);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 1000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 30 * 1000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 1000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 30 * 1000);
    }

    function test_DepositBeingBasicStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));

        vm.stopPrank();

        address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");

        vm.startPrank(stratosphereMemberBasic);
        depositToken.increaseAllowance(address(depositFacet), 1_000_000);
        depositToken.mint(stratosphereMemberBasic, 1000);

        vm.warp(block.timestamp + 1 days);

        depositFacet.deposit(1000);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 1), 1000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberBasic, 1), 29 * 1000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 1000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 29 * 1000);
    }

    function test_DepositBeingGoldStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);

        vm.stopPrank();

        address stratosphereMemberGold = makeAddr("stratosphereMemberGold");

        vm.startPrank(stratosphereMemberGold);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(stratosphereMemberGold, 1000);

        vm.warp(block.timestamp + 5 days);

        depositFacet.deposit(1000);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGold, 1), 1000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberGold, 1), 25 * 1000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 1000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 25 * 1000);
    }

    function test_RevertsIfDepositAfterSeasonEnd() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);

        vm.stopPrank();

        address stratosphereMemberGold = makeAddr("stratosphereMemberGold");

        vm.startPrank(stratosphereMemberGold);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(stratosphereMemberGold, 1000);

        vm.warp(block.timestamp + 31 days);
        vm.expectRevert(DepositFacet__SeasonEnded.selector);
        depositFacet.deposit(1000);
    }

    function test_DepositMultipleDeposits() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);

        vm.stopPrank();

        address stratosphereMemberBasic = makeAddr("user");

        vm.startPrank(stratosphereMemberBasic);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(stratosphereMemberBasic, 1000);
        depositFacet.deposit(1000);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 1), 1000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberBasic, 1), 30 * 1000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 1000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 30 * 1000);

        vm.stopPrank();

        stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");

        vm.startPrank(stratosphereMemberBasic);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(stratosphereMemberBasic, 1000);

        vm.warp(block.timestamp + 1 days);

        depositFacet.deposit(1000);

        vm.stopPrank();

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 1), 1000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberBasic, 1), 29 * 1000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 2000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 29 * 1000 + 30 * 1000);
    }
}
