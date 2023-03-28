// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DiamondTest, LiquidMiningDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {RestakeFacet, RestakeFacet__InProgressSeason, RestakeFacet__HasWithdrawnOrRestaked} from "src/facets/RestakeFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {StratosphereMock} from "test/mocks/StratosphereMock.sol";
import "../../src/libraries/LPercentages.sol";

contract RestakeFacetTest is DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidMiningDiamond internal diamond;
    DepositFacet internal depositFacet;
    RestakeFacet internal restakeFacet;
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
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        depositFacet = DepositFacet(address(diamond));
        restakeFacet = RestakeFacet(address(diamond));

        // Set up season details for deposit
        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
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

    function _getAmountAfterFee(uint256 _amount, uint256 _discount, uint256 _fee) internal pure returns (uint256) {
        return _amount - LPercentages.percentage(_amount, _fee - (_discount * _fee) / 10000);
    }
}
