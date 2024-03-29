// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage, UserData, Season } from "../libraries/AppStorage.sol";
import { LPercentages } from "../libraries/LPercentages.sol";
import { IStratosphere } from "../interfaces/IStratosphere.sol";
import { LStratosphere } from "../libraries/LStratosphere.sol";

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
        uint256 indexed seasonId,
        address indexed user,
        uint256 boostLevel,
        uint256 _boostPoints,
        uint256 boostFee,
        uint256 tier
    );

    AppStorage s;

    /// @notice Claim daily boost points
    function claimBoost(uint256 _boostLevel) external {
        uint256 _seasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        if (_userData.depositAmount == 0) {
            revert BoostFacet__UserNotParticipated();
        }
        if (_userData.lastBoostClaimTimestamp != 0 && block.timestamp - _userData.lastBoostClaimTimestamp < 1 days) {
            revert BoostFacet__BoostAlreadyClaimed();
        }
        (bool isStratosphereMember, uint256 stratosphereTier) = LStratosphere.getDetails(s, msg.sender);
        uint256 _boostFee = _calculateBoostFee(isStratosphereMember, _boostLevel);

        _userData.lastBoostClaimTimestamp = block.timestamp;
        uint256 _boostPercent = _calculateBoostPercent(isStratosphereMember, stratosphereTier, _boostLevel);
        uint256 _boostPointsAmount = _calculatePoints(_userData, _boostPercent, _seasonId);
        _userData.boostPoints += _boostPointsAmount;
        _userData.lastBoostClaimAmount = _boostPointsAmount;
        if (_boostFee > 0) {
            _applyBoostFee(_boostFee);
            IERC20(s.feeToken).transferFrom(msg.sender, address(this), _boostFee);
        }
        emit ClaimBoost(_seasonId, msg.sender, _boostLevel, _boostPointsAmount, _boostFee, stratosphereTier);
    }

    /// @notice Calculate boost points
    /// @param _userData User season data
    /// @param _boostPercent % to boost points
    /// @param _seasonId current seasonId
    /// @return Boost points
    /// @dev Utilizes 'LPercentages'.
    /// @dev _daysSinceSeasonStart starts from 0 equal to the first day of the season.
    function _calculatePoints(
        UserData storage _userData,
        uint256 _boostPercent,
        uint256 _seasonId
    ) internal returns (uint256) {
        if (_boostPercent == 0) {
            return 0;
        }

        Season storage _season = s.seasons[_seasonId];
        uint256 _daysUntilSeasonEnd = (_season.endTimestamp - block.timestamp) / 1 days;

        if (_daysUntilSeasonEnd == 0) {
            return 0;
        }

        uint256 _pointsObtainedTillNow = (_userData.depositPoints + _userData.boostPoints) -
            (_userData.depositAmount * _daysUntilSeasonEnd);

        if (_pointsObtainedTillNow == 0) {
            return 0;
        }
        uint256 points = LPercentages.percentage(_pointsObtainedTillNow, _boostPercent);
        _season.totalPoints += points;
        return points;
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

    function _calculateBoostPercent(
        bool _isStratosphereMember,
        uint256 _tier,
        uint256 _boostLevel
    ) internal view returns (uint256 _boostPercent) {
        if (_isStratosphereMember) {
            _boostPercent = s.boostPercentFromTierToLevel[_tier][_boostLevel];
        } else {
            _boostPercent = s.boostForNonStratMembers;
        }
    }

    function _calculateBoostFee(
        bool _isStratosphereMember,
        uint256 _boostLevel
    ) internal view returns (uint256 _boostFee) {
        if (_isStratosphereMember) {
            _boostFee = s.boostLevelToFee[_boostLevel];
        } else if (!_isStratosphereMember && _boostLevel > 0) {
            revert BoostFacet__InvalidBoostLevel();
        }
    }
}
