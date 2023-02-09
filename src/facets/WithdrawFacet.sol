// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "../libraries/AppStorage.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

error WithdrawFacet__InProgressSeason();
error WithdrawFacet__InsufficientBalance();
error WithdrawFacet__UnlockNotMatured();
error WithdrawFacet__UserNotParticipated();
error WithdrawFacet__AlreadyWithdrawn();

/// @title WithdrawFacet
/// @notice Facet in charge of withdrawing unlocked VPND
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'IERC20'
contract WithdrawFacet {
    //////////////
    /// EVENTS ///
    //////////////
    event WithdrawUnlocked(uint256 amount, address indexed to);
    event Withdraw(uint256 amount, address indexed to);
    
    AppStorage s;
    
    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Withdraw prematurely unlocked VPND 
    /// @param _seasonId The ID of the season
    /// @param _amount The amount of VPND to deposit
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


    /// @notice Withdraw unlocked VPND 
    function withdraw(address _user) external {
        uint256 seasonId = s.addressToLastSeasonId[_user];

       if(s.usersData[seasonId][_user].depositAmount == 0) {
        revert WithdrawFacet__UserNotParticipated();
       }

       if(s.seasons[seasonId].endTimestamp >= block.timestamp) {
        revert WithdrawFacet__InProgressSeason();
       }

       if(s.usersData[seasonId][_user].hasWithdrawnOrRestaked == true) {
        revert WithdrawFacet__AlreadyWithdrawn();
       } 

       uint256 amount = s.usersData[seasonId][_user].depositAmount;
    //    s.usersData[seasonId][_user].depositAmount = 0; // @audit Do we want do this?
        s.usersData[seasonId][_user].hasWithdrawnOrRestaked = true; // @audit Or this is better?
       IERC20(s.depositToken).transferFrom(address(this), _user, amount);
       emit Withdraw(amount, _user);
    }
}
