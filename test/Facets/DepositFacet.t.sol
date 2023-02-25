// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";
import {DiamondTest, LiquidStakingDiamond} from "../utils/DiamondTest.sol";
import {DepositFacet, DepositFacet__NotEnoughTokenBalance} from "src/facets/DepositFacet.sol";
import {DiamondManagerFacet} from "src/facets/DiamondManagerFacet.sol";
import {TestManagerFacet} from "src/facets/TestManagerFacet.sol";
import "../mocks/ERC20.sol";

contract DepositFacetTest is Test, DiamondTest {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidStakingDiamond internal diamond;
    DepositFacet internal depositFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    TestManagerFacet internal testManagerFacet;
    MockERC20 vpnd;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);
    address david = address(4);
    address eve = address(5);
    address frank = address(6);
    address grace = address(7);
    address heidi = address(8);
    address ivan = address(9);
    address judy = address(10);
    address karen = address(11);

    function setUp() public {

        vpnd = new MockERC20("MockVPND", "mVPND", 18, 10000000 * 1e18);
        vpnd.transfer(alice, 1_000_000 * 1e18);
        // vpnd.transfer(bob, 1_000_000 * 1e18);
        // vpnd.transfer(charlie, 1_000_000 * 1e18);
        // vpnd.transfer(david, 1_000_000 * 1e18);
        // vpnd.transfer(eve, 1_000_000 * 1e18);
        // vpnd.transfer(frank, 1_000_000 * 1e18);
        // vpnd.transfer(grace, 1_000_000 * 1e18);
        // vpnd.transfer(heidi, 1_000_000 * 1e18);
        // vpnd.transfer(ivan, 1_000_000 * 1e18);
        // vpnd.transfer(judy, 1_000_000 * 1e18);

        diamond = createDiamond();
        depositFacet = new DepositFacet();
        diamondManagerFacet = new DiamondManagerFacet();

        bytes4[] memory managerFunctionSelectors = new bytes4[](9);
        managerFunctionSelectors[0] = diamondManagerFacet.setDepositToken.selector;
        managerFunctionSelectors[1] = diamondManagerFacet.setCurrentSeasonId.selector;
        managerFunctionSelectors[2] = diamondManagerFacet.setDepositDiscountForStratosphereMember.selector;
        managerFunctionSelectors[3] = diamondManagerFacet.setDepositFee.selector;
        managerFunctionSelectors[4] = diamondManagerFacet.setStratosphereAddress.selector;
        managerFunctionSelectors[5] = diamondManagerFacet.setRewardsControllerAddress.selector;
        managerFunctionSelectors[6] = diamondManagerFacet.setSeasonEndTimestamp.selector;
        managerFunctionSelectors[7] = diamondManagerFacet.setDepositFeeReceivers.selector;
        managerFunctionSelectors[8] = diamondManagerFacet.getDepositToken.selector;
        addFacet(diamond, address(diamondManagerFacet), managerFunctionSelectors);

        bytes4[] memory depositFunctionSelectors = new bytes4[](2);
        depositFunctionSelectors[0] = depositFacet.deposit.selector;
        depositFunctionSelectors[1] = depositFacet.getSDepositToken.selector;
        addFacet(diamond, address(depositFacet), depositFunctionSelectors);

        bytes4[] memory testManagerFunctionSelectors = new bytes4[](1);
        testManagerFunctionSelectors[0] = testManagerFacet.getDepositToken.selector;
        addFacet(diamond, address(testManagerFacet), testManagerFunctionSelectors);

        diamondManagerFacet = DiamondManagerFacet(address(diamond));

        diamondManagerFacet.setDepositToken(address(vpnd));

        depositFacet = DepositFacet(address(diamond));
    }

    // function test_RevertIfDepositorDoesNotHaveEnoughBalance() public {
    //     vm.startPrank(makeAddr("user"));
    //     // // vm.expectRevert(DepositFacet__NotEnoughTokenBalance.selector);
    //     vm.expectRevert();
    //     depositFacet.deposit(100);
    // }

    function test_DepositToken() public {
        vm.startPrank(alice);
        address token = diamondManagerFacet.getDepositToken();
        assertEq(token, address(vpnd));
    }

    // function test_TestManagerState() public {
    //     vm.startPrank(alice);
    //     address token = testManagerFacet.getDepositToken();
    //     address token2 = diamondManagerFacet.getDepositToken();
    //     assertEq(token, token2);
    // }

    
}
