// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet} from "src/facets/DepositFacet.sol";
import {ClaimFacet} from "src/facets/ClaimFacet.sol";
import {BoostFacet} from "src/facets/BoostFacet.sol";
import {UnlockFacet} from "src/facets/UnlockFacet.sol";
import {RestakeFacet} from "src/facets/RestakeFacet.sol";
import {FeeCollectorFacet} from "src/facets/FeeCollectorfacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {StratosphereMock} from "test/mocks/StratosphereMock.sol";
import "src/libraries/LPercentages.sol";

contract FeeCollectorFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    UnlockFacet internal unlockFacet;
    DepositFacet internal depositFacet;
    RestakeFacet internal restakeFacet;
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
        restakeFacet = RestakeFacet(address(diamond));
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
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);
        diamondManagerFacet.setUnlockFeeReceivers(depositFeeReceivers, depositFeeProportions);
        diamondManagerFacet.setRestakeFeeReceivers(depositFeeReceivers, depositFeeProportions);
        diamondManagerFacet.setClaimFeeReceivers(depositFeeReceivers, depositFeeProportions);
        diamondManagerFacet.setBoostFeeReceivers(depositFeeReceivers, depositFeeProportions);

        vm.stopPrank();
    }

    function test_collectDepositFee() public {
        address user = makeAddr("user");

        vm.startPrank(user);
        _mintAndDeposit(user, 1000);
        vm.stopPrank();

        assertEq(
            diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)) +
                diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)),
            49
        );

        vm.startPrank(makeAddr("diamondOwner"));
        feeCollectorFacet.collectDepositFees();
        assertEq(depositToken.balanceOf(depositFeeReceiver1), 37);
        assertEq(depositToken.balanceOf(depositFeeReceiver2), 12);
    }

    function test_collectUnlockFee() public {
        address user = makeAddr("user");

        vm.startPrank(user);
        _mintAndDeposit(user, 1000);
        unlockFacet.unlock(950);
        vm.stopPrank();

        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver1, address(depositToken)), 71 + 37);
        assertEq(diamondManagerFacet.getPendingWithdrawals(depositFeeReceiver2, address(depositToken)), 23 + 12);

        vm.startPrank(makeAddr("diamondOwner"));
        feeCollectorFacet.collectUnlockFees();
        assertEq(depositToken.balanceOf(depositFeeReceiver1), 71 + 37);
        assertEq(depositToken.balanceOf(depositFeeReceiver2), 23 + 12);
    }

    function test_collectRestakeFee() public {
        address user = makeAddr("user");

        vm.startPrank(user);
        _mintAndDeposit(user, 1000);
        vm.stopPrank();

        // Set up season for restake
        vm.startPrank(makeAddr("diamondOwner"));
        _startNewSeason();
        vm.stopPrank();

        vm.startPrank(user);
        restakeFacet.restake();
        vm.stopPrank();

        uint256 restakeFee = ((diamondManagerFacet.getDepositAmountOfUser(user, 1) * initArgs.restakeFee) / 10000);

        vm.startPrank(makeAddr("diamondOwner"));
        feeCollectorFacet.collectRestakeFees();
        assertEq(
            depositToken.balanceOf(depositFeeReceiver1) + depositToken.balanceOf(depositFeeReceiver2),
            49 + restakeFee
        );
    }

    function test_collectClaimFee() public {
        address user = makeAddr("user");

        vm.startPrank(user);
        _mintAndDeposit(user, 1000);
        vm.warp(block.timestamp + 31 days);
        uint256 shareOfUser = _calculateShare(user, 1);
        uint256 _fee = LPercentages.percentage(shareOfUser, initArgs.claimFee);
        claimFacet.claim();
        vm.stopPrank();

        vm.startPrank(makeAddr("diamondOwner"));
        feeCollectorFacet.collectClaimFees();

        assertEq(rewardToken.balanceOf(depositFeeReceiver1) + rewardToken.balanceOf(depositFeeReceiver2), _fee);
    }

    function test_collectBoostFee() public {
        uint256 boostFeeLvl1 = 2 * 1e6;

        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, 1000);
        _fundUserWithBoostFeeToken(stratosphereMemberBasic, boostFeeLvl1);
        boostFacet.claimBoost(1);
        // uint256 _fee = LPercentages.percentage(_amount, boostFeeLvl1 - (_discount * boostFeeLvl1) / 10000);
        vm.stopPrank();

        vm.startPrank(makeAddr("diamondOwner"));
        feeCollectorFacet.collectBoostFees();

        assertEq(
            boostFeeToken.balanceOf(depositFeeReceiver1) + boostFeeToken.balanceOf(depositFeeReceiver2),
            boostFeeLvl1
        );
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

    function _fundUserWithBoostFeeToken(address _addr, uint256 _amount) internal {
        boostFeeToken.mint(_addr, _amount);
        boostFeeToken.increaseAllowance(address(boostFacet), _amount);
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
