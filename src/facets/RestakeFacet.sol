// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../libraries/LStratosphere.sol";

error RestakeFacet__InProgressSeason();
error RestakeFacet__HasWithdrawnOrRestaked();
error RestakeFacet__FundsInPrevSeason();

contract RestakeFacet {
    event Restake(address indexed depositor, uint256 amount);

    AppStorage s;

    function restake() external {
        uint256 lastSeasonParticipated = s.addressToLastSeasonId[msg.sender];
        UserData storage userData = s.usersData[lastSeasonParticipated][msg.sender];
        if (s.seasons[lastSeasonParticipated].endTimestamp >= block.timestamp) {
            revert RestakeFacet__InProgressSeason();
        }

        if (s.usersData[lastSeasonParticipated][msg.sender].hasWithdrawnOrRestaked == true) {
            revert RestakeFacet__HasWithdrawnOrRestaked();
        }

        if (s.usersData[lastSeasonParticipated][msg.sender].unlockAmount > 0) {
            revert RestakeFacet__FundsInPrevSeason();
        }

        uint256 lastSeasonAmount = userData.depositAmount + userData.unlockAmount;
        userData.unlockAmount = 0;
        _restake(lastSeasonAmount);
        userData.hasWithdrawnOrRestaked = true;
        s.addressToLastSeasonId[msg.sender] = s.currentSeasonId;
    }

    function _restake(uint256 _amount) internal {
        uint256 _discount = 0;
        s.addressToLastSeasonId[msg.sender] = s.currentSeasonId;
        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _discount = s.depositDiscountForStratosphereMembers[tier];
        }
        uint256 _fee = LPercentages.percentage(_amount, s.restakeFee - (_discount * s.restakeFee) / 10000);
        uint256 _amountMinusFee = _amount - _fee;
        _applyPoints(_amountMinusFee);
        _applyRestakeFee(_fee);
        emit Restake(msg.sender, _amount);
    }

    /// @notice Apply points
    /// @param _amount Amount of token to apply points
    function _applyPoints(uint256 _amount) internal {
        uint256 _seasonId = s.currentSeasonId;
        uint256 _daysUntilSeasonEnd = (s.seasons[_seasonId].endTimestamp - block.timestamp) / 1 days;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        _userData.depositAmount += _amount;
        _userData.depositPoints += _amount * _daysUntilSeasonEnd;
        s.seasons[_seasonId].totalDepositAmount += _amount;
        s.seasons[_seasonId].totalPoints += _amount * _daysUntilSeasonEnd;
    }

    /// @notice Apply restake fee
    /// @param _fee Fee amount
    function _applyRestakeFee(uint256 _fee) internal {
        uint256 _length = s.restakeFeeReceivers.length;
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, s.restakeFeeReceiversShares[i]);
            s.pendingWithdrawals[s.restakeFeeReceivers[i]][s.depositToken] += _share;
            unchecked {
                i++;
            }
        }
    }
}
