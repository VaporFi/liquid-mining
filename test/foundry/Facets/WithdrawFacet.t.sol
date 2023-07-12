// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { WithdrawFacet, WithdrawFacet__InsufficientBalance, WithdrawFacet__UnlockNotMatured } from "src/facets/WithdrawFacet.sol";
import { DepositFacet } from "src/facets/DepositFacet.sol";
import { UnlockFacet } from "src/facets/UnlockFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { ERC20Mock } from "test/foundry/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/foundry/mocks/StratosphereMock.sol";

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

    function test_RevertIf_WithdrawTwice() external {
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
}
