// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__AlreadyClaimed} from "src/facets/ClaimFacet.sol";
import {BoostFacet, BoostFacet__InvalidBoostLevel, BoostFacet__BoostAlreadyClaimed, BoostFacet__UserNotParticipated} from "src/facets/BoostFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "src/mocks/ERC20Mock.sol";
import {RewardsControllerMock} from "src/mocks/RewardsControllerMock.sol";
import {StratosphereMock} from "src/mocks/StratosphereMock.sol";
import "src/libraries/LPercentages.sol";

contract BoostFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    ClaimFacet internal claimFacet;
    BoostFacet internal boostFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    ERC20Mock internal depositToken;
    ERC20Mock internal rewardToken;
    ERC20Mock internal boostFeeToken;
    StratosphereMock stratosphereMock;
    RewardsControllerMock rewardsControllerMock;

    // setup addresses
    address feeReceiver1 = makeAddr("FeeReceiver1");
    address feeReceiver2 = makeAddr("FeeReceiver2");
    address diamondOwner = makeAddr("diamondOwner");
    address user = makeAddr("user");
    address stratosphereMemberBasic = makeAddr("stratosphere_member_basic");
    address stratosphereMemberSilver = makeAddr("stratosphere_member_silver");
    address stratosphereMemberGold = makeAddr("stratosphere_member_gold");
    // setup test details
    uint256 rewardTokenToDistribute = 10000 * 1e18;
    uint256 testDepositAmount = 5000 * 1e18;
    uint256 depositFee = 500;
    uint256 depositDiscountBasic = 500;
    uint256 depositDiscountSilver = 550;
    uint256 depositDiscountGold = 650;
    uint256 boostFeeLvl1 = 2 * 1e18;
    uint256 boostFeeLvl2 = 3 * 1e18;
    uint256 boostFeeLvl3 = 4 * 1e18;

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

    uint256 boostLvl3Tier1 = 4000;
    uint256 boostLvl3Tier2 = 4100;
    uint256 boostLvl3Tier3 = 4200;
    uint256 boostLvl3Tier4 = 4300;
    uint256 boostLvl3Tier5 = 4400;
    uint256 boostLvl3Tier6 = 4500;

    


    function setUp() public {
        vm.startPrank(diamondOwner);

        diamond = createDiamond();
        depositFacet = new DepositFacet();
        claimFacet = new ClaimFacet();
        boostFacet = new BoostFacet();
        diamondManagerFacet = new DiamondManagerFacet();
        

        // Deposit Facet Setup
        bytes4[] memory depositFunctionSelectors = new bytes4[](1);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;
        addFacet(diamond, address(depositFacet), depositFunctionSelectors);

        // Restake Facet Setup
        bytes4[] memory claimFunctionSelectors = new bytes4[](1);
        claimFunctionSelectors[0] = claimFacet.claim.selector;
        addFacet(diamond, address(claimFacet), claimFunctionSelectors);

        // Boost Facet Setup
        bytes4[] memory boostFunctionSelectors = new bytes4[](2);
        boostFunctionSelectors[0] = boostFacet.claimBoost.selector;
        addFacet(diamond, address(boostFacet), boostFunctionSelectors);

        // Diamond Manager Facet Setup
        bytes4[] memory managerFunctionSelectors = new bytes4[](29);
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
        managerFunctionSelectors[13] = diamondManagerFacet.setRestakeDiscountForStratosphereMember.selector;
        managerFunctionSelectors[14] = diamondManagerFacet.setRestakeFee.selector;
        managerFunctionSelectors[15] = diamondManagerFacet.getCurrentSeasonId.selector;
        managerFunctionSelectors[16] = diamondManagerFacet.getSeasonEndTimestamp.selector;
        managerFunctionSelectors[17] = diamondManagerFacet.getWithdrawRestakeStatus.selector;
        managerFunctionSelectors[18] = diamondManagerFacet.startNewSeason.selector;
        managerFunctionSelectors[19] = diamondManagerFacet.getUserDepositAmount.selector;
        managerFunctionSelectors[20] = diamondManagerFacet.setRewardToken.selector;
        managerFunctionSelectors[21] = diamondManagerFacet.getUserClaimedRewards.selector;
        managerFunctionSelectors[22] = diamondManagerFacet.getSeasonTotalPoints.selector;
        managerFunctionSelectors[23] = diamondManagerFacet.getSeasonTotalClaimedRewards.selector;
        managerFunctionSelectors[24] = diamondManagerFacet.getUserTotalPoints.selector;
        managerFunctionSelectors[25] = diamondManagerFacet.setBoostFee.selector;
        managerFunctionSelectors[26] = diamondManagerFacet.setBoostFeeToken.selector;
        managerFunctionSelectors[27] = diamondManagerFacet.setBoostPercentTierLevel.selector;
        managerFunctionSelectors[28] = diamondManagerFacet.getUserPoints.selector;
        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        // Initializers
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        depositToken = new ERC20Mock("Vapor nodes", "VPND");
        rewardToken = new ERC20Mock("VAPE Token", "VAPE");
        boostFeeToken = new ERC20Mock("USDC", "USDC");
        diamondManagerFacet.setDepositToken(address(depositToken));
        depositFacet = DepositFacet(address(diamond));
        claimFacet = ClaimFacet(address(diamond));
        boostFacet = BoostFacet(address(diamond));
        stratosphereMock = new StratosphereMock();
        rewardsControllerMock = new RewardsControllerMock();

        // Set up season details for deposit
        rewardToken.mint(address(diamond), rewardTokenToDistribute);
        diamondManagerFacet.setRewardToken(address(rewardToken));
        diamondManagerFacet.startNewSeason(rewardTokenToDistribute);
        diamondManagerFacet.setDepositFee(depositFee);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, depositDiscountBasic);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, depositDiscountSilver);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, depositDiscountGold);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = feeReceiver1;
        depositFeeReceivers[1] = feeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);
        diamondManagerFacet.setBoostFee(1, boostFeeLvl1);
        diamondManagerFacet.setBoostFee(2, boostFeeLvl2);
        diamondManagerFacet.setBoostFee(3, boostFeeLvl3);
        diamondManagerFacet.setBoostFeeToken(address(boostFeeToken));
        diamondManagerFacet.setBoostPercentTierLevel(1, 1, boostLvl1Tier1);
        diamondManagerFacet.setBoostPercentTierLevel(2, 1, boostLvl1Tier2);
        diamondManagerFacet.setBoostPercentTierLevel(3, 1, boostLvl1Tier3);
        diamondManagerFacet.setBoostPercentTierLevel(1, 2, boostLvl2Tier1);
        
        vm.stopPrank();

    }

    function test_revertIfNotStratosphereMember() public {
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.expectRevert(BoostFacet__InvalidBoostLevel.selector);
        boostFacet.claimBoost(1);
        vm.stopPrank();
    }

    function test_revertIfNoDeposit() public {
        vm.startPrank(stratosphereMemberBasic);
        vm.expectRevert(BoostFacet__UserNotParticipated.selector);
        boostFacet.claimBoost(1);
        vm.stopPrank();
    }

    function test_boostWithStratBasicLvl1() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberBasic, boostFeeLvl1);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), boostFeeLvl1);
        boostFacet.claimBoost(1);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountBasic, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl1Tier1, depositAmountAfterFee);
        (uint256 depositPoints , uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberBasic, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_boostWithStratSilverLvl1() public {
        vm.startPrank(stratosphereMemberSilver);
        _mintAndDeposit(stratosphereMemberSilver, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberSilver, boostFeeLvl1);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberSilver), boostFeeLvl1);
        boostFacet.claimBoost(1);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountSilver, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl1Tier2, depositAmountAfterFee);
        (uint256 depositPoints , uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberSilver, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberSilver), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_boostWithStratGoldLvl1() public {
        vm.startPrank(stratosphereMemberGold);
        _mintAndDeposit(stratosphereMemberGold, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberGold, boostFeeLvl1);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberGold), boostFeeLvl1);
        boostFacet.claimBoost(1);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountGold, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl1Tier3, depositAmountAfterFee);
        (uint256 depositPoints , uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberGold, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberGold), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_boostWithStratBasicLvl2() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberBasic, boostFeeLvl2);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), boostFeeLvl2);
        boostFacet.claimBoost(2);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountBasic, depositFee);
        uint256 expectedBoostPoints = _calculatePoints(boostLvl2Tier1, depositAmountAfterFee);
        (uint256 depositPoints , uint256 boostPoints) = diamondManagerFacet.getUserPoints(stratosphereMemberBasic, 1);
        assertEq(boostPoints, expectedBoostPoints);
        assertEq(boostFeeToken.balanceOf(stratosphereMemberBasic), 0);
        assertEq(boostFeeToken.balanceOf(address(boostFacet)), boostFeeLvl2);
        vm.stopPrank();
    }

    

    // Helper functions

    function _getAmountAfterFee(uint256 _amount, uint256 _discount, uint256 _fee) internal view returns (uint256) {
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

   function _calculatePoints(
        uint256 boostPointsAmount,
        uint256 depositAmount
    ) internal view returns (uint256) {
        return LPercentages.percentage(depositAmount, boostPointsAmount);
    }

}
