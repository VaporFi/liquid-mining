// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../libraries/LStratosphere.sol";

error BoostFacet__InvalidBoostLevel();
error BoostFacet__BoostAlreadyClaimed();
error BoostFacet__UserNotParticipated();
error BoostFacet__InvalidFeeReceivers();

/// @title BoostFacet
/// @notice Facet in charge of point's boosts
/// @dev Utilizes 'LDiamond', 'AppStorage'
contract BoostFacet {

    /// @notice Ordering of the events are according to their relevance in the facet
    event ClaimBoost(
        uint256 indexed _seasonId,
        address indexed _user,
        uint256 boostLevel,
        uint256 _boostPoints,
        uint256 boostFee,
        uint256 tier
    );

    AppStorage s;

    /// @notice Claim daily boost points
    function claimBoost(uint256 boostLevel) external {
        uint256 _seasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        if (_userData.depositAmount == 0) {
            revert BoostFacet__UserNotParticipated();
        }
        if (_userData.lastBoostClaimTimestamp != 0 && block.timestamp - _userData.lastBoostClaimTimestamp < 1 days) {
            revert BoostFacet__BoostAlreadyClaimed();
        }
        uint256 _boostFee = 0;
        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (!isStratosphereMember && boostLevel > 0) {
            revert BoostFacet__InvalidBoostLevel();
        }
        if (isStratosphereMember) {
            _boostFee = s.boostLevelToFee[boostLevel];
        }
        _userData.lastBoostClaimTimestamp = block.timestamp;
        uint256 _boostPercent;
        if (isStratosphereMember) {
            _boostPercent = s.boostPercentFromTierToLevel[tier][boostLevel];
        } else {
            _boostPercent = s.boostForNonStratMembers;
        }
        uint256 _boostPointsAmount = _calculatePoints(_userData, _boostPercent, _seasonId);
        _userData.boostPoints += _boostPointsAmount;
        _userData.lastBoostClaimAmount = _boostPointsAmount;
        if (_boostFee > 0) {
            _applyBoostFee(_boostFee);
            IERC20(s.feeToken).transferFrom(msg.sender, address(this), _boostFee);
        }
        emit ClaimBoost(_seasonId, msg.sender, boostLevel, _boostPointsAmount, _boostFee, tier);
    }

    /// @notice Calculate boost points
    /// @param _userData User data
    /// @param _boostPercent % to boost points
    /// @param _seasonId current seasonId
    /// @return Boost points
    /// @dev Utilizes 'LPercentages'.
    /// @dev _daysSinceSeasonStart starts from 0 equal to the first day of the season.
    function _calculatePoints(
        UserData storage _userData,
        uint256 _boostPercent,
        uint256 _seasonId
    ) internal view returns (uint256) {
        if (_boostPercent == 0) {
            return 0;
        }

        Season storage _season = s.seasons[_seasonId];
        uint256 _daysUntilSeasonEnd = (_season.endTimestamp - block.timestamp) / 1 days;

        if (_daysUntilSeasonEnd == 0) {
            return 0;
        }

        uint256 _pointsObtainedTillNow = (_userData.depositPoints) - (_userData.depositAmount * _daysUntilSeasonEnd);

        if (_pointsObtainedTillNow == 0) {
            return 0;
        }
        return LPercentages.percentage(_pointsObtainedTillNow, _boostPercent);
    }

    /// @notice Apply boost fee
    /// @param _fee Fee amount
    function _applyBoostFee(uint256 _fee) internal {
        address[] storage _receivers = s.boostFeeReceivers;
        uint256[] storage _shares = s.boostFeeReceiversShares;
        uint256 _length = _receivers.length;

        if (_length != _shares.length) {
            revert BoostFacet__InvalidFeeReceivers();
        }
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, _shares[i]);
            s.pendingWithdrawals[_receivers[i]][s.feeToken] += _share;
            unchecked {
                i++;
            }
        }
    }
}
