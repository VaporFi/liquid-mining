// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidMiningDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__AlreadyClaimed} from "src/facets/ClaimFacet.sol";
import {BoostFacet, BoostFacet__InvalidBoostLevel, BoostFacet__BoostAlreadyClaimed, BoostFacet__UserNotParticipated} from "src/facets/BoostFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {StratosphereMock} from "test/mocks/StratosphereMock.sol";
import "src/libraries/LPercentages.sol";

contract BoostFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidMiningDiamond internal diamond;
    DepositFacet internal depositFacet;
    ClaimFacet internal claimFacet;
    BoostFacet internal boostFacet;
    DiamondManagerFacet internal diamondManagerFacet;

    // setup addresses
    address feeReceiver1 = makeAddr("feeReceiver1");
    address feeReceiver2 = makeAddr("feeReceiver2");
    address diamondOwner = makeAddr("diamondOwner");
    address user = makeAddr("user");
    address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");
    address stratosphereMemberSilver = makeAddr("stratosphereMemberSilver");
    address stratosphereMemberGold = makeAddr("stratosphereMemberGold");
    // setup test details
    uint256 rewardTokenToDistribute = 10000 * 1e18;
    uint256 testDepositAmount = 5000 * 1e18;
    uint256 depositFee = 500;
    uint256 depositDiscountBasic = 500;
    uint256 depositDiscountSilver = 550;
    uint256 depositDiscountGold = 650;
    /// @dev using 1e6 because USDC has 6 decimals
    uint256 boostFeeLvl1 = 2 * 1e6;
    uint256 boostFeeLvl2 = 3 * 1e6;
    uint256 boostFeeLvl3 = 4 * 1e6;
    // boost data setup
    uint256 boostLvl1Tier1 = 1000;
    uint256 boostLvl1Tier2 = 1100;
    uint256 boostLvl1Tier3 = 1200;
    uint256 boostLvl1Tier4 = 1300;
    uint256 boostLvl1Tier5 = 1400;
    uint256 boostLvl1Tier6 = 1500;
    uint256 boostLvl2Tier1 = 2000;
    uint256 boostLvl2Tier2 = 2100;
    uint256 boostLvl2Tier3 = 2200;
    uint256 boostLvl2Tier4 = 2300;
    uint256 boostLvl2Tier5 = 2400;
    uint256 boostLvl2Tier6 = 2500;
    uint256 boostLvl3Tier1 = 1200;
    uint256 boostLvl3Tier2 = 4100;
    uint256 boostLvl3Tier3 = 4200;
    uint256 boostLvl3Tier4 = 4300;
    uint256 boostLvl3Tier5 = 4400;
    uint256 boostLvl3Tier6 = 4500;

    function setUp() public {
        vm.startPrank(diamondOwner);

        diamond = createDiamond();
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));
        claimFacet = ClaimFacet(address(diamond));
        boostFacet = BoostFacet(address(diamond));

        // Set up season details for deposit
        rewardToken.mint(address(diamond), rewardTokenToDistribute);
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

    function test_RevertIf_NotStratosphereMember() public {
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.expectRevert(BoostFacet__InvalidBoostLevel.selector);
        boostFacet.claimBoost(1);
        vm.stopPrank();
    }

    function test_RevertIf_NoDeposit() public {
        vm.startPrank(stratosphereMemberBasic);
        vm.expectRevert(BoostFacet__UserNotParticipated.selector);
        boostFacet.claimBoost(1);
        vm.stopPrank();
    }

    function test_BoostWithStratBasicLvl1() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberBasic, boostFeeLvl1);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), boostFeeLvl1);
        boostFacet.claimBoost(1);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountBasic, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl1Tier1, depositAmountAfterFee);
        (, uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberBasic, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_BoostWithStratSilverLvl1() public {
        vm.startPrank(stratosphereMemberSilver);
        _mintAndDeposit(stratosphereMemberSilver, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberSilver, boostFeeLvl1);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberSilver), boostFeeLvl1);
        boostFacet.claimBoost(1);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountSilver, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl1Tier2, depositAmountAfterFee);
        (, uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberSilver, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberSilver), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_BoostWithStratGoldLvl1() public {
        vm.startPrank(stratosphereMemberGold);
        _mintAndDeposit(stratosphereMemberGold, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberGold, boostFeeLvl1);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberGold), boostFeeLvl1);
        boostFacet.claimBoost(1);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountGold, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl1Tier3, depositAmountAfterFee);
        (, uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberGold, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberGold), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_BoostWithStratBasicLvl2() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberBasic, boostFeeLvl2);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), boostFeeLvl2);
        boostFacet.claimBoost(2);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountBasic, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl2Tier1, depositAmountAfterFee);
        (, uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberBasic, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl2);
        vm.stopPrank();
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

    function _calculatePoints(uint256 boostPointsAmount, uint256 depositAmount) internal pure returns (uint256) {
        return LPercentages.percentage(depositAmount, boostPointsAmount);
    }
}
