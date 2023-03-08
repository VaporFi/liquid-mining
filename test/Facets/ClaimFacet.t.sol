// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__InvalidSeason, ClaimFacet__AlreadyClaimed} from "src/facets/ClaimFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "src/mocks/ERC20Mock.sol";
import {RewardsControllerMock} from "src/mocks/RewardsControllerMock.sol";
import {StratosphereMock} from "src/mocks/StratosphereMock.sol";
import "../../src/libraries/LPercentages.sol";

contract RestakeFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    ClaimFacet internal claimFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    ERC20Mock internal depositToken;
    ERC20Mock internal rewardToken;
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

    function setUp() public {
        vm.startPrank(diamondOwner);

        diamond = createDiamond();
        depositFacet = new DepositFacet();
        claimFacet = new ClaimFacet();
        diamondManagerFacet = new DiamondManagerFacet();

        // Deposit Facet Setup
        bytes4[] memory depositFunctionSelectors = new bytes4[](1);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;
        addFacet(diamond, address(depositFacet), depositFunctionSelectors);

        // Restake Facet Setup
        bytes4[] memory claimFunctionSelectors = new bytes4[](1);
        claimFunctionSelectors[0] = claimFacet.claim.selector;
        addFacet(diamond, address(claimFacet), claimFunctionSelectors);

        // Diamond Manager Facet Setup
        bytes4[] memory managerFunctionSelectors = new bytes4[](21);
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
        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        // Initializers
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        depositToken = new ERC20Mock("Vapor nodes", "VPND");
        rewardToken = new ERC20Mock("VAPE Token", "VAPE");
        diamondManagerFacet.setDepositToken(address(depositToken));
        depositFacet = DepositFacet(address(diamond));
        claimFacet = ClaimFacet(address(diamond));
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
        vm.stopPrank();

        // Deposit for the current season
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.stopPrank();

    }

    function test_claimRewards() public {

        // Set up season for restake
        vm.startPrank(user);
        vm.warp(block.timestamp + 31 days);
        claimFacet.claim();
        assertEq(rewardToken.balanceOf(user), rewardTokenToDistribute);
        vm.stopPrank();

       
    }

    // Helper functions

    function _mintAndDeposit(address _addr, uint256 _amount) internal {
        depositToken.increaseAllowance(address(depositFacet), _amount);
        depositToken.mint(_addr, _amount);
        depositFacet.deposit(_amount);
    }

}
