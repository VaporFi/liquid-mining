// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../libraries/LStratosphere.sol";
import "forge-std/Test.sol";

error UnlockFacet__InvalidAmount();
error UnlockFacet__AlreadyUnlocked();
error UnlockFacet__InvalidFeeReceivers();
error UnlockFacet__InvalidUnlock();

contract UnlockFacet {
    event Unlocked(address indexed user, uint256 amount, uint256 seasonId, uint256 unlockFee);

    AppStorage s;
    uint256 public constant COOLDOWN_PERIOD = 72 * 3600; // 72 Hours

    function unlock(uint256 _amount) external {
        if (s.usersData[s.currentSeasonId][msg.sender].unlockTimestamp != 0) {
            revert UnlockFacet__AlreadyUnlocked();
        }
        if (s.usersData[s.currentSeasonId][msg.sender].depositAmount < _amount) {
            revert UnlockFacet__InvalidAmount();
        }
        _deductPoints(_amount);

        uint256 _timeDiscount = 0;
        uint256 _feeDiscount = 0;
        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _timeDiscount = s.unlockTimestampDiscountForStratosphereMembers[tier];
            _feeDiscount = s.unlockFeeDiscountForStratosphereMembers[tier];
        }
        uint256 _fee = LPercentages.percentage(_amount, s.unlockFee - (_feeDiscount * s.unlockFee) / 10000);
        _applyUnlockFee(_fee);
        uint256 _unlockTimestamp = block.timestamp + COOLDOWN_PERIOD - (_timeDiscount * COOLDOWN_PERIOD) / 10000;

        if (_unlockTimestamp >= s.seasons[s.currentSeasonId].endTimestamp) {
            revert UnlockFacet__InvalidUnlock();
        }

        s.usersData[s.currentSeasonId][msg.sender].unlockAmount += (_amount - _fee);
        s.usersData[s.currentSeasonId][msg.sender].unlockTimestamp = _unlockTimestamp;

        emit Unlocked(msg.sender, _amount, s.currentSeasonId, _fee);
    }

    /// @notice deduct points
    /// @param _amount Amount of token to deduct points
    function _deductPoints(uint256 _amount) internal {
        uint256 _seasonId = s.currentSeasonId;
        uint256 _daysUntilSeasonEnd = (s.seasons[_seasonId].endTimestamp - block.timestamp) / 1 days;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        _userData.depositAmount -= _amount;
        _userData.depositPoints -= _amount * _daysUntilSeasonEnd;
        s.seasons[_seasonId].totalDepositAmount -= _amount;
        s.seasons[_seasonId].totalPoints -= _amount * _daysUntilSeasonEnd;
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
