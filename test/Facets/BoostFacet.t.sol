// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded } from "src/facets/DepositFacet.sol";
import { ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__AlreadyClaimed } from "src/facets/ClaimFacet.sol";
import { BoostFacet, BoostFacet__InvalidBoostLevel, BoostFacet__BoostAlreadyClaimed, BoostFacet__UserNotParticipated } from "src/facets/BoostFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { ERC20Mock } from "test/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/mocks/StratosphereMock.sol";
import "src/libraries/LPercentages.sol";

contract BoostFacetTest is DiamondTest {
    // StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
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
    uint256 depositFee = 0;
    uint256 depositDiscountBasic = 0;
    uint256 depositDiscountSilver = 0;
    uint256 depositDiscountGold = 0;
    /// @dev using 1e6 because USDC has 6 decimals
    uint256 boostFeeLvl1 = 2 * 1e6;
    uint256 boostFeeLvl2 = 3 * 1e6;
    uint256 boostFeeLvl3 = 4 * 1e6;
    // boost data setup
    uint256 boostLvl1Tier1 = 22;
    uint256 boostLvl1Tier2 = 28;
    uint256 boostLvl1Tier3 = 37;
    uint256 boostLvl1Tier4 = 51;
    uint256 boostLvl1Tier5 = 74;
    uint256 boostLvl1Tier6 = 115;
    uint256 boostLvl2Tier1 = 24;
    uint256 boostLvl2Tier2 = 30;
    uint256 boostLvl2Tier3 = 40;
    uint256 boostLvl2Tier4 = 55;
    uint256 boostLvl2Tier5 = 81;
    uint256 boostLvl2Tier6 = 125;
    uint256 boostLvl3Tier1 = 26;
    uint256 boostLvl3Tier2 = 33;
    uint256 boostLvl3Tier3 = 44;
    uint256 boostLvl3Tier4 = 60;
    uint256 boostLvl3Tier5 = 87;
    uint256 boostLvl3Tier6 = 135;

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
        _fundUserWithfeeToken(stratosphereMemberBasic, boostFeeLvl1);
        assertEq(feeToken.balanceOf(stratosphereMemberBasic), boostFeeLvl1);

        (uint256 depositPointsTillNow, uint256 boostPointsTillNow) = diamondManagerFacet.getUserPoints(
            stratosphereMemberBasic,
            1
        );

        vm.warp(block.timestamp + 3 days);
        uint256 expectedTotalPoints = depositPointsTillNow + _calculatePoints(depositPointsTillNow, boostLvl1Tier1);
        boostFacet.claimBoost(1);
        uint256 lastBoostClaimedAmount = diamondManagerFacet.getUserLastBoostClaimedAmount(stratosphereMemberBasic, 1);
        assertEq(depositPointsTillNow + lastBoostClaimedAmount, expectedTotalPoints);
        assertEq(feeToken.balanceOf(stratosphereMemberBasic), 0);
        assertEq(feeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_BoostWithStratSilverLvl1() public {
        vm.startPrank(stratosphereMemberSilver);
        _mintAndDeposit(stratosphereMemberSilver, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberSilver, boostFeeLvl1);
        assertEq(feeToken.balanceOf(stratosphereMemberSilver), boostFeeLvl1);

        (uint256 depositPointsTillNow, uint256 boostPointsTillNow) = diamondManagerFacet.getUserPoints(
            stratosphereMemberSilver,
            1
        );

        vm.warp(block.timestamp + 3 days);
        uint256 expectedTotalPoints = depositPointsTillNow + _calculatePoints(depositPointsTillNow, boostLvl1Tier2);

        boostFacet.claimBoost(1);

        uint256 lastBoostClaimedAmount = diamondManagerFacet.getUserLastBoostClaimedAmount(stratosphereMemberSilver, 1);
        assertEq(depositPointsTillNow + lastBoostClaimedAmount, expectedTotalPoints);
        assertEq(feeToken.balanceOf(stratosphereMemberSilver), 0);
        assertEq(feeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_BoostWithStratGoldLvl1() public {
        vm.startPrank(stratosphereMemberGold);
        _mintAndDeposit(stratosphereMemberGold, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberGold, boostFeeLvl1);
        assertEq(feeToken.balanceOf(stratosphereMemberGold), boostFeeLvl1);

        (uint256 depositPointsTillNow, uint256 boostPointsTillNow) = diamondManagerFacet.getUserPoints(
            stratosphereMemberGold,
            1
        );

        vm.warp(block.timestamp + 3 days);
        uint256 expectedTotalPoints = depositPointsTillNow + _calculatePoints(depositPointsTillNow, boostLvl1Tier3);

        boostFacet.claimBoost(1);
        uint256 lastBoostClaimedAmount = diamondManagerFacet.getUserLastBoostClaimedAmount(stratosphereMemberGold, 1);
        assertEq(depositPointsTillNow + lastBoostClaimedAmount, expectedTotalPoints);
        assertEq(feeToken.balanceOf(stratosphereMemberGold), 0);
        assertEq(feeToken.balanceOf(address(boostFacet)), boostFeeLvl1);
        vm.stopPrank();
    }

    function test_BoostWithStratBasicLvl2() public {
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        _fundUserWithBoostFeeToken(stratosphereMemberBasic, boostFeeLvl2);
        assertEq(feeToken.balanceOf(stratosphereMemberBasic), boostFeeLvl2);

        (uint256 depositPointsTillNow, uint256 boostPointsTillNow) = diamondManagerFacet.getUserPoints(
            stratosphereMemberBasic,
            1
        );
        vm.warp(block.timestamp + 3 days);
        uint256 expectedTotalPoints = depositPointsTillNow + _calculatePoints(depositPointsTillNow, boostLvl2Tier1);
        boostFacet.claimBoost(2);
        uint256 lastBoostClaimedAmount = diamondManagerFacet.getUserLastBoostClaimedAmount(stratosphereMemberBasic, 1);
        assertEq(depositPointsTillNow + lastBoostClaimedAmount, expectedTotalPoints);
        assertEq(feeToken.balanceOf(stratosphereMemberBasic), 0);
        assertEq(feeToken.balanceOf(address(boostFacet)), boostFeeLvl2);
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
        feeToken.mint(_addr, _amount);
        feeToken.increaseAllowance(address(boostFacet), _amount);
    }

    function _calculatePoints(uint256 depositPoints, uint256 _boostPercent) internal view returns (uint256) {
        if (_boostPercent == 0) {
            return 0;
        }

        uint256 seasonEndTimestamp = diamondManagerFacet.getSeasonEndTimestamp(1);

        uint256 blockTimestamp = block.timestamp;
        if (blockTimestamp > seasonEndTimestamp) {
            return 0;
        }
        uint256 _daysUntilSeasonEnd = (seasonEndTimestamp - blockTimestamp) / 1 days;

        if (_daysUntilSeasonEnd == 0) {
            return 0;
        }

        uint256 _pointsObtainedTillNow = depositPoints - (testDepositAmount * _daysUntilSeasonEnd);

        if (_pointsObtainedTillNow == 0) {
            return 0;
        }
        return LPercentages.percentage(_pointsObtainedTillNow, _boostPercent);
    }
}
