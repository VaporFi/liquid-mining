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

    // setup addresses
    address feeReceiver1 = makeAddr("FeeReceiver1");
    address feeReceiver2 = makeAddr("FeeReceiver2");
    address diamondOwner = makeAddr("diamondOwner");
    address user = makeAddr("user");
    address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");
    address stratosphereMemberSilver = makeAddr("stratosphereMemberSilver");
    address stratosphereMemberGold = makeAddr("stratosphereMemberGold");
    // setup test details
    uint256 testDepositAmount = 5000 * 1e18;
    uint256 depositFee = 500;
    uint256 depositDiscountBasic = 500;
    uint256 depositDiscountSilver = 550;
    uint256 depositDiscountGold = 650;
    uint256 restakeFee = 300;
    uint256 restakeDiscountBasic = 500;
    uint256 restakeDiscountSilver = 550;
    uint256 restakeDiscountGold = 650;

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

        // Set up season details for deposit

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
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

        // Restake Setup
        diamondManagerFacet.setRestakeFee(restakeFee);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(1, restakeDiscountBasic);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(2, restakeDiscountSilver);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(3, restakeDiscountGold);
        vm.stopPrank();

        // Deposit for the current season
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.stopPrank();

        // Set up season for restake
        vm.startPrank(diamondOwner);
        _startNewSeason();
        vm.stopPrank();
    }

    function test_DepositAndRestakeWithoutBeingStratosphereMember() public {
        vm.startPrank(user);
        uint256 amountAfterDepositFee = testDepositAmount - ((testDepositAmount * depositFee) / 10000);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), amountAfterDepositFee);
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 2);
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(1));
        restakeFacet.restake();
        uint256 amountAfterRestakeFee = diamondManagerFacet.getDepositAmountOfUser(user, 1) -
            ((diamondManagerFacet.getDepositAmountOfUser(user, 1) * restakeFee) / 10000);
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
        vm.startPrank(stratosphereMemberBasic);
        _mintAndDeposit(stratosphereMemberBasic, testDepositAmount);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountBasic, depositFee);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 2), depositAmountAfterFee);
        vm.stopPrank();

        // Set a new season
        vm.startPrank(diamondOwner);
        _startNewSeason();
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(2));
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 3);
        vm.stopPrank();

        // Restake for the new season
        vm.startPrank(stratosphereMemberBasic);
        uint256 restakeAmount = diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 2);
        uint256 restakeAmountAfterFee = _getAmountAfterFee(restakeAmount, restakeDiscountBasic, restakeFee);
        restakeFacet.restake();
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberBasic, 3), restakeAmountAfterFee);
        vm.stopPrank();
    }

    function test_DepositAndRestakeBeingStratosphereMemberTierSilver() public {
        // Deposit for the current season
        vm.startPrank(stratosphereMemberSilver);
        _mintAndDeposit(stratosphereMemberSilver, testDepositAmount);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountSilver, depositFee);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberSilver, 2), depositAmountAfterFee);
        vm.stopPrank();

        // Set a new season
        vm.startPrank(diamondOwner);
        _startNewSeason();
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(2));
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 3);
        vm.stopPrank();

        // Restake for the new season
        vm.startPrank(stratosphereMemberSilver);
        uint256 restakeAmount = diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberSilver, 2);
        uint256 restakeAmountAfterFee = _getAmountAfterFee(restakeAmount, restakeDiscountSilver, restakeFee);
        restakeFacet.restake();
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberSilver, 3), restakeAmountAfterFee);
        vm.stopPrank();
    }

    function test_DepositAndRestakeBeingStratosphereMemberTierGold() public {
        // Deposit for the current season
        vm.startPrank(stratosphereMemberGold);
        _mintAndDeposit(stratosphereMemberGold, testDepositAmount);
        uint256 depositAmountAfterFee = _getAmountAfterFee(testDepositAmount, depositDiscountGold, depositFee);
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGold, 2), depositAmountAfterFee);
        vm.stopPrank();

        // Set a new season
        vm.startPrank(diamondOwner);
        _startNewSeason();
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(2));
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 3);
        vm.stopPrank();

        // Restake for the new season
        vm.startPrank(stratosphereMemberGold);
        uint256 restakeAmount = diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGold, 2);
        uint256 restakeAmountAfterFee = _getAmountAfterFee(restakeAmount, restakeDiscountGold, restakeFee);
        restakeFacet.restake();
        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratosphereMemberGold, 3), restakeAmountAfterFee);
        vm.stopPrank();
    }

    // Helper functions

    function _mintAndDeposit(address _addr, uint256 _amount) internal {
        depositToken.increaseAllowance(address(depositFacet), _amount);
        depositToken.mint(_addr, _amount);
        depositFacet.deposit(_amount);
    }

    function _startNewSeason() internal {
        vm.warp(block.timestamp + 31 days);
        uint256 newSeasonId = diamondManagerFacet.getCurrentSeasonId() + 1;
        diamondManagerFacet.setCurrentSeasonId(newSeasonId);
        diamondManagerFacet.setSeasonEndTimestamp(newSeasonId, block.timestamp + 30 days);
    }

    function _getAmountAfterFee(uint256 _amount, uint256 _discount, uint256 _fee) internal view returns (uint256) {
        return _amount - LPercentages.percentage(_amount, _fee - (_discount * _fee) / 10000);
    }
}
