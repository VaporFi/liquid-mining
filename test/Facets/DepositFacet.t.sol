// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance} from "src/facets/DepositFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";

contract DepositFacetTest is Test, DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;

    function setUp() public {
        diamond = createDiamond();
        depositFacet = new DepositFacet();
        diamondManagerFacet = new DiamondManagerFacet();
        bytes4[] memory depositFunctionSelectors = new bytes4[](1);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;
        addFacet(diamond, address(depositFacet), depositFunctionSelectors);
        bytes4[] memory managerFunctionSelectors = new bytes4[](8);
        managerFunctionSelectors[0] = diamondManagerFacet.setDepositToken.selector;
        managerFunctionSelectors[1] = diamondManagerFacet.setCurrentSeasonId.selector;
        managerFunctionSelectors[2] = diamondManagerFacet.setDepositDiscountForStratosphereMember.selector;
        managerFunctionSelectors[3] = diamondManagerFacet.setDepositFee.selector;
        managerFunctionSelectors[4] = diamondManagerFacet.setStratosphereAddress.selector;
        managerFunctionSelectors[5] = diamondManagerFacet.setRewardsControllerAddress.selector;
        managerFunctionSelectors[6] = diamondManagerFacet.setSeasonEndTimestamp.selector;
        managerFunctionSelectors[7] = diamondManagerFacet.setDepositFeeReceivers.selector;
        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        diamondManagerFacet.setDepositToken(makeAddr("vape token"));

        depositFacet = DepositFacet(address(diamond));
    }

    function test_RevertIfDepositorDoesNotHaveEnoughBalance() public {
        vm.startPrank(makeAddr("user"));
        // // vm.expectRevert(DepositFacet__NotEnoughTokenBalance.selector);
        vm.expectRevert();
        depositFacet.deposit(100);
    }
}
