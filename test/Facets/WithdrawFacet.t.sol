// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {WithdrawFacet, WithdrawFacet__InProgressSeason, WithdrawFacet__InsufficientBalance, WithdrawFacet__UnlockNotMatured, WithdrawFacet__UserNotParticipated, WithdrawFacet__AlreadyWithdrawn} from "src/facets/WithdrawFacet.sol";
import {DepositFacet} from "src/facets/DepositFacet.sol";
import {UnlockFacet} from "src/facets/UnlockFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {StratosphereMock} from "test/mocks/StratosphereMock.sol";

contract WithdrawFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    UnlockFacet internal unlockFacet;
    DepositFacet internal depositFacet;
    WithdrawFacet internal withdrawFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    address feeReceiver1 = makeAddr("FeeReceiver1");
    address feeReceiver2 = makeAddr("FeeReceiver2");

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        unlockFacet = UnlockFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));
        withdrawFacet = WithdrawFacet(address(diamond));

        address[] memory feeReceivers = new address[](2);
        uint256[] memory feeProportions = new uint256[](2);
        feeReceivers[0] = feeReceiver1;
        feeReceivers[1] = feeReceiver2;
        feeProportions[0] = 7500;
        feeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(feeReceivers, feeProportions);

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

    function test_RevertIf_NotUnlocked() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        vm.expectRevert(WithdrawFacet__InsufficientBalance.selector);
        withdrawFacet.withdrawUnlocked();
    }

    function test_RevertIf_PrematureUnlocked() external {
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

    function test_RevertIf_WithdrawAgain() external {
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

    function test_RevertIf_Withdraw() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(95);
        vm.expectRevert(WithdrawFacet__UserNotParticipated.selector);
        withdrawFacet.withdraw();
    }

    function test_RevertIf_WithdrawWhenSeasonInProgress() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(90);
        vm.expectRevert(WithdrawFacet__InProgressSeason.selector);
        withdrawFacet.withdraw();
    }

    function test_RevertIf_WithdrawTwice() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(90);
        vm.warp(block.timestamp + 31 days);
        withdrawFacet.withdraw();
        vm.expectRevert(WithdrawFacet__AlreadyWithdrawn.selector);
        withdrawFacet.withdraw();
    }

    function test_Withdraw_AfterSeasonEndSuccessful() external {
        address user = makeAddr("user");
        vm.startPrank(user);
        depositHelper(user, 1000);
        vm.warp(block.timestamp + 31 days);
        uint256 previousBalanceOfUser = depositToken.balanceOf(user);
        withdrawFacet.withdraw();
        uint256 finalBalanceOfUser = depositToken.balanceOf(user);
        assertEq(finalBalanceOfUser, previousBalanceOfUser + 950);
    }

    function test_RevertIf_WithdrawAllWithoutDeposit() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(95);
        vm.expectRevert(WithdrawFacet__UserNotParticipated.selector);
        withdrawFacet.withdrawAll();
    }

    function test_RevertIf_WithdrawAllWithoutSeasonEnd() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        vm.expectRevert(WithdrawFacet__InProgressSeason.selector);
        withdrawFacet.withdrawAll();
    }

    function test_RevertIf_WithdrawAllWithoutUnlockAmount() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        vm.warp(block.timestamp + 31 days);
        vm.expectRevert(WithdrawFacet__InsufficientBalance.selector);
        withdrawFacet.withdrawAll();
    }

    function test_RevertIf_WithdrawAllTwice() external {
        vm.startPrank(makeAddr("user"));
        depositHelper(makeAddr("user"), 100);
        unlockHelper(90);
        vm.warp(block.timestamp + 31 days);
        withdrawFacet.withdrawAll();
        vm.expectRevert(WithdrawFacet__InsufficientBalance.selector);
        withdrawFacet.withdrawAll();
    }

    function test_WithdrawAll_AfterSeasonEndSuccessful() external {
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
