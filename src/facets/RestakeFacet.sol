// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../interfaces/IRewardsController.sol";

error RestakeFacet__InProgressSeason();
error RestakeFacet__HasWithdrawnOrRestaked();
error RestakeFacet__InvalidFeeReceivers();

contract RestakeFacet is ReentrancyGuard {

    event Restake(address indexed depositor, uint256 amount);

    AppStorage s;

    function restake() external nonReentrant {
        uint256 lastSeasonParticipated = s.addressToLastSeasonId[msg.sender];
        if(s.seasons[lastSeasonParticipated].endTimestamp >= block.timestamp) {
        revert RestakeFacet__InProgressSeason();
        }

        if(s.usersData[lastSeasonParticipated][msg.sender].hasWithdrawnOrRestaked == true){
            revert RestakeFacet__HasWithdrawnOrRestaked();
        }

        uint256 lastSeasonAmount = s.usersData[lastSeasonParticipated][msg.sender].depositAmount;
        _restake(lastSeasonAmount);
        s.usersData[s.currentSeasonId][msg.sender].hasWithdrawnOrRestaked = true;
    }

    function _restake(uint256 _amount) internal {
        uint256 _discount = 0;
        uint256 restakeFee = s.seasons[s.currentSeasonId].restakeFee;
        s.addressToLastSeasonId[msg.sender] = s.currentSeasonId;
        (bool isStratosphereMember, uint256 tier) = getStratosphereMembershipDetails(msg.sender);
        if (isStratosphereMember) {
            _discount = s.depositDiscountForStratosphereMembers[tier];
        }
        uint256 _fee = LPercentages.percentage(_amount, restakeFee - ((restakeFee * _discount) / 100)); // audit
        uint256 _amountMinusFee = _amount - _fee;
        _applyPoints(_amountMinusFee);
        _applyRestakeFee(_fee);
        emit Restake(msg.sender, _amount);
        
    }
 
    /// @notice get details of stratosphere for member
    /// @param _account Account of member to check
    /// @return bool if account is stratosphere member
    /// @return uint256 tier of membership
    function getStratosphereMembershipDetails(address _account) private view returns (bool, uint256) {
        IStratosphere stratosphere = IStratosphere(s.stratoshpereAddress);
        uint256 tokenId = stratosphere.tokenIdOf(_account);

        if (tokenId != 0) {
        uint256 _tier = IRewardsController().tierOf();
        return (true, _tier)
        }
        
        return (false, 0);
            return (false, 0);
        } else {
            IRewardsController rewardController = IRewardsController(s.rewardsControllerAddress);
            uint256 tier = rewardController.tierOf(keccak256("STRATOSPHERE_PROGRAM"), tokenId);
            return (true, tier);
        }
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
        if (s.depositFeeReceivers.length != s.depositFeeReceiversShares.length) {
            revert RestakeFacet__InvalidFeeReceivers();
        }
        uint256 _length = s.depositFeeReceivers.length;
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, s.depositFeeReceiversShares[i]);
            s.pendingWithdrawals[s.depositFeeReceivers[i]] += _share;
            unchecked {
                i++;
            }
        }
    }


}