// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";

/// @title BoostFacet
/// @notice Facet in charge of point's boosts
/// @dev Utilizes 'LDiamond', 'AppStorage'
contract BoostFacet {
    error BoostFacet__BoostAlreadyClaimed();

    event ClaimBoost(address indexed _user, uint256 _seasonId, uint256 _boostPoints);

    AppStorage s;

    /// @notice Claim daily boost points
    function claimBoost() external {
        uint256 _seasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        if (_userData.lastBoostClaimTimestamp != 0 && block.timestamp - _userData.lastBoostClaimTimestamp < 1 days) {
            revert BoostFacet__BoostAlreadyClaimed();
        }
        // TODO: add Stratosphere boost points
        _userData.boostPoints += _calculatePoints(_userData);
        emit ClaimBoost(msg.sender, _seasonId, _userData.boostPoints);
    }

    /// @notice Calculate boost points
    /// @param _userData User data
    /// @return Boost points
    /// @dev Utilizes 'LPercentages'.
    /// @dev _daysSinceSeasonStart starts from 0 equal to the first day of the season.
    function _calculatePoints(UserData memory _userData) internal view returns (uint256) {
        uint256 _daysSinceSeasonStart = (block.timestamp - s.seasons[s.currentSeasonId].startTimestamp) / 1 days;
        if (_daysSinceSeasonStart == 0) {
            return LPercentages.percentage(_userData.depositAmount, 2500); // 25%
        } else if (_daysSinceSeasonStart == 1) {
            return LPercentages.percentage(_userData.depositAmount, 2000); // 20%
        } else if (_daysSinceSeasonStart == 2) {
            return LPercentages.percentage(_userData.depositAmount, 1200); // 12%
        } else if (_daysSinceSeasonStart == 3) {
            return LPercentages.percentage(_userData.depositAmount, 600); // 6%
        } else if (_daysSinceSeasonStart == 4) {
            return LPercentages.percentage(_userData.depositAmount, 240); // 2.4%
        } else if (_daysSinceSeasonStart == 5) {
            return LPercentages.percentage(_userData.depositAmount, 70); // 0.7%
        } else if (_daysSinceSeasonStart == 6) {
            return LPercentages.percentage(_userData.depositAmount, 10); // 0.1%
        } else {
            return 0;
        }
    }
}
