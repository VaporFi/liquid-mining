// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage, UserData, Season } from "../libraries/AppStorage.sol";
import { LPercentages } from "../libraries/LPercentages.sol";
import { LAuthorizable } from "../libraries/LAuthorizable.sol";

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

    /// @notice Ordering of the events are according to their relevance in the facet
    event Claim(uint256 indexed seasonId, address indexed user, uint256 rewardsAmount, uint256 depositAmount);

    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Claim accrued VAPE rewards during the current season and withdraw unlocked VPND
    /// @param _seasonId The season ID
    /// @param _users The users to claim for
    function automatedClaimBatch(uint256 _seasonId, address[] memory _users) external {
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
            uint256 userShare = _calculateShare(totalPoints, season);

            uint256 rewardTokenShare = _vapeToDistribute(userShare, season);

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

    function automatedClaim(uint256 _seasonId, address _user) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Season storage season = s.seasons[_seasonId];
        // If season is still in progress, skip
        if (season.endTimestamp >= block.timestamp) {
            revert ClaimFacet__InProgressSeason();
        }

        UserData storage userData = s.usersData[_seasonId][_user];
        uint256 _depositPoints = userData.depositPoints;
        uint256 _unlockAmount = userData.unlockAmount;

        // If user has not participated in the season, skip
        // if (_depositPoints == 0) {
        //     revert ClaimFacet__NotEnoughPoints();
        // }
        // If user has already claimed, skip
        if (userData.amountClaimed > 0) {
            revert ClaimFacet__AlreadyClaimed();
        }

        uint256 totalPoints = _depositPoints + userData.boostPoints;
        uint256 userShare = _calculateShare(totalPoints, season);

        uint256 rewardTokenShare = _vapeToDistribute(userShare, season);

        userData.amountClaimed = rewardTokenShare;
        userData.hasWithdrawnOrRestaked = true;
        userData.unlockAmount = 0;
        userData.unlockTimestamp = 0;
        season.rewardTokenBalance -= rewardTokenShare;
        season.totalClaimAmount += rewardTokenShare;

        IERC20(s.rewardToken).transfer(_user, rewardTokenShare);
        uint256 withdrawAmount = userData.depositAmount + _unlockAmount;
        IERC20(s.depositToken).transfer(_user, withdrawAmount);

        emit Claim(_seasonId, _user, rewardTokenShare, withdrawAmount);
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
