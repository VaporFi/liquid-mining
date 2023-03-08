// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../interfaces/IRewardsController.sol";

error UnlockFacet__InvalidAmount();
error UnlockFacet__AlreadyUnlocked();
error UnlockFacet__InvalidFeeReceivers();
error UnlockFacet__InvalidUnlock();

contract UnlockFacet {
    event Unlocked(address indexed user, uint256 amount);

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

        uint256 _fee = LPercentages.percentage(_amount, s.unlockFee);
        _applyUnlockFee(_fee);

        uint256 _timeDiscount = 0;
        (bool isStratosphereMember, uint256 tier) = getStratosphereMembershipDetails(msg.sender);
        if (isStratosphereMember) {
            _timeDiscount = s.unlockDiscountForStratosphereMembers[tier];
        }

        uint256 _unlockTimestamp = block.timestamp + COOLDOWN_PERIOD - (_timeDiscount * COOLDOWN_PERIOD) / 10000;

        if (_unlockTimestamp >= s.seasons[s.currentSeasonId].endTimestamp) {
            revert UnlockFacet__InvalidUnlock();
        }

        s.usersData[s.currentSeasonId][msg.sender].unlockAmount += (_amount - _fee);
        s.usersData[s.currentSeasonId][msg.sender].unlockTimestamp = _unlockTimestamp;

        emit Unlocked(msg.sender, _amount);
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
        if (s.feeReceivers.length != s.feeReceiversShares.length) {
            revert UnlockFacet__InvalidFeeReceivers();
        }
        uint256 _length = s.feeReceivers.length;
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, s.feeReceiversShares[i]);
            s.pendingWithdrawals[s.feeReceivers[i]] += _share;
            unchecked {
                i++;
            }
        }
    }
}
