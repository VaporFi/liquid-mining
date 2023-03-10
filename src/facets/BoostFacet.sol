// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../interfaces/IRewardsController.sol";

error BoostFacet__InvalidBoostLevel();
error BoostFacet__BoostAlreadyClaimed();

/// @title BoostFacet
/// @notice Facet in charge of point's boosts
/// @dev Utilizes 'LDiamond', 'AppStorage'
contract BoostFacet {
    event ClaimBoost(address indexed _user, uint256 _seasonId, uint256 _boostPoints);

    AppStorage s;

    /// @notice Claim daily boost points
    function claimBoost(uint256 boostLevel) external {
        uint256 _seasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        if (_userData.lastBoostClaimTimestamp != 0 && block.timestamp - _userData.lastBoostClaimTimestamp < 1 days) {
            revert BoostFacet__BoostAlreadyClaimed();
        }
        uint256 _boostFee = 0;
        (bool isStratosphereMember, uint256 tier) = getStratosphereMembershipDetails(msg.sender);
        if (!isStratosphereMember && boostLevel > 0) {
            revert BoostFacet__InvalidBoostLevel();
        }
        if (isStratosphereMember) {
            _boostFee = s.boostLevelToFee[boostLevel];
        }
        if (_boostFee > 0) {
            IERC20(s.boostFeeToken).transferFrom(msg.sender, address(this), _boostFee);
        }
        _userData.lastBoostClaimTimestamp = block.timestamp;
        _userData.boostPoints += _calculatePoints(_userData, boostLevel, tier);
        emit ClaimBoost(msg.sender, _seasonId, _userData.boostPoints);
    }

    /// @notice Calculate boost points
    /// @param _userData User data
    /// @return Boost points
    /// @dev Utilizes 'LPercentages'.
    /// @dev _daysSinceSeasonStart starts from 0 equal to the first day of the season.
    function _calculatePoints(
        UserData storage _userData,
        uint256 _boostLevel,
        uint256 _tier
    ) internal view returns (uint256) {
        uint256 _boostPointsAmount = s.boostPercentFromTierToLevel[_tier][_boostLevel];
        if (_boostPointsAmount == 0) {
            return 0;
        }
        return LPercentages.percentage(_userData.depositAmount, _boostPointsAmount);
    }

    /// @notice get details of stratosphere for member
    /// @param _account Account of member to check
    /// @return bool if account is stratosphere member
    /// @return uint256 tier of membership
    function getStratosphereMembershipDetails(address _account) private view returns (bool, uint256) {
        IStratosphere stratosphere = IStratosphere(s.stratoshpereAddress);
        uint256 tokenId = stratosphere.tokenIdOf(_account);

        if (tokenId == 0) {
            return (false, 0);
        } else {
            IRewardsController rewardController = IRewardsController(s.rewardsControllerAddress);
            uint256 tier = rewardController.tierOf(keccak256("STRATOSPHERE_PROGRAM"), tokenId);
            return (true, tier);
        }
    }
}
