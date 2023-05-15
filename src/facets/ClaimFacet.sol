// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";

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
