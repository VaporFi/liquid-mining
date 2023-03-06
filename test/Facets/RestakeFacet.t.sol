// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded, DepositFacet__InvalidFeeReceivers} from "src/facets/DepositFacet.sol";
import {RestakeFacet, RestakeFacet__InProgressSeason, RestakeFacet__HasWithdrawnOrRestaked} from "src/facets/RestakeFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {ERC20Mock} from "src/mocks/ERC20Mock.sol";
import {RewardsControllerMock} from "src/mocks/RewardsControllerMock.sol";
import {StratosphereMock} from "src/mocks/StratosphereMock.sol";

contract RestakeFacetTest is Test, DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    RestakeFacet internal restakeFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    ERC20Mock internal depositToken;
    address depositFeeReceiver1 = makeAddr("depositFeeReceiver1");
    address depositFeeReceiver2 = makeAddr("depositFeeReceiver2");
    address restakeFeeReceiver1 = makeAddr("restakeFeeReceiver1");
    address restakeFeeReceiver2 = makeAddr("restakeFeeReceiver2");
    address diamondOwner = makeAddr("diamondOwner");
    address user = makeAddr("user");
    StratosphereMock stratosphereMock;
    RewardsControllerMock rewardsControllerMock;

    function setUp() public {
        vm.startPrank(diamondOwner);

        diamond = createDiamond();
        depositFacet = new DepositFacet();
        restakeFacet = new RestakeFacet();
        diamondManagerFacet = new DiamondManagerFacet();

        
        bytes4[] memory depositFunctionSelectors = new bytes4[](1);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;

        addFacet(diamond, address(depositFacet), depositFunctionSelectors);

        bytes4[] memory restakeFunctionSelectors = new bytes4[](1);
        restakeFunctionSelectors[0] = restakeFacet.restake.selector;
        addFacet(diamond, address(restakeFacet), restakeFunctionSelectors);


        bytes4[] memory managerFunctionSelectors = new bytes4[](19);
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
        managerFunctionSelectors[15] = diamondManagerFacet.setRestakeFeeReceivers.selector;
        managerFunctionSelectors[16] = diamondManagerFacet.getCurrentSeasonId.selector;
        managerFunctionSelectors[17] = diamondManagerFacet.getSeasonEndTimestamp.selector;
        managerFunctionSelectors[18] = diamondManagerFacet.getWithdrawRestakeStatus.selector;
        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        depositToken = new ERC20Mock("Vapor nodes", "VPND");

        diamondManagerFacet.setDepositToken(address(depositToken));

        depositFacet = DepositFacet(address(diamond));

        restakeFacet = RestakeFacet(address(diamond));

        stratosphereMock = new StratosphereMock();
        rewardsControllerMock = new RewardsControllerMock();

        vm.stopPrank();

        vm.startPrank(makeAddr("diamondOwner"));

        diamondManagerFacet.setCurrentSeasonId(1);
        diamondManagerFacet.setDepositFee(500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setDepositDiscountForStratosphereMember(3, 650);
        diamondManagerFacet.setSeasonEndTimestamp(1, block.timestamp + 30 days);
        diamondManagerFacet.setStratosphereAddress(address(stratosphereMock));
        diamondManagerFacet.setRewardsControllerAddress(address(rewardsControllerMock));
        address[] memory depositFeeReceivers = new address[](2);
        uint256[] memory depositFeeProportions = new uint256[](2);
        depositFeeReceivers[0] = depositFeeReceiver1;
        depositFeeReceivers[1] = depositFeeReceiver2;
        depositFeeProportions[0] = 7500;
        depositFeeProportions[1] = 2500;
        diamondManagerFacet.setDepositFeeReceivers(depositFeeReceivers, depositFeeProportions);


        // Restake Setup
        diamondManagerFacet.setRestakeFee(300);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(1, 500);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(2, 550);
        diamondManagerFacet.setRestakeDiscountForStratosphereMember(3, 650);
        address[] memory restakeFeeReceivers = new address[](2);
        uint256[] memory restakeFeeProportions = new uint256[](2);
        restakeFeeReceivers[0] = restakeFeeReceiver1;
        restakeFeeReceivers[1] = restakeFeeReceiver2;
        restakeFeeProportions[0] = 7500;
        restakeFeeProportions[1] = 2500;
        diamondManagerFacet.setRestakeFeeReceivers(restakeFeeReceivers, restakeFeeProportions);

         vm.stopPrank();

        // deposit and set a new season to test restake

        vm.startPrank(user);
        depositToken.increaseAllowance(address(depositFacet), 5000 * 10 ** 18);
        depositToken.mint(user, 5000 * 10 ** 18);
        depositFacet.deposit(5000 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(diamondOwner);
        vm.warp(block.timestamp + 31 days);

        diamondManagerFacet.setCurrentSeasonId(2);
        diamondManagerFacet.setSeasonEndTimestamp(2, block.timestamp + 30 days);
        
        vm.stopPrank();


       
    }

    function test_DepositAndRestakeWithoutBeingStratosphereMember() public {

        vm.startPrank(user);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(user, 1), 4750 * 10 ** 18);
        assertEq(diamondManagerFacet.getCurrentSeasonId(), 2);
        assertTrue(block.timestamp > diamondManagerFacet.getSeasonEndTimestamp(1));
        restakeFacet.restake();
        assertTrue(diamondManagerFacet.getDepositAmountOfUser(user, 2) > 4607);
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

    function test_DepositAndRestakeBeingStratosphereMember() public {
        address stratBasicMember = makeAddr("stratosphere_member_basic");

        vm.startPrank(stratBasicMember);
        depositToken.increaseAllowance(address(depositFacet), 1000000);
        depositToken.mint(stratBasicMember, 1000);

        depositFacet.deposit(1000);

        assertEq(diamondManagerFacet.getDepositAmountOfUser(stratBasicMember, 2), 953);

        vm.stopPrank();

        vm.startPrank(diamondOwner);

        vm.warp(block.timestamp + 31 days);

        diamondManagerFacet.setCurrentSeasonId(3);

        vm.stopPrank();

        vm.startPrank(stratBasicMember);

        assertEq(diamondManagerFacet.getCurrentSeasonId(), 3);

        restakeFacet.restake();


        // assertTrue(diamondManagerFacet.getDepositAmountOfUser(user, 3) > 924);

        vm.stopPrank();

        


    }

    
}
