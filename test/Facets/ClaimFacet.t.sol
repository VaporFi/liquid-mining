// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__AlreadyClaimed} from "src/facets/ClaimFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {StratosphereMock} from "test/mocks/StratosphereMock.sol";
import "../../src/libraries/LPercentages.sol";

contract ClaimFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    ClaimFacet internal claimFacet;
    DiamondManagerFacet internal diamondManagerFacet;

    // setup addresses
    address feeReceiver1 = makeAddr("FeeReceiver1");
    address feeReceiver2 = makeAddr("FeeReceiver2");
    address diamondOwner = makeAddr("diamondOwner");
    address user = makeAddr("user");
    address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");
    address stratosphereMemberSilver = makeAddr("stratosphereMemberSilver");
    address stratosphereMemberGold = makeAddr("stratosphereMemberGold");
    // setup test details
    uint256 rewardTokenToDistribute = 10000 * 1e18;
    uint256 testDepositAmount = 5000 * 1e18;

    function setUp() public {
        vm.startPrank(diamondOwner);

        diamond = createDiamond();
        depositFacet = DepositFacet(address(diamond));
        claimFacet = ClaimFacet(address(diamond));
        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        // Set up season details for deposit
        rewardToken.mint(address(diamond), rewardTokenToDistribute);
        diamondManagerFacet.setRewardToken(address(rewardToken));
        diamondManagerFacet.startNewSeason(rewardTokenToDistribute);
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = feeReceiver1;
        depositFeeReceivers[1] = feeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();
    }

    function test_ClaimRewardsWihtoutBeingStratMember() public {
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        uint256 shareOfUser = _calculateShare(user, 1);
        claimFacet.claim();
        assertEq(rewardToken.balanceOf(user), shareOfUser);
        assertEq(rewardToken.balanceOf(user), rewardTokenToDistribute);
        assertEq(diamondManagerFacet.getSeasonTotalClaimedRewards(1), rewardTokenToDistribute);
        assertEq(diamondManagerFacet.getUserClaimedRewards(user, 1), rewardTokenToDistribute);
        vm.stopPrank();
    }

    function test_ClaimRewardsWithStratMemberBasic() public {
        vm.startPrank(stratosphereMemberBasic);

        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        uint256 shareOfUser = _calculateShare(stratosphereMemberBasic, 1);
        claimFacet.claim();
        assertEq(rewardToken.balanceOf(stratosphereMemberBasic), rewardTokenToDistribute);
        assertEq(diamondManagerFacet.getUserClaimedRewards(stratosphereMemberBasic, 1), rewardTokenToDistribute);

        vm.stopPrank();
    }

    function test_ClaimRewardsWithStratMemberSilver() public {
        // Set up season for restake
        vm.startPrank(stratosphereMemberSilver);
        _mintAndDeposit(stratosphereMemberSilver, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        claimFacet.claim();
        assertEq(rewardToken.balanceOf(stratosphereMemberSilver), rewardTokenToDistribute);
        assertEq(diamondManagerFacet.getUserClaimedRewards(stratosphereMemberSilver, 1), rewardTokenToDistribute);

        vm.stopPrank();
    }

    function test_ClaimRewardsWithStratMemberGold() public {
        // Set up season for restake
        vm.startPrank(stratosphereMemberGold);
        _mintAndDeposit(stratosphereMemberGold, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        claimFacet.claim();
        assertEq(rewardToken.balanceOf(stratosphereMemberGold), rewardTokenToDistribute);
        assertEq(diamondManagerFacet.getUserClaimedRewards(stratosphereMemberGold, 1), rewardTokenToDistribute);

        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingTwice() public {
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        claimFacet.claim();
        vm.expectRevert(ClaimFacet__AlreadyClaimed.selector);
        claimFacet.claim();
        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingTwiceWithStratMember() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        claimFacet.claim();
        vm.expectRevert(ClaimFacet__AlreadyClaimed.selector);
        claimFacet.claim();
        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingBeforeSeasonEnd() public {
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.expectRevert(ClaimFacet__InProgressSeason.selector);
        claimFacet.claim();
        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingBeforeSeasonEndWithStratMember() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        vm.expectRevert(ClaimFacet__InProgressSeason.selector);
        claimFacet.claim();
        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingWithNoDeposit() public {
        vm.startPrank(user);
        vm.warp(block.timestamp + 31 days);
        vm.expectRevert(ClaimFacet__NotEnoughPoints.selector);
        claimFacet.claim();
        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingWithNoDepositWithStratMember() public {
        vm.startPrank(stratosphereMemberBasic);
        vm.warp(block.timestamp + 31 days);
        vm.expectRevert(ClaimFacet__NotEnoughPoints.selector);
        claimFacet.claim();
        vm.stopPrank();
    }

    function test_DataIsUpdatingWithClaims() public {
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        assertEq(diamondManagerFacet.getUserClaimedRewards(user, 1), 0);
        claimFacet.claim();
        assertEq(diamondManagerFacet.getUserClaimedRewards(user, 1), rewardTokenToDistribute);
        vm.stopPrank();
    }

    function test_DataIsUpdatingWithClaimsWithStratMember() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        assertEq(diamondManagerFacet.getUserClaimedRewards(stratosphereMemberBasic, 1), 0);
        claimFacet.claim();
        assertEq(diamondManagerFacet.getUserClaimedRewards(stratosphereMemberBasic, 1), rewardTokenToDistribute);
        vm.stopPrank();
    }

    // Helper functions

    function _mintAndDeposit(address _addr, uint256 _amount) internal {
        depositToken.increaseAllowance(address(depositFacet), _amount);
        depositToken.mint(_addr, _amount);
        depositFacet.deposit(_amount);
    }

    function _calculateShare(address _addr, uint256 _seasonId) internal view returns (uint256) {
        uint256 seasonTotalPoints = diamondManagerFacet.getSeasonTotalPoints(_seasonId);
        uint256 userTotalPoints = diamondManagerFacet.getUserTotalPoints(1, _addr);
        uint256 userShare = (userTotalPoints * 1e18) / seasonTotalPoints;
        return _vapeToDistribute(userShare);
    }

    function _vapeToDistribute(uint256 _userShare) internal view returns (uint256) {
        return (rewardTokenToDistribute * _userShare) / 1e18;
    }
}
