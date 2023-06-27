// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../libraries/LStratosphere.sol";

error UnlockFacet__InvalidAmount();
error UnlockFacet__AlreadyUnlocked();
error UnlockFacet__InvalidFeeReceivers();
error UnlockFacet__InvalidUnlock();

contract UnlockFacet {
    /// @notice Ordering of the events are according to their relevance in the facet
    event Unlocked(uint256 indexed seasonId, address indexed user, uint256 amount, uint256 unlockFee);

    AppStorage s;
    uint256 public constant COOLDOWN_PERIOD = 72 * 3600; // 72 Hours

    function unlock(uint256 _amount) external {
        uint256 _currentSeasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_currentSeasonId][msg.sender];
        Season storage _currentSeason = s.seasons[_currentSeasonId];
        uint256 _seasonEndTimestamp = _currentSeason.endTimestamp; //used twice in transaction
        if (_userData.unlockTimestamp != 0) {
            revert UnlockFacet__AlreadyUnlocked();
        }
        if (_userData.depositAmount < _amount) {
            revert UnlockFacet__InvalidAmount();
        }
        _deductPoints(_amount, _seasonEndTimestamp, _userData, _currentSeason);

        uint256 _timeDiscount = 0;
        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _timeDiscount = s.unlockTimestampDiscountForStratosphereMembers[tier];
        }
        uint256 _unlockFeeFromState = s.unlockFee;
        uint256 _fee = LPercentages.percentage(_amount,_unlockFeeFromState);
        _applyUnlockFee(_fee);
        uint256 _unlockTimestamp = block.timestamp + COOLDOWN_PERIOD - (_timeDiscount * COOLDOWN_PERIOD) / 10000;

        if (_unlockTimestamp >= _seasonEndTimestamp) {
            revert UnlockFacet__InvalidUnlock();
        }

        _userData.unlockAmount += (_amount - _fee);
        _userData.unlockTimestamp = _unlockTimestamp;

        emit Unlocked(_currentSeasonId, msg.sender, _amount, _fee);
    }

    /// @notice deduct points
    /// @param _amount Amount of token to deduct points
    function _deductPoints(
        uint256 _amount,
        uint256 _seasonEndTimestamp,
        UserData storage _userData,
        Season storage _season
    ) internal {
        uint256 _daysUntilSeasonEnd = (_seasonEndTimestamp - block.timestamp) / 1 days;
        _userData.depositAmount -= _amount;
        _userData.depositPoints -= _amount * _daysUntilSeasonEnd;
        _season.totalDepositAmount -= _amount;
        _season.totalPoints -= _amount * _daysUntilSeasonEnd;
    }

    /// @notice Apply deposit fee
    /// @param _fee Fee amount
    function _applyUnlockFee(uint256 _fee) internal {
        if (s.unlockFeeReceivers.length != s.unlockFeeReceiversShares.length) {
            revert UnlockFacet__InvalidFeeReceivers();
        }
        uint256 _length = s.unlockFeeReceivers.length;
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, s.unlockFeeReceiversShares[i]);
            s.pendingWithdrawals[s.unlockFeeReceivers[i]][s.depositToken] += _share;
            unchecked {
                i++;
            }
        }
    }
}
