// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../libraries/LAuthorizable.sol";

error ClaimFacet__NotEnoughPoints();
error ClaimFacet__InProgressSeason();
error ClaimFacet__AlreadyClaimed();
error ClaimFacet__InvalidFeeReceivers();

/// @title ClaimFacet
/// @notice Facet in charge of claiming VAPE rewards
/// @dev Utilizes 'LDiamond' and 'AppStorage'
contract ClaimFacet {
    //////////////
    /// EVENTS ///
    //////////////
    event Claim(uint256 amount, address indexed claimer, uint256 seasonId);

    AppStorage s;

    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Claim accrued VAPE reward token
    function claim() external {
        uint256 seasonId = s.addressToLastSeasonId[msg.sender];
        UserData storage userData = s.usersData[seasonId][msg.sender];
        if (s.seasons[seasonId].endTimestamp >= block.timestamp) {
            revert ClaimFacet__InProgressSeason();
        }
        if (userData.depositPoints == 0) {
            revert ClaimFacet__NotEnoughPoints();
        }
        if (userData.amountClaimed > 0) {
            revert ClaimFacet__AlreadyClaimed();
        }

        uint256 totalPoints = userData.depositPoints + userData.boostPoints;
        uint256 userShare = _calculateShare(totalPoints, seasonId);

        uint256 rewardTokenShare = _vapeToDistribute(userShare, seasonId);

        userData.amountClaimed = rewardTokenShare;
        s.seasons[seasonId].rewardTokenBalance -= rewardTokenShare;
        s.seasons[seasonId].totalClaimAmount += rewardTokenShare;

        IERC20(s.rewardToken).transfer(msg.sender, rewardTokenShare);

        emit Claim(rewardTokenShare, msg.sender, seasonId);
    }

    /// @notice Claim accrued VAPE rewards during the current season and withdraw unlocked VPND
    function automatedClaim(address[] memory _users) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);
        uint256 _length = _users.length;
        for (uint256 i; i < _length; ) {
            address user = _users[i];
            uint256 seasonId = s.addressToLastSeasonId[user];
            UserData storage userData = s.usersData[seasonId][user];
            Season storage season = s.seasons[seasonId];
            uint256 _depositPoints = userData.depositPoints;

            // If user has not participated in the season, skip
            if (_depositPoints == 0) {
                continue;
            }

            // If user has already claimed, skip
            if (userData.amountClaimed > 0) {
                continue;
            }

            // If season is still in progress, skip
            if (season.endTimestamp >= block.timestamp) {
                continue;
            }

            uint256 totalPoints = _depositPoints + userData.boostPoints;
            uint256 userShare = _calculateShare(totalPoints, seasonId);

            uint256 rewardTokenShare = _vapeToDistribute(userShare, seasonId);

            userData.amountClaimed = rewardTokenShare;
            userData.hasWithdrawnOrRestaked = true;
            season.rewardTokenBalance -= rewardTokenShare;
            season.totalClaimAmount += rewardTokenShare;

            IERC20(s.rewardToken).transfer(user, rewardTokenShare);
            // Withdraw unlocked VPND
            IERC20(s.depositToken).transfer(user, userData.depositAmount);

            emit Claim(rewardTokenShare, user, seasonId);

            unchecked {
                i++;
            }
        }
    }

    //////////////////////
    /// INTERNAL LOGIC ///
    //////////////////////

    /// @notice Calculate the share of the User based on totalPoints of season
    function _calculateShare(uint256 _totalPoints, uint256 _seasonId) internal view returns (uint256) {
        uint256 seasonTotalPoints = s.seasons[_seasonId].totalPoints;
        uint256 userShare = (_totalPoints * 1e18) / seasonTotalPoints;
        return userShare;
    }

    /// @notice Calculate VAPE earned by User through share of the totalPoints
    function _vapeToDistribute(uint256 _userShare, uint256 _seasonId) internal view returns (uint256) {
        return (s.seasons[_seasonId].rewardTokensToDistribute * _userShare) / 1e18;
    }
}
