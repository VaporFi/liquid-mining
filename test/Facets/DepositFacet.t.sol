// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {StratosphereMock} from "test/mocks/StratosphereMock.sol";

contract DepositFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    ERC20Mock internal depositToken;
    address depositFeeReceiver1 = makeAddr("depositFeeReceiver1");
    address depositFeeReceiver2 = makeAddr("depositFeeReceiver2");
    StratosphereMock stratosphereMock;

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        depositFacet = new DepositFacet();
        diamondManagerFacet = new DiamondManagerFacet();
        bytes4[] memory depositFunctionSelectors = new bytes4[](1);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;
        addFacet(diamond, address(depositFacet), depositFunctionSelectors);
        bytes4[] memory managerFunctionSelectors = new bytes4[](13);
        managerFunctionSelectors[0] = diamondManagerFacet.setDepositToken.selector;
        managerFunctionSelectors[1] = diamondManagerFacet.setCurrentSeasonId.selector;
        managerFunctionSelectors[2] = diamondManagerFacet.setDepositDiscountForStratosphereMember.selector;
        managerFunctionSelectors[3] = diamondManagerFacet.setDepositFee.selector;
        managerFunctionSelectors[4] = diamondManagerFacet.setStratosphereAddress.selector;
        managerFunctionSelectors[6] = diamondManagerFacet.setSeasonEndTimestamp.selector;
        managerFunctionSelectors[7] = diamondManagerFacet.setDepositFeeReceivers.selector;
        managerFunctionSelectors[8] = diamondManagerFacet.getPendingWithdrawals.selector;
        managerFunctionSelectors[9] = diamondManagerFacet.getDepositAmountOfUser.selector;
        managerFunctionSelectors[10] = diamondManagerFacet.getDepositPointsOfUser.selector;
        managerFunctionSelectors[11] = diamondManagerFacet.getTotalDepositAmountOfSeason.selector;
        managerFunctionSelectors[12] = diamondManagerFacet.getTotalPointsOfSeason.selector;

        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        depositToken = new ERC20Mock("Vapor nodes", "VPND");

        diamondManagerFacet.setDepositToken(address(depositToken));

        depositFacet = DepositFacet(address(diamond));

        stratosphereMock = new StratosphereMock();

        vm.stopPrank();
    }

    function test_RevertIfDepositorDoesNotHaveEnoughBalance() public {
        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 10);
        vm.expectRevert(DepositFacet__NotEnoughTokenBalance.selector);
        depositFacet.deposit(100);
    }

    function test_DepositWithoutBeingStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();

        address user = makeAddr("user");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);
        depositFacet.deposit(1000);

        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2),
            49
        );

        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1), 37);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2), 12);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 950);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 30 * 950);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 950);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 30 * 950);
    }

    function test_DepositBeingBasicStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();

        address user = makeAddr("stratosphere_member_basic");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);

        vm.warp(block.timestamp + 1 days);

        depositFacet.deposit(1000);

        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2),
            46
        );

        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1), 35);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2), 11);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 953);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 29 * 953);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 953);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 29 * 953);
    }

    function test_DepositBeingGoldStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();

        address user = makeAddr("stratosphere_member_gold");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);

        vm.warp(block.timestamp + 5 days);

        depositFacet.deposit(1000);

        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2),
            45
        );

        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1), 34);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2), 11);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 954);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 25 * 954);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 954);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 25 * 954);
    }

    function test_RevertsIfDepositAfterSeasonEnd() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();

        address user = makeAddr("stratosphere_member_gold");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);

        vm.warp(block.timestamp + 31 days);
        vm.expectRevert(DepositFacet__SeasonEnded.selector);
        depositFacet.deposit(1000);
    }

    function test_DepositMultipleDeposits() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();

        address user = makeAddr("user");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);
        depositFacet.deposit(1000);

        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2),
            49
        );

        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1), 37);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2), 12);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 950);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 30 * 950);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 950);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 30 * 950);

        vm.stopPrank();

        user = makeAddr("stratosphere_member_basic");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);

        vm.warp(block.timestamp + 1 days);

        depositFacet.deposit(1000);

        vm.stopPrank();

        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2),
            46 + 49
        );

        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1), 35 + 37);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2), 11 + 12);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 953);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 29 * 953);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 953 + 950);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 29 * 953 + 30 * 950);
    }
}
