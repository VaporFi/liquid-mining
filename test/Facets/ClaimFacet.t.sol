// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded } from "src/facets/DepositFacet.sol";
import { ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__AlreadyClaimed } from "src/facets/ClaimFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { AuthorizationFacet } from "src/facets/AuthorizationFacet.sol";
import { ERC20Mock } from "test/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/mocks/StratosphereMock.sol";
import "../../src/libraries/LPercentages.sol";

contract ClaimFacetTest is DiamondTest {
    // StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    LiquidMiningDiamond internal diamond;
    DepositFacet internal depositFacet;
    ClaimFacet internal claimFacet;
    DiamondManagerFacet internal diamondManagerFacet;
    AuthorizationFacet internal authorizationFacet;

    // setup addresses
    address feeReceiver1 = makeAddr("FeeReceiver1");
    address feeReceiver2 = makeAddr("FeeReceiver2");
    address diamondOwner = makeAddr("diamondOwner");
    address user = makeAddr("user");
    address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");
    address stratosphereMemberSilver = makeAddr("stratosphereMemberSilver");
    address stratosphereMemberGold = makeAddr("stratosphereMemberGold");
    address oracle = makeAddr("oracle");
    // setup test details
    uint256 rewardTokenToDistribute = 10000 * 1e18;
    uint256 testDepositAmount = 5000 * 1e18;

    function setUp() public {
        vm.startPrank(diamondOwner);

        diamond = createDiamond();
        depositFacet = DepositFacet(address(diamond));
        claimFacet = ClaimFacet(address(diamond));
        diamondManagerFacet = DiamondManagerFacet(address(diamond));
        authorizationFacet = AuthorizationFacet(address(diamond));

        // Set up season details for deposit
        rewardToken.mint(address(diamond), rewardTokenToDistribute);
        diamondManagerFacet.setRewardToken(address(rewardToken));
        diamondManagerFacet.startNewSeason(rewardTokenToDistribute);

        // Authoriza oracle for automated claims
        authorizationFacet.authorize(oracle);

        vm.stopPrank();
    }

  
    function test_automatedClaim() public {
        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.warp(block.timestamp + 31 days);
        assertEq(diamondManagerFacet.getUserClaimedRewards(user, 1), 0);
        vm.stopPrank();

        vm.startPrank(oracle);
        address[] memory users = new address[](1);
        users[0] = user;
        claimFacet.automatedClaim(1, users);
        assertEq(diamondManagerFacet.getUserClaimedRewards(user, 1), rewardTokenToDistribute);
        vm.stopPrank();
    }

    // Helper functions

    function _mintAndDeposit(address _addr, uint256 _amount) internal {
        depositToken.increaseAllowance(address(depositFacet), _amount);
        depositToken.mint(_addr, _amount);
        depositFacet.deposit(_amount);
    }

    function _calculateShare(address _addr, uint256 _seasonId) internal view returns (uint256) {
        uint256 seasonTotalPoints = diamondManagerFacet.getSeasonTotalPoints(_seasonId);
        uint256 userTotalPoints = diamondManagerFacet.getUserTotalPoints(1, _addr);
        uint256 userShare = (userTotalPoints * 1e18) / seasonTotalPoints;
        return _vapeToDistribute(userShare);
    }

    function _vapeToDistribute(uint256 _userShare) internal view returns (uint256) {
        return (rewardTokenToDistribute * _userShare) / 1e18;
    }
}
