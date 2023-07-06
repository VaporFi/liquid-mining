// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "lib/forge-std/src/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidMiningPass } from "src/facets/DepositFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { ERC20Mock } from "test/foundry/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/foundry/mocks/StratosphereMock.sol";
import { MiningPassFacet } from "src/facets/MiningPassFacet.sol";

contract DepositFacetTest is DiamondTest {
    // StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidMiningDiamond internal diamond;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    MiningPassFacet internal miningPassFacet;
    address depositFeeReceiver1 = makeAddr("depositFeeReceiver1");
    address depositFeeReceiver2 = makeAddr("depositFeeReceiver2");

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        depositFacet = DepositFacet(address(diamond));
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        miningPassFacet = MiningPassFacet(address(diamond));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));

        vm.stopPrank();
    }

    function test_RevertIf_DepositorDoesNotHaveEnoughBalance() public {
        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 10);
        vm.expectRevert(DepositFacet__NotEnoughTokenBalance.selector);
        depositFacet.deposit(100);
    }

    function test_DepositWithoutBeingStratosphereMember() public {
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
        address stratosphereMemberGold = makeAddr("stratosphereMemberGold");

        vm.startPrank(stratosphereMemberGold);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(stratosphereMemberGold, 1000);

        vm.warp(block.timestamp + 31 days);
        vm.expectRevert(DepositFacet__SeasonEnded.selector);
        depositFacet.deposit(1000);
    }

    function test_DepositMultipleDeposits() public {
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

    function test_SecondDepositAfterUpgradingMiningPass() public {
        address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");

        vm.startPrank(stratosphereMemberBasic);
        depositToken.increaseAllowance(address(depositFacet), 5000 * 1e18);
        depositToken.mint(stratosphereMemberBasic, 5000 * 1e18);

        depositFacet.deposit(5000 * 1e18);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 1), 5000000000000000000000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberBasic, 1), 150000000000000000000000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 5000000000000000000000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 150000000000000000000000);

        depositToken.mint(stratosphereMemberBasic, 20_000 * 1e18);
        depositToken.increaseAllowance(address(depositFacet), 20_000 * 1e18);
        feeToken.mint(stratosphereMemberBasic, 2 * 1e6);
        feeToken.increaseAllowance(address(depositFacet), 2 * 1e6);

        vm.warp(block.timestamp + 5 days);

        miningPassFacet.purchase(2);
        depositFacet.deposit(20_000 * 1e18);

        vm.stopPrank();

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 1), 25000000000000000000000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberBasic, 1), 650000000000000000000000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 25000000000000000000000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 650000000000000000000000);
    }

    function test_RevertIf_UserTriesToDepositMoreThanFreeTierMiningPass() public {
        address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");

        vm.startPrank(stratosphereMemberBasic);

        depositToken.mint(stratosphereMemberBasic, 25_000 * 1e18);
        depositToken.increaseAllowance(address(depositFacet), 25_000 * 1e18);
        feeToken.mint(stratosphereMemberBasic, 2 * 1e6);
        feeToken.increaseAllowance(address(depositFacet), 2 * 1e6);

        depositFacet.deposit(5000 * 1e18);

        vm.warp(block.timestamp + 5 days);

        vm.expectRevert(DepositFacet__InvalidMiningPass.selector);
        depositFacet.deposit(20_000 * 1e18);

        vm.stopPrank();
    }
}
