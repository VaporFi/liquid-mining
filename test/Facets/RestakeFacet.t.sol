// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {RestakeFacet, RestakeFacet__InProgressSeason, RestakeFacet__HasWithdrawnOrRestaked} from "src/facets/RestakeFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "src/mocks/ERC20Mock.sol";
import {RewardsControllerMock} from "src/mocks/RewardsControllerMock.sol";
import {StratosphereMock} from "src/mocks/StratosphereMock.sol";
import "../../src/libraries/LPercentages.sol";

contract RestakeFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    RestakeFacet internal restakeFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    ERC20Mock internal depositToken;
    StratosphereMock stratosphereMock;
    RewardsControllerMock rewardsControllerMock;

    address FeeReceiver1 = makeAddr("FeeReceiver1");
    address FeeReceiver2 = makeAddr("FeeReceiver2");
    address diamondOwner = makeAddr("diamondOwner");
    address user = makeAddr("user");
    address stratosphereMemberBasicTierAddress = makeAddr("stratosphere_member_basic");
    address stratosphereMemberSilverTierAddress = makeAddr("stratosphere_member_silver");
    address stratosphereMemberGoldTierAddress = makeAddr("stratosphere_member_gold");
    

    function setUp() public {
        vm.startPrank(diamondOwner);

        diamond = createDiamond();
        depositFacet = new DepositFacet();
        restakeFacet = new RestakeFacet();
        diamondManagerFacet = new DiamondManagerFacet();

        // Deposit Facet Setup
        bytes4[] memory depositFunctionSelectors = new bytes4[](1);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;
        addFacet(diamond, address(depositFacet), depositFunctionSelectors);

        // Restake Facet Setup
        bytes4[] memory restakeFunctionSelectors = new bytes4[](1);
        restakeFunctionSelectors[0] = restakeFacet.restake.selector;
        addFacet(diamond, address(restakeFacet), restakeFunctionSelectors);

        // Diamond Manager Facet Setup
        bytes4[] memory managerFunctionSelectors = new bytes4[](18);
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
        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        // Initializers
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        depositToken = new ERC20Mock("Vapor nodes", "VPND");
        diamondManagerFacet.setDepositToken(address(depositToken));
        depositFacet = DepositFacet(address(diamond));
        restakeFacet = RestakeFacet(address(diamond));
        stratosphereMock = new StratosphereMock();
        rewardsControllerMock = new RewardsControllerMock();

        vm.stopPrank();


        // Set up season details for deposit
        vm.startPrank(diamondOwner);
        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = FeeReceiver1;
        depositFeeReceivers[1] = FeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);


        // Restake Setup
        diamondManagerFacet.setRestakeFee(300);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(3, 650);
        vm.stopPrank();


        // Deposit for the current season
        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 5000 * 1e18);
        depositToken.mint(user, 5000 * 1e18);
        depositFacet.deposit(5000 * 1e18);
        vm.stopPrank();
        
        // Set up season details for restake
        vm.startPrank(diamondOwner);
        vm.warp(block.timestamp + 31 days);
        diamondManagerFacet.setCurrentSeasonId(2);
        diamondManagerFacet.setSeasonEndTimestamp(2, block.timestamp + 30 days);
        vm.stopPrank();
    }


    function test_DepositAndRestakeWithoutBeingStratosphereMember() public {
        
        vm.startPrank(user);
        uint256 depositAmount = 5000 * 1e18;
        uint256 amountAfterDepositFee = depositAmount - (depositAmount * 500 / 10000);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), amountAfterDepositFee);
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 2);
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(1));
        restakeFacet.restake();
        uint256 amountAfterRestakeFee = diamondManagerFacet.getDepositAmountOfUser(user, 1) - (diamondManagerFacet.getDepositAmountOfUser(user, 1) * 300 / 10000);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 2), amountAfterRestakeFee);
        assertEq(diamondManagerFacet.getWithdrawRestakeStatus(user, 1), true);
        vm.stopPrank();

    }

    function test_CannotRestakeTwiceForTheSameSeason() public {

        vm.startPrank(user);
        restakeFacet.restake();
        assertEq(diamondManagerFacet.getWithdrawRestakeStatus(user, 1), true); 
        vm.expectRevert(RestakeFacet__InProgressSeason.selector);
        restakeFacet.restake();
    }

    function test_DepositAndRestakeBeingStratosphereMemberTierBasic() public {
        
       // Deposit for the current season
        vm.startPrank(stratosphereMemberBasicTierAddress);
        uint256 depositAmount = 5000 * 1e18;
        uint256 depositFee = 500;
        uint256 depositDiscountForBasicTierMember = 500;
        uint256 depositAmountAfterFee = depositAmount - LPercentages.percentage(depositAmount, depositFee - (depositDiscountForBasicTierMember * depositFee) / 10000);
        depositToken.increaseAllowance(address(depositFacet), depositAmount);
        depositToken.mint(stratosphereMemberBasicTierAddress, depositAmount);
        depositFacet.deposit(depositAmount);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasicTierAddress, 2), depositAmountAfterFee);
        vm.stopPrank();

        // Set a new season
        vm.startPrank(diamondOwner);
        vm.warp(block.timestamp + 31 days);
        diamondManagerFacet.setCurrentSeasonId(3);
        diamondManagerFacet.setSeasonEndTimestamp(3, block.timestamp + 30 days);
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(2));
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 3);
        vm.stopPrank();

        // Restake for the new season
        vm.startPrank(stratosphereMemberBasicTierAddress);
        uint256 restakeAmount = diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasicTierAddress, 2);
        uint256 restakeFee = 300;
        uint256 restakeDiscountForBasicTierMember = 500;
        uint256 restakeAmountAfterFee = restakeAmount - LPercentages.percentage(restakeAmount, restakeFee - (restakeDiscountForBasicTierMember * restakeFee) / 10000);
        restakeFacet.restake();
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasicTierAddress, 3), restakeAmountAfterFee);
        vm.stopPrank();

    }

    function test_DepositAndRestakeBeingStratosphereMemberTierSilver() public {

        
        // Deposit for the current season
        vm.startPrank(stratosphereMemberSilverTierAddress);
        uint256 depositAmount = 5000 * 1e18;
        uint256 depositFee = 500;
        uint256 depositDiscountForSilverTierMember = 550;
        uint256 depositAmountAfterFee = depositAmount - LPercentages.percentage(depositAmount, depositFee - (depositDiscountForSilverTierMember * depositFee) / 10000);
        depositToken.increaseAllowance(address(depositFacet), depositAmount);
        depositToken.mint(stratosphereMemberSilverTierAddress, depositAmount);
        depositFacet.deposit(depositAmount);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberSilverTierAddress, 2), depositAmountAfterFee);
        vm.stopPrank();

        // Set a new season
        vm.startPrank(diamondOwner);
        vm.warp(block.timestamp + 31 days);
        diamondManagerFacet.setCurrentSeasonId(3);
        diamondManagerFacet.setSeasonEndTimestamp(3, block.timestamp + 30 days);
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(2));
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 3);
        vm.stopPrank();

        // Restake for the new season
        vm.startPrank(stratosphereMemberSilverTierAddress);
        uint256 restakeAmount = diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberSilverTierAddress, 2);
        uint256 restakeFee = 300;
        uint256 restakeDiscountForSilverTierMember = 550;
        uint256 restakeAmountAfterFee = restakeAmount - LPercentages.percentage(restakeAmount, restakeFee - (restakeDiscountForSilverTierMember * restakeFee) / 10000);
        restakeFacet.restake();
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberSilverTierAddress, 3), restakeAmountAfterFee);
        vm.stopPrank();

    }

    function test_DepositAndRestakeBeingStratosphereMemberTierGold() public {
        
        // Deposit for the current season
        vm.startPrank(stratosphereMemberGoldTierAddress);
        uint256 depositAmount = 5000 * 1e18;
        uint256 depositFee = 500;
        uint256 depositDiscountForGoldTierMember = 650;
        uint256 depositAmountAfterFee = depositAmount - LPercentages.percentage(depositAmount, depositFee - (depositDiscountForGoldTierMember * depositFee) / 10000);
        depositToken.increaseAllowance(address(depositFacet), depositAmount);
        depositToken.mint(stratosphereMemberGoldTierAddress, depositAmount);
        depositFacet.deposit(depositAmount);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGoldTierAddress, 2), depositAmountAfterFee);
        vm.stopPrank();

        // Set a new season
        vm.startPrank(diamondOwner);
        vm.warp(block.timestamp + 31 days);
        diamondManagerFacet.setCurrentSeasonId(3);
        diamondManagerFacet.setSeasonEndTimestamp(3, block.timestamp + 30 days);
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(2));
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 3);
        vm.stopPrank();

        // Restake for the new season
        vm.startPrank(stratosphereMemberGoldTierAddress);
        uint256 restakeAmount = diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGoldTierAddress, 2);
        uint256 restakeFee = 300;
        uint256 restakeDiscountForGoldTierMember = 650;
        uint256 restakeAmountAfterFee = restakeAmount - LPercentages.percentage(restakeAmount, restakeFee - (restakeDiscountForGoldTierMember * restakeFee) / 10000);
        restakeFacet.restake();
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGoldTierAddress, 3), restakeAmountAfterFee);
        vm.stopPrank();

    }

    
}
