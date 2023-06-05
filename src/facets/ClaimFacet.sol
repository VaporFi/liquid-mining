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
    AppStorage s;

    //////////////
    /// EVENTS ///
    //////////////
    event Claim(uint256 indexed seasonId, address indexed user, uint256 rewardsAmount, uint256 depositAmount);

    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Claim accrued VAPE reward token and withdraw unlocked VPND
    function claim() external {
        uint256 seasonId = s.addressToLastSeasonId[msg.sender];
        UserData storage userData = s.usersData[seasonId][msg.sender];
        Season storage season = s.seasons[seasonId];
        if (season.endTimestamp >= block.timestamp) {
            revert ClaimFacet__InProgressSeason();
        }
        if (userData.depositPoints == 0) {
            revert ClaimFacet__NotEnoughPoints();
        }
        if (userData.amountClaimed > 0) {
            revert ClaimFacet__AlreadyClaimed();
        }

        uint256 totalPoints = userData.depositPoints + userData.boostPoints;
        uint256 userShare = _calculateShare(totalPoints, season);

        uint256 rewardTokenShare = _vapeToDistribute(userShare, season);

        userData.amountClaimed = rewardTokenShare;
        season.rewardTokenBalance -= rewardTokenShare;
        season.totalClaimAmount += rewardTokenShare;

        IERC20(s.rewardToken).transfer(msg.sender, rewardTokenShare);
        uint256 withdrawAmount = userData.depositAmount + userData.unlockAmount;
        IERC20(s.depositToken).transfer(msg.sender, withdrawAmount);

        emit Claim(seasonId, msg.sender, rewardTokenShare, withdrawAmount);
    }

    /// @notice Claim accrued VAPE rewards during the current season and withdraw unlocked VPND
    /// @param _seasonId The season ID
    /// @param _users The users to claim for
    function automatedClaim(uint256 _seasonId, address[] memory _users) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Season storage season = s.seasons[_seasonId];
        // If season is still in progress, skip
        if (season.endTimestamp >= block.timestamp) {
            revert ClaimFacet__InProgressSeason();
        }

        uint256 _length = _users.length;
        for (uint256 i; i < _length; ) {
            address user = _users[i];
            UserData storage userData = s.usersData[_seasonId][user];
            uint256 _depositPoints = userData.depositPoints;
            uint256 _unlockAmount = userData.unlockAmount;

            // If user has not participated in the season, skip
            if (_depositPoints == 0) {
                continue;
            }
            // If user has already claimed, skip
            if (userData.amountClaimed > 0) {
                continue;
            }

            uint256 totalPoints = _depositPoints + userData.boostPoints;
            uint256 userShare = _calculateShare(totalPoints, _seasonId);

            uint256 rewardTokenShare = _vapeToDistribute(userShare, _seasonId);

            userData.amountClaimed = rewardTokenShare;
            userData.hasWithdrawnOrRestaked = true;
            userData.unlockAmount = 0;
            userData.unlockTimestamp = 0;
            season.rewardTokenBalance -= rewardTokenShare;
            season.totalClaimAmount += rewardTokenShare;

            IERC20(s.rewardToken).transfer(user, rewardTokenShare);
            uint256 withdrawAmount = userData.depositAmount + _unlockAmount;
            IERC20(s.depositToken).transfer(user, withdrawAmount);

            emit Claim(_seasonId, user, rewardTokenShare, withdrawAmount);

            unchecked {
                i++;
            }
        }
    }

    //////////////////////
    /// INTERNAL LOGIC ///
    //////////////////////

    /// @notice Calculate the share of the User based on totalPoints of season
    function _calculateShare(uint256 _totalPoints, Season storage season) internal view returns (uint256) {
        uint256 seasonTotalPoints = season.totalPoints;
        uint256 userShare = (_totalPoints * 1e18) / seasonTotalPoints;
        return userShare;
    }

    /// @notice Calculate VAPE earned by User through share of the totalPoints
    function _vapeToDistribute(uint256 _userShare, Season storage season) internal view returns (uint256) {
        return (season.rewardTokensToDistribute * _userShare) / 1e18;
    }
}
