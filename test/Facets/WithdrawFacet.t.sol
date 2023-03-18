// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {WithdrawFacet, WithdrawFacet__InProgressSeason, WithdrawFacet__InsufficientBalance, WithdrawFacet__UnlockNotMatured, WithdrawFacet__UserNotParticipated, WithdrawFacet__AlreadyWithdrawn} from "src/facets/WithdrawFacet.sol";
import {DepositFacet} from "src/facets/DepositFacet.sol";
import {UnlockFacet} from "src/facets/UnlockFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "src/mocks/ERC20Mock.sol";
import {StratosphereMock} from "src/mocks/StratosphereMock.sol";

contract WithdrawFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    UnlockFacet internal unlockFacet;
    DepositFacet internal depositFacet;
    WithdrawFacet internal withdrawFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    ERC20Mock internal depositToken;
    address feeReceiver1 = makeAddr("FeeReceiver1");
    address feeReceiver2 = makeAddr("FeeReceiver2");
    StratosphereMock stratosphereMock;

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

        withdrawFacet = new WithdrawFacet();
        bytes4[] memory withdrawFunctionSelectors = new bytes4[](3);
        withdrawFunctionSelectors[0] = withdrawFacet.withdrawUnlocked.selector;
        withdrawFunctionSelectors[1] = withdrawFacet.withdraw.selector;
        withdrawFunctionSelectors[2] = withdrawFacet.withdrawAll.selector;
        addFacet(diamond, address(withdrawFacet), withdrawFunctionSelectors);

        bytes4[] memory managerFunctionSelectors = new bytes4[](19);
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
        managerFunctionSelectors[13] = diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember.selector;
        managerFunctionSelectors[14] = diamondManagerFacet.setUnlockFee.selector;
        managerFunctionSelectors[15] = diamondManagerFacet.setUnlockFeeReceivers.selector;
        managerFunctionSelectors[16] = diamondManagerFacet.getUnlockAmountOfUser.selector;
        managerFunctionSelectors[17] = diamondManagerFacet.getUnlockTimestampOfUser.selector;
        managerFunctionSelectors[18] = diamondManagerFacet.getCurrentSeasonId.selector;

        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        depositToken = new ERC20Mock("Vapor nodes", "VPND");

        diamondManagerFacet.setDepositToken(address(depositToken));

        unlockFacet = UnlockFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));
        withdrawFacet = WithdrawFacet(address(diamond));

        stratosphereMock = new StratosphereMock();

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setUnlockFee(1000);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setUnlockTimestampDiscountForStratosphereMember(3, 650);
        address[] memory feeReceivers = new address[](2);
        uint256[] memory feeProportions = new uint256[](2);
        feeReceivers[0] = feeReceiver1;
        feeReceivers[1] = feeReceiver2;
        feeProportions[0] = 7500;
        feeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(feeReceivers, feeProportions);
        diamondManagerFacet.setUnlockFeeReceivers(feeReceivers, feeProportions);

        vm.stopPrank();
    }

    function depositHelper(address addr, uint256 amount) internal {
        depositToken.mint(addr, amount);
        depositToken.increaseAllowance(address(depositFacet), amount);
        depositFacet.deposit(amount);
    }

    function unlockHelper(uint256 amount) internal {
        unlockFacet.unlock(amount);
    }

    function test_Revert_If_Not_Unlocked() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        vm.expectRevert(WithdrawFacet__InsufficientBalance.selector);
        withdrawFacet.withdrawUnlocked();
    }

    function test_Revert_If_Premature_Unlocked() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(90);
        vm.expectRevert(WithdrawFacet__UnlockNotMatured.selector);
        withdrawFacet.withdrawUnlocked();
    }

    function test_Withdraw_Successful() external {
        address user = makeAddr("user");
        vm.startPrank(user);
        depositHelper(user, 1000);
        unlockHelper(950);
        vm.warp(block.timestamp + 3 days);
        uint256 previousBalanceOfUser = depositToken.balanceOf(user);
        withdrawFacet.withdrawUnlocked();
        uint256 finalBalanceOfUser = depositToken.balanceOf(user);
        assertEq(finalBalanceOfUser, previousBalanceOfUser + 950 - 95);
    }

    function test_Revert_Withdraw_Again() external {
        address user = makeAddr("user");
        vm.startPrank(user);
        depositHelper(user, 1000);
        unlockHelper(950);
        vm.warp(block.timestamp + 3 days);
        uint256 previousBalanceOfUser = depositToken.balanceOf(user);
        withdrawFacet.withdrawUnlocked();
        uint256 finalBalanceOfUser = depositToken.balanceOf(user);
        assertEq(finalBalanceOfUser, previousBalanceOfUser + 950 - 95);
        vm.expectRevert(WithdrawFacet__InsufficientBalance.selector);
        withdrawFacet.withdrawUnlocked();
    }

    function test_Revert_If_Withdraw() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(95);
        vm.expectRevert(WithdrawFacet__UserNotParticipated.selector);
        withdrawFacet.withdraw();
    }

    function test_Revert_If_Withdraw_When_Season_In_Progress() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(90);
        vm.expectRevert(WithdrawFacet__InProgressSeason.selector);
        withdrawFacet.withdraw();
    }

    function test_Revert_If_Withdraw_Twice() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(90);
        vm.warp(block.timestamp + 31 days);
        withdrawFacet.withdraw();
        vm.expectRevert(WithdrawFacet__AlreadyWithdrawn.selector);
        withdrawFacet.withdraw();
    }

    function test_Withdraw_After_SeasonEnd_Successful() external {
        address user = makeAddr("user");
        vm.startPrank(user);
        depositHelper(user, 1000);
        vm.warp(block.timestamp + 31 days);
        uint256 previousBalanceOfUser = depositToken.balanceOf(user);
        withdrawFacet.withdraw();
        uint256 finalBalanceOfUser = depositToken.balanceOf(user);
        assertEq(finalBalanceOfUser, previousBalanceOfUser + 950);
    }

    function test_Revert_If_WithdrawAll_Without_Deposit() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(95);
        vm.expectRevert(WithdrawFacet__UserNotParticipated.selector);
        withdrawFacet.withdrawAll();
    }

    function test_Revert_If_WithdrawAll_Without_SeasonEnd() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        vm.expectRevert(WithdrawFacet__InProgressSeason.selector);
        withdrawFacet.withdrawAll();
    }

    function test_Revert_If_WithdrawAll_Without_UnlockAmount() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        vm.warp(block.timestamp + 31 days);
        vm.expectRevert(WithdrawFacet__InsufficientBalance.selector);
        withdrawFacet.withdrawAll();
    }

    function test_Revert_If_WithdrawAll_Twice() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(90);
        vm.warp(block.timestamp + 31 days);
        withdrawFacet.withdrawAll();
        vm.expectRevert(WithdrawFacet__InsufficientBalance.selector);
        withdrawFacet.withdrawAll();
    }

    function test_WithdrawAll_After_SeasonEnd_Successful() external {
        address user = makeAddr("user");
        vm.startPrank(user);
        depositHelper(user, 1000);
        unlockHelper(100);
        vm.warp(block.timestamp + 31 days);
        uint256 previousBalanceOfUser = depositToken.balanceOf(user);
        withdrawFacet.withdrawAll();
        uint256 finalBalanceOfUser = depositToken.balanceOf(user);
        assertEq(finalBalanceOfUser, previousBalanceOfUser + 940);
    }
}
