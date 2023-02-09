// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "../libraries/AppStorage.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

error WithdrawFacet__InProgressSeason();
error WithdrawFacet__UnlockNotParked();
error WithdrawFacet__InsufficientBalance();
error WithdrawFacet__UnlockNotMatured();
error WithdrawFacet__UserNotParticipated();
error WithdrawFacet__InvalidSeason();
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

    /////////////////
    /// MODIFIERS ///
    /////////////////


    /// @dev Mark function is given a valid seasonId
    /// @param _seasonId The ID to check
    modifier checkSeason(uint256 _seasonId) {
        if(s.seasons[_seasonId].endTimestamp >= block.timestamp) revert WithdrawFacet__InProgressSeason();
        if(_seasonId > s.currentSeasonId) revert WithdrawFacet__InvalidSeason();
        _;
    }
    /// @dev Mark function is called first time after unlock
    /// @param _seasonId The ID to check
    modifier hasWithdrawnOrStaked(uint56 _seasonId) {
        if(s.usersData[_seasonId][msg.sender].hasWithdrawnOrRestaked == true) revert WithdrawFacet__AlreadyWithdrawn();
        _;
    }

    
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
    /// @param _seasonId The ID of the season
    function withdraw(uint256 _seasonId) checkSeason(_seasonId) external {
       if(s.usersData[_seasonId][msg.sender].depositAmount == 0) {
        revert WithdrawFacet__UserNotParticipated();
       }
       uint256 amount = s.usersData[_seasonId][msg.sender].depositAmount;
    //    s.usersData[_seasonId][msg.sender].depositAmount = 0; // @audit Do we want do this?
        s.usersData[_seasonId][msg.sender].hasWithdrawnOrRestaked = true; // @audit Or this is better?
       IERC20(s.depositToken).transferFrom(address(this), msg.sender, amount);
       emit Withdraw(amount, msg.sender);
    }
}
