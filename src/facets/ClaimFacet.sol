// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/AppStorage.sol";


error ClaimFacet__NotEnoughPoints();
error ClaimFacet__InProgressSeason();
error ClaimFacet__InvalidSeason();


/// @title ClaimFacet
/// @notice Facet in charge of claiming VAPE rewards
/// @dev Utilizes 'LDiamond' and 'AppStorage'
contract ClaimFacet {
    event Claim(uint256 amount, address indexed claimer);

    AppStorage s;

    modifier checkSeason(uint256 _seasonId) {
        if(s.seasons[_seasonId].endTimestamp >= block.timestamp) revert ClaimFacet__InProgressSeason();
        if(_seasonId > s.currentSeasonId) revert ClaimFacet__InvalidSeason();
        _;
    }

    function claim(uint256 _seasonId) checkSeason(_seasonId) external {
        if(s.usersData[_seasonId][msg.sender].depositPoints == 0) {
            revert ClaimFacet__NotEnoughPoints();
        }
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        uint256 totalPoints = _userData.depositPoints + _userData.boostPoints;
        uint256 userShare = calculateShare(totalPoints, _seasonId);
        uint256 rewardTokenShare = vapeToDistribute(userShare, _seasonId);
        _userData.depositPoints = 0;
        _userData.boostPoints = 0;
        IERC20(s.rewardToken).transferFrom(address(this), msg.sender, rewardTokenShare);
        emit Claim(rewardTokenShare, msg.sender)

    }

    function calculateShare(uint256 _totalPoints, uint256 _seasonId) internal view returns(uint256) {
        uint256 seasonTotalPoints = s.seasons[_seasonId].totalPoints;
        uint256 userShare = (_totalPoints * 1e18) / seasonTotalPoints;
        return userShare;
    }

    function vapeToDistribute(uint256 _userShare, uint256 _seasonId) internal view returns(uint256) {
        return (s.seasons[_seasonId].rewardTokenBalance * _userShare) / 1e18;
    }
}
