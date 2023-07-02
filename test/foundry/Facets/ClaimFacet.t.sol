// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { DepositFacet, DepositFacet__NotEnoughTokenBalance, DepositFacet__SeasonEnded } from "src/facets/DepositFacet.sol";
import { ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__AlreadyClaimed } from "src/facets/ClaimFacet.sol";
import { DiamondManagerFacet } from "src/facets/DiamondManagerFacet.sol";
import { AuthorizationFacet } from "src/facets/AuthorizationFacet.sol";
import { ERC20Mock } from "test/foundry/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/foundry/mocks/StratosphereMock.sol";
import { LPercentages } from "src/libraries/LPercentages.sol";

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

        // Set up reward token
        diamondManagerFacet.setRewardToken(address(rewardToken));
        // Authorize oracle for automated claims
        authorizationFacet.authorize(oracle);

        vm.stopPrank();
    }

    function test_automatedClaim() public {
        console.log(type(uint8).max);
        _startSeason();

        vm.startPrank(user);
        _mintAndDeposit(user, testDepositAmount);
        vm.stopPrank();

        (uint256 _depositAmount, ) = diamondManagerFacet.getUserDepositAmount(user, 1);
        assertEq(_depositAmount, (testDepositAmount));

        vm.warp(block.timestamp + 26 days);
        assertEq(diamondManagerFacet.getUserClaimedRewards(user, 1), 0);

        address[] memory users = new address[](1);
        users[0] = user;

        vm.startPrank(oracle);
        claimFacet.automatedClaimBatch(1, users);
        vm.stopPrank();

        assertEq(diamondManagerFacet.getUserClaimedRewards(user, 1), rewardTokenToDistribute);
    }

    // function test_automatedClaim_MultipleSeasons() public {
    //     uint8 _seasonAmount = 3;
    //     uint16 _userAmount = 100;

    //     for (uint8 i = 1; i < _seasonAmount; i++) {
    //         console.log("Season: %s", i);
    //         _startSeason();
    //         address[] memory users = _mintAndDepositForUsers(_userAmount);
    //         vm.warp(block.timestamp + 26 days);
    //         _automatedClaimFromOracle(i, users);
    //     }
    // }

    // Helper functions

    function _startSeason() internal {
        vm.startPrank(diamondOwner);
        rewardToken.mint(address(diamond), rewardTokenToDistribute);
        diamondManagerFacet.startNewSeason(rewardTokenToDistribute);
        vm.stopPrank();
    }

    function _automatedClaimFromOracle(uint256 _seasonId, address[] memory _users) internal {
        vm.startPrank(oracle);

        if (_users.length <= 100) {
            claimFacet.automatedClaimBatch(_seasonId, _users);
            return;
        } else {
            // Chunk users into 100 user batches
            for (uint256 i = 0; i < _users.length; i += 100) {
                uint256 chunkSize = _users.length - i < 100 ? _users.length - i : 100;
                address[] memory chunk = new address[](chunkSize);
                for (uint256 j = 0; j < chunkSize; j++) {
                    chunk[j] = _users[i + j];
                }
                claimFacet.automatedClaimBatch(_seasonId, chunk);
            }
        }

        vm.stopPrank();
    }

    function _mintAndDepositForUsers(uint256 _usersAmount) internal returns (address[] memory) {
        address[] memory users = new address[](_usersAmount);
        console.log("Users: %s", _usersAmount);
        for (uint256 i = 0; i < _usersAmount; i++) {
            // address _user = makeAddr(string(abi.encodePacked("user", i)));
            address _user = vm.addr(i + 1);
            console.log("User: %s", _user);
            vm.startPrank(_user);
            _mintAndDeposit(_user, testDepositAmount);
            vm.stopPrank();

            users[i] = user;
        }

        return users;
    }

    function _mintAndDeposit(address _addr, uint256 _amount) internal {
        depositToken.mint(_addr, _amount);
        depositToken.increaseAllowance(address(depositFacet), _amount);
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
