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
    event WithdrawUnlockedVPND(uint256 amount, address indexed to);
    event WithdrawVPND(uint256 amount, address indexed to);
    event WithdrawAll(uint256 amount, address indexed to);
    
    AppStorage s;
    
    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Withdraw prematurely unlocked VPND
    /// @dev User cannot participate in new seasons until they withdraw 
    function withdrawUnlocked() external {
        address user = msg.sender;
        uint256 seasonId = s.addressToLastSeasonId[user];
        uint256 amount = s.usersData[seasonId][user].unlockAmount;
        uint256 unlockTimestamp = s.usersData[seasonId][user].unlockTimestamp;
        if(amount == 0) {
            revert WithdrawFacet__InsufficientBalance();
        } 
        if(unlockTimestamp > block.timestamp) {
            revert WithdrawFacet__UnlockNotMatured();
        }
        s.usersData[seasonId][user].unlockAmount = 0;
        s.usersData[seasonId][user].unlockTimestamp = 0;
        IERC20(s.depositToken).transferFrom(address(this), user, amount); 
        emit WithdrawUnlockedVPND(amount, user);
    }


    /// @notice Withdraw unlocked VPND
    /// @dev User cannot participate in new seasons until they withdraw 
    function withdraw() external {
        address user = msg.sender;
        uint256 seasonId = s.addressToLastSeasonId[user];

       if(s.usersData[seasonId][user].depositAmount == 0) {
        revert WithdrawFacet__UserNotParticipated();
       }

       if(s.seasons[seasonId].endTimestamp >= block.timestamp) {
        revert WithdrawFacet__InProgressSeason();
       }

       if(s.usersData[seasonId][user].hasWithdrawnOrRestaked == true) {
        revert WithdrawFacet__AlreadyWithdrawn();
       } 

       uint256 amount = s.usersData[seasonId][user].depositAmount;
    //    s.usersData[seasonId][user].depositAmount = 0; // @audit Do we want do this?
        s.usersData[seasonId][user].hasWithdrawnOrRestaked = true; // @audit Or this is better?
       IERC20(s.depositToken).transferFrom(address(this), user, amount);
       emit WithdrawVPND(amount, user);
    }

    /// @notice Withdraw all unlocked VPND
    /// @dev User cannot participate in new seasons until they withdraw 
    function withdrawAll() external {
        address user = msg.sender;
        uint256 seasonId = s.addressToLastSeasonId[user];
        uint256 depositAmount = s.usersData[seasonId][user].depositAmount;
        uint256 unlockAmount = s.usersData[seasonId][user].unlockAmount;
        uint256 unlockTimestamp = s.usersData[seasonId][user].unlockTimestamp;
        uint256 seasonEndTimestamp = s.seasons[seasonId].endTimestamp;
        bool hasWithdrawnOrRestaked = s.usersData[seasonId][user].hasWithdrawnOrRestaked;

        if(depositAmount == 0) {
            revert WithdrawFacet__UserNotParticipated();
        }


        if(seasonEndTimestamp >= block.timestamp) {
            revert WithdrawFacet__InProgressSeason();
        }
        
        if(unlockAmount == 0) {
            revert WithdrawFacet__InsufficientBalance();
        }


        if(unlockTimestamp > block.timestamp) {
            revert WithdrawFacet__UnlockNotMatured();
        }
        

        if(hasWithdrawnOrRestaked == true) {
            revert WithdrawFacet__AlreadyWithdrawn();
        } 


        uint256 amount = depositAmount + unlockAmount;
        s.usersData[seasonId][user].unlockAmount = 0;
        s.usersData[seasonId][user].unlockTimestamp = 0;
        s.usersData[seasonId][user].hasWithdrawnOrRestaked = true;
        IERC20(s.depositToken).transferFrom(address(this), user, amount);
        emit WithdrawAll(amount, user);
    }
}
