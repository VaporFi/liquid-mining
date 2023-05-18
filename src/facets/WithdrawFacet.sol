// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";

error WithdrawFacet__InsufficientBalance();
error WithdrawFacet__UnlockNotMatured();

/// @title WithdrawFacet
/// @notice Facet in charge of withdrawing unlocked VPND
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'IERC20'
contract WithdrawFacet {
    AppStorage s;

    //////////////
    /// EVENTS ///
    //////////////
    event WithdrawUnlockedVPND(uint256 amount, address indexed to, uint256 seasonId);

    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Withdraw prematurely unlocked VPND
    /// @dev User cannot participate in new seasons until they withdraw
    function withdrawUnlocked() external {
        address user = msg.sender;
        uint256 seasonId = s.addressToLastSeasonId[user];

        UserData storage userData = s.usersData[seasonId][user];
        uint256 amount = userData.unlockAmount;
        uint256 unlockTimestamp = userData.unlockTimestamp;
        if (amount == 0) {
            revert WithdrawFacet__InsufficientBalance();
        }
        if (unlockTimestamp > block.timestamp) {
            revert WithdrawFacet__UnlockNotMatured();
        }
        s.usersData[seasonId][user].unlockAmount = 0;
        s.usersData[seasonId][user].unlockTimestamp = 0;
        IERC20(s.depositToken).transfer(user, amount);
        emit WithdrawUnlockedVPND(amount, user, seasonId);
    }
}
