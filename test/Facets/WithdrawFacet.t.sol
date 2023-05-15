// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { WithdrawFacet, WithdrawFacet__InProgressSeason, WithdrawFacet__InsufficientBalance, WithdrawFacet__UnlockNotMatured, WithdrawFacet__UserNotParticipated, WithdrawFacet__AlreadyWithdrawn } from "src/facets/WithdrawFacet.sol";
import { DepositFacet } from "src/facets/DepositFacet.sol";
import { UnlockFacet } from "src/facets/UnlockFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { ERC20Mock } from "test/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/mocks/StratosphereMock.sol";

contract WithdrawFacetTest is DiamondTest {
    // StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidMiningDiamond internal diamond;
    UnlockFacet internal unlockFacet;
    DepositFacet internal depositFacet;
    WithdrawFacet internal withdrawFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    address feeReceiver1 = makeAddr("FeeReceiver1");
    address feeReceiver2 = makeAddr("FeeReceiver2");
    uint256 rewardTokenToDistribute = 10000 * 1e18;

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));
        unlockFacet = UnlockFacet(address(diamond));
        withdrawFacet = WithdrawFacet(address(diamond));

        // Set up season details for deposit
        rewardToken.mint(address(diamond), rewardTokenToDistribute);
        diamondManagerFacet.startNewSeason(rewardTokenToDistribute);

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

    function test_RevertWhen_WithdrawFromNonParticipant() external {
        vm.startPrank(makeAddr("user"));
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
        uint256 depositAmount = 1000;
        vm.startPrank(user);
        depositHelper(user, depositAmount);
        vm.warp(block.timestamp + 31 days);
        withdrawFacet.withdraw();
        uint256 finalBalanceOfUser = depositToken.balanceOf(user);
        assertEq(finalBalanceOfUser, depositAmount);
    }

    function test_Revert_If_WithdrawAll_Without_Deposit() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(100);
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
        uint256 _depositAmount = 1000;
        uint256 _unlockAmount = 100;

        vm.startPrank(user);
        depositHelper(user, _depositAmount);
        unlockHelper(_unlockAmount);
        vm.warp(block.timestamp + 31 days);

        withdrawFacet.withdrawAll();

        uint256 finalBalanceOfUser = depositToken.balanceOf(user);
        assertEq(finalBalanceOfUser, 990);
    }
}
