// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DepositFacet } from "src/facets/DepositFacet.sol";
import { ClaimFacet } from "src/facets/ClaimFacet.sol";
import { BoostFacet, BoostFacet__BoostAlreadyClaimed } from "src/facets/BoostFacet.sol";
import { UnlockFacet } from "src/facets/UnlockFacet.sol";
import { FeeCollectorFacet } from "src/facets/FeeCollectorFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { ERC20Mock } from "test/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/mocks/StratosphereMock.sol";
import "src/libraries/LPercentages.sol";

contract FeeCollectorFacetTest is DiamondTest {
    // StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidMiningDiamond internal diamond;
    UnlockFacet internal unlockFacet;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    FeeCollectorFacet internal feeCollectorFacet;
    ClaimFacet internal claimFacet;
    BoostFacet internal boostFacet;
    address depositFeeReceiver1 = makeAddr("depositFeeReceiver1");
    address depositFeeReceiver2 = makeAddr("depositFeeReceiver2");
    address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");
    uint256 rewardTokenToDistribute = 10000 * 1e18;

    function setUp() public {
        vm.startPrank(makeAddr("diamondOwner"));

        diamond = createDiamond();
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        unlockFacet = UnlockFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));
        feeCollectorFacet = FeeCollectorFacet(address(diamond));
        claimFacet = ClaimFacet(address(diamond));
        boostFacet = BoostFacet(address(diamond));

        // diamondManagerFacet.setCurrentSeasonId(1);
        // diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        rewardToken.mint(address(diamond), rewardTokenToDistribute);
        diamondManagerFacet.setRewardToken(address(rewardToken));
        diamondManagerFacet.startNewSeason(rewardTokenToDistribute);
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setUnlockFeeReceivers(depositFeeReceivers, depositFeeProportions);
        diamondManagerFacet.setBoostFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();
    }

    function test_collectUnlockFee() public {
        address user = makeAddr("user");

        vm.startPrank(user);
        _mintAndDeposit(user, 1000);
        unlockFacet.unlock(950);
        vm.stopPrank();

        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)), 71);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)), 23);

        vm.startPrank(makeAddr("diamondOwner"));
        feeCollectorFacet.collectUnlockFees();
        assertEq(depositToken.balanceOf(depositFeeReceiver1), 71);
        assertEq(depositToken.balanceOf(depositFeeReceiver2), 23);
    }

    function test_collectBoostFee() public {
        uint256 boostFeeLvl1 = 2 * 1e6;

        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, 1000);
        _fundUserWithfeeToken(stratosphereMemberBasic, boostFeeLvl1);
        vm.expectRevert(BoostFacet__BoostAlreadyClaimed.selector);
        boostFacet.claimBoost(1);
        vm.stopPrank();

        vm.startPrank(makeAddr("diamondOwner"));
        feeCollectorFacet.collectBoostFees();
    }

    // Helper functions

    function _getAmountAfterFee(uint256 _amount, uint256 _discount, uint256 _fee) internal pure returns (uint256) {
        return _amount - LPercentages.percentage(_amount, _fee - (_discount * _fee) / 10000);
    }

    function _mintAndDeposit(address _addr, uint256 _amount) internal {
        depositToken.increaseAllowance(address(depositFacet), _amount);
        depositToken.mint(_addr, _amount);
        depositFacet.deposit(_amount);
    }

    function _fundUserWithfeeToken(address _addr, uint256 _amount) internal {
        feeToken.mint(_addr, _amount);
        feeToken.increaseAllowance(address(boostFacet), _amount);
    }

    function _startNewSeason() internal {
        vm.warp(block.timestamp + 31 days);
        uint256 newSeasonId = diamondManagerFacet.getCurrentSeasonId() + 1;
        diamondManagerFacet.setCurrentSeasonId(newSeasonId);
        diamondManagerFacet.setSeasonEndTimestamp(newSeasonId, block.timestamp + 30 days);
    }

    function _calculatePoints(uint256 boostPointsAmount, uint256 depositAmount) internal pure returns (uint256) {
        return LPercentages.percentage(depositAmount, boostPointsAmount);
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
