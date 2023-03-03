// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {UnlockFacet, UnlockFacet__InvalidAmount, UnlockFacet__AlreadyUnlocked, UnlockFacet__InvalidFeeReceivers, UnlockFacet__InvalidUnlock} from "src/facets/UnlockFacet.sol";
import {DepositFacet} from "src/facets/DepositFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "src/mocks/ERC20Mock.sol";
import {RewardsControllerMock} from "src/mocks/RewardsControllerMock.sol";
import {StratosphereMock} from "src/mocks/StratosphereMock.sol";

contract UnlockFacetTest is Test, DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    UnlockFacet internal unlockFacet;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    ERC20Mock internal depositToken;
    address depositFeeReceiver1 = makeAddr("depositFeeReceiver1");
    address depositFeeReceiver2 = makeAddr("depositFeeReceiver2");
    address unlockFeeReceiver1 = makeAddr("unlockFeeReceiver1");
    address unlockFeeReceiver2 = makeAddr("unlockFeeReceiver2");
    StratosphereMock stratosphereMock;

    RewardsControllerMock rewardsControllerMock;

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        unlockFacet = new UnlockFacet();
        diamondManagerFacet = new DiamondManagerFacet();
        bytes4[] memory unlockFunctionSelectors = new bytes4[](1);
        unlockFunctionSelectors[0] = unlockFacet.unlock.selector;
        addFacet(diamond, address(unlockFacet), unlockFunctionSelectors);

        depositFacet = new DepositFacet();
        bytes4[] memory depositFunctionSelectors = new bytes4[](1);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;
        addFacet(diamond, address(depositFacet), depositFunctionSelectors);

        bytes4[] memory managerFunctionSelectors = new bytes4[](18);
        managerFunctionSelectors[0] = diamondManagerFacet.setDepositToken.selector;
        managerFunctionSelectors[1] = diamondManagerFacet.setCurrentSeasonId.selector;
        managerFunctionSelectors[2] = diamondManagerFacet.setDepositDiscountForStratosphereMember.selector;
        managerFunctionSelectors[3] = diamondManagerFacet.setDepositFee.selector;
        managerFunctionSelectors[4] = diamondManagerFacet.setStratosphereAddress.selector;
        managerFunctionSelectors[5] = diamondManagerFacet.setRewardsControllerAddress.selector;
        managerFunctionSelectors[6] = diamondManagerFacet.setSeasonEndTimestamp.selector;
        managerFunctionSelectors[7] = diamondManagerFacet.setDepositFeeReceivers.selector;
        managerFunctionSelectors[8] = diamondManagerFacet.getPendingWithdrawals.selector;
        managerFunctionSelectors[9] = diamondManagerFacet.getDepositAmountOfUser.selector;
        managerFunctionSelectors[10] = diamondManagerFacet.getDepositPointsOfUser.selector;
        managerFunctionSelectors[11] = diamondManagerFacet.getTotalDepositAmountOfSeason.selector;
        managerFunctionSelectors[12] = diamondManagerFacet.getTotalPointsOfSeason.selector;
        managerFunctionSelectors[13] = diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember.selector;
        managerFunctionSelectors[14] = diamondManagerFacet.setUnlockFee.selector;
        managerFunctionSelectors[15] = diamondManagerFacet.setUnlockFeeReceivers.selector;
        managerFunctionSelectors[16] = diamondManagerFacet.getUnlockAmountOfUser.selector;
        managerFunctionSelectors[17] = diamondManagerFacet.getUnlockTimestampOfUser.selector;

        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        depositToken = new ERC20Mock("Vapor nodes", "VPND");

        diamondManagerFacet.setDepositToken(address(depositToken));

        unlockFacet = UnlockFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));

        stratosphereMock = new StratosphereMock();
        rewardsControllerMock = new RewardsControllerMock();

        vm.stopPrank();
    }

    function test_RevertIfUnlockerDoesNotHaveEnoughBalanceDeposited() public {
        vm.startPrank(makeAddr("diamondOwner"));
        depositToken.mint(makeAddr("user"), 100);

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));

        vm.stopPrank();

        vm.startPrank(makeAddr("user"));
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(50);
        vm.expectRevert(UnlockFacet__InvalidAmount.selector);
        unlockFacet.unlock(100);
    }

    function test_RevertIfUnlockedTwice() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));

        vm.stopPrank();

        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 100);
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(100);
        unlockFacet.unlock(50);
        vm.expectRevert(UnlockFacet__AlreadyUnlocked.selector);
        unlockFacet.unlock(10);
    }

    function test_RevertIfUnlockedWithInvalidAmount() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));

        vm.stopPrank();

        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 100);
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(100);
        vm.expectRevert(UnlockFacet__InvalidAmount.selector);
        unlockFacet.unlock(100);
    }

    function test_RevertIfUnlockedTimestampIsMoreThanSeasonEndTimestamp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));

        vm.stopPrank();

        vm.startPrank(makeAddr("user"));
        depositToken.mint(makeAddr("user"), 100);
        depositToken.increaseAllowance(address(depositFacet), 1000000);

        depositFacet.deposit(100);
        vm.warp(block.timestamp + 29 days);
        vm.expectRevert(UnlockFacet__InvalidUnlock.selector);
        unlockFacet.unlock(50);
    }

    function test_UnlockWithoutBeingStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));
        diamondManagerFacet.setUnlockFee(1000);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(3, 650);
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        address[] memory unlockFeeReceivers = new address[](2);
        uint256[] memory unlockFeeProportions = new uint256[](2);
        unlockFeeReceivers[0] = unlockFeeReceiver1;
        unlockFeeReceivers[1] = unlockFeeReceiver2;
        unlockFeeProportions[0] = 7500;
        unlockFeeProportions[1] = 2500;
        diamondManagerFacet.setUnlockFeeReceivers(unlockFeeReceivers, unlockFeeProportions);

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

        vm.expectRevert(UnlockFacet__InvalidAmount.selector);
        unlockFacet.unlock(951);

        unlockFacet.unlock(950);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 0);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 0);
        assertEq(diamondManagerFacet.getUnlockAmountOfUser(user, 1), 950 - 95);
        assertEq(diamondManagerFacet.getUnlockTimestampOfUser(user, 1), block.timestamp + 3 days);
        assertEq(
            diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver2),
            94
        );
        assertEq(diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver1), 71);
        assertEq(diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver2), 23);
    }

    function test_UnlockBeingBasicStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));
        diamondManagerFacet.setUnlockFee(1000);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(3, 650);
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        address[] memory unlockFeeReceivers = new address[](2);
        uint256[] memory unlockFeeProportions = new uint256[](2);
        unlockFeeReceivers[0] = unlockFeeReceiver1;
        unlockFeeReceivers[1] = unlockFeeReceiver2;
        unlockFeeProportions[0] = 7500;
        unlockFeeProportions[1] = 2500;
        diamondManagerFacet.setUnlockFeeReceivers(unlockFeeReceivers, unlockFeeProportions);

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

        vm.expectRevert(UnlockFacet__InvalidAmount.selector);
        unlockFacet.unlock(954);

        unlockFacet.unlock(953);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 0);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 0);
        assertEq(diamondManagerFacet.getUnlockAmountOfUser(user, 1), 953 - 95);
        assertEq(diamondManagerFacet.getUnlockTimestampOfUser(user, 1), block.timestamp + 3 days - 12960);
        assertEq(
            diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver2),
            94
        );
        assertEq(diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver1), 71);
        assertEq(diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver2), 23);
    }

    function test_UnlockBeingGoldStratosphereMember() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));
        diamondManagerFacet.setUnlockFee(1000);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(3, 650);
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        address[] memory unlockFeeReceivers = new address[](2);
        uint256[] memory unlockFeeProportions = new uint256[](2);
        unlockFeeReceivers[0] = unlockFeeReceiver1;
        unlockFeeReceivers[1] = unlockFeeReceiver2;
        unlockFeeProportions[0] = 7500;
        unlockFeeProportions[1] = 2500;
        diamondManagerFacet.setUnlockFeeReceivers(unlockFeeReceivers, unlockFeeProportions);

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

        vm.expectRevert(UnlockFacet__InvalidAmount.selector);
        unlockFacet.unlock(955);

        unlockFacet.unlock(954);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getDepositPointsOfUser(user, 1), 0);
        assertEq(diamondManagerFacet.getTotalDepositAmountOfSeason(1), 0);
        assertEq(diamondManagerFacet.getTotalPointsOfSeason(1), 0);
        assertEq(diamondManagerFacet.getUnlockAmountOfUser(user, 1), 954 - 95);
        assertEq(diamondManagerFacet.getUnlockTimestampOfUser(user, 1), block.timestamp + 3 days - 16848);
        assertEq(
            diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver1) +
                diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver2),
            94
        );
        assertEq(diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver1), 71);
        assertEq(diamondManagerFacet.getPendingWithdrawals(unlockFeeReceiver2), 23);
    }
}
