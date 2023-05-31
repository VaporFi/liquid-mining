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
    event Claim(uint256 amount, address indexed claimer, uint256 seasonId, uint256 claimFee);

    AppStorage s;

    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Claim accrued VAPE reward token
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

        uint256 _fee = LPercentages.percentage(rewardTokenShare, s.claimFee);
        _applyClaimFee(_fee);
        IERC20(s.rewardToken).transfer(msg.sender, rewardTokenShare - _fee);

        emit Claim(rewardTokenShare, msg.sender, seasonId, _fee);
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

    function _applyClaimFee(uint256 _fee) internal {
        address[] storage _receivers = s.claimFeeReceivers;
        uint256[] storage _shares = s.claimFeeReceiversShares;
        uint256 _length = _receivers.length;

        if (_length != _shares.length) {
            revert ClaimFacet__InvalidFeeReceivers();
        }
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, _shares[i]);
            s.pendingWithdrawals[_receivers[i]][s.rewardToken] += _share;
            unchecked {
                i++;
            }
        }
    }
}
