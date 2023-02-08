// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "../libraries/AppStorage.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WithdrawFacet {
    event WithdrawUnlocked(uint256 amount, address indexed to);
    event Withdraw(uint256 amount, address indexed to);


    error WithdrawFacet__InProgressSeason();
    error WithdrawFacet__UnlockNotParked();
    error WithdrawFacet__InsufficientBalance();
    error WithdrawFacet__UnlockNotMatured();
    error WithdrawFacet__UserNotParticipated();

    AppStorage s;

    
    function withdrawUnlocked(uint256 _seasonId, uint256 _amount) external {
        if(_amount == 0 && s.usersData[_seasonId][msg.sender].isUnlockAmount < _amount) {
            revert WithdrawFacet__InsufficientBalance();
        } 
        if(s.usersData[_seasonId][msg.sender].isUnlockTimestamp < block.timestamp) {
            revert WithdrawFacet__UnlockNotMatured();
        }
        s.usersData[_seasonId][msg.sender].isUnlockAmount = 0;
        s.usersData[_seasonId][msg.sender].isUnlockTimestamp = 0;
        IERC20(s.depositToken).transferFrom(address(this), msg.sender, _amount);
        emit WithdrawUnlocked(_amount, msg.sender);
    }

    function withdraw(uint256 _seasonId) external {
       if (_seasonId == s.currentSeasonId) revert WithdrawFacet__InProgressSeason();
       if(s.usersData[_seasonId][msg.sender].depositAmount == 0) {
        revert WithdrawFacet__UserNotParticipated();
       }
       uint256 amount = s.usersData[_seasonId][msg.sender].depositAmount;
       IERC20(s.depositToken).transferFrom(address(this), msg.sender, amount);
       emit Withdraw(amount, msg.sender);
    }
}
