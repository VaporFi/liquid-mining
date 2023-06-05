// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { UnlockFacet, UnlockFacet__InvalidAmount, UnlockFacet__AlreadyUnlocked, UnlockFacet__InvalidFeeReceivers, UnlockFacet__InvalidUnlock } from "src/facets/UnlockFacet.sol";
import { DepositFacet } from "src/facets/DepositFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { ERC20Mock } from "test/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/mocks/StratosphereMock.sol";

contract UnlockFacetTest is DiamondTest {
    LiquidMiningDiamond internal diamond;
    UnlockFacet internal unlockFacet;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    address depositFeeReceiver1 = makeAddr("depositFeeReceiver1");
    address depositFeeReceiver2 = makeAddr("depositFeeReceiver2");
    address unlockFeeReceiver1 = makeAddr("unlockFeeReceiver1");
    address unlockFeeReceiver2 = makeAddr("unlockFeeReceiver2");

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        unlockFacet = UnlockFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));

        depositToken.mint(makeAddr("user"), 100);

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setUnlockFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();
    }

    function test_RevertIf_UnlockerDoesNotHaveEnoughBalanceDeposited() public {
        vm.startPrank(makeAddr("user"));
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(50);
        vm.expectRevert(UnlockFacet__InvalidAmount.selector);
        unlockFacet.unlock(100);
    }

    function test_RevertIf_UnlockedTwice() public {
        vm.startPrank(makeAddr("user"));
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(100);
        unlockFacet.unlock(50);
        vm.expectRevert(UnlockFacet__AlreadyUnlocked.selector);
        unlockFacet.unlock(10);
    }

    function test_RevertIf_UnlockedWithInvalidAmount() public {
        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 100);
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(100);
        vm.expectRevert(UnlockFacet__InvalidAmount.selector);
        unlockFacet.unlock(101);
    }

    function test_RevertIf_UnlockedTimestampIsMoreThanSeasonEndTimestamp() public {
        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 100);
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(100);
        vm.warp(block.timestamp + 29 days);
        vm.expectRevert(UnlockFacet__InvalidUnlock.selector);
        unlockFacet.unlock(50);
    }

    function test_UnlockWithoutBeingStratosphereMember() public {
        address user = makeAddr("user");

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(user, 1000);
        depositFacet.deposit(1000);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 1000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 30 * 1000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 1000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 30 * 1000);

        unlockFacet.unlock(1000);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 0);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 0);
        assertEq(diamondManagerFacet.getUnlockAmountOfUser(user, 1), 1000 - 100);
        assertEq(diamondManagerFacet.getUnlockTimestampOfUser(user, 1), block.timestamp + 3 days);
        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)),
            100
        );
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)), 75);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)), 25);
    }

    function test_UnlockBeingBasicStratosphereMember() public {
        address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");

        vm.startPrank(stratosphereMemberBasic);

        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(stratosphereMemberBasic, 1000);

        vm.warp(block.timestamp + 1 days);

        depositFacet.deposit(1000);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 1), 1000);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberBasic, 1), 29 * 1000);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 1000);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 29 * 1000);

        unlockFacet.unlock(1000);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 1), 0);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberBasic, 1), 0);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 0);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 0);
        assertEq(diamondManagerFacet.getUnlockAmountOfUser(stratosphereMemberBasic, 1), 905); // deposit amount - (unlock fee * STRAT fee discount)
        assertEq(
            diamondManagerFacet.getUnlockTimestampOfUser(stratosphereMemberBasic, 1),
            block.timestamp + 3 days - 12960
        );
        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)),
            94
        );
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)), 71);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)), 23);
    }

    function test_UnlockBeingGoldStratosphereMember() public {
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

        unlockFacet.unlock(1000);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGold, 1), 0);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(stratosphereMemberGold, 1), 0);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 0);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 0);
        assertEq(diamondManagerFacet.getUnlockAmountOfUser(stratosphereMemberGold, 1), 1000 - 93);
        assertEq(
            diamondManagerFacet.getUnlockTimestampOfUser(stratosphereMemberGold, 1),
            block.timestamp + 3 days - 16848
        );
        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)),
            92
        );
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)), 69);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)), 23);
    }
}
