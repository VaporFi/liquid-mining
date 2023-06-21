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

    /// @notice Ordering of the events are according to their relevance in the facet
    event WithdrawUnlockedVPND(uint256 indexed seasonId, address indexed to, uint256 amount);

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
        userData.unlockAmount = 0;
        userData.unlockTimestamp = 0;
        IERC20(s.depositToken).transfer(user, amount);
        emit WithdrawUnlockedVPND(seasonId, user, amount);
    }
}
