// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "../libraries/AppStorage.sol";

contract WithdrawFacet {
    error WithdrawFacet__InProgressSeason();

    AppStorage s;

    /// @notice Withdraws the staked amount from previous stake seasons
    /// @param _seasonId Season ID
    function withdraw(uint256 _seasonId) external view {
        if (_seasonId == s.currentSeasonId) revert WithdrawFacet__InProgressSeason();
    }
}
