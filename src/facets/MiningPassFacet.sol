// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPausable.sol";

error MiningPassFacet__InvalidTier();
error MiningPassFacet__AlreadyPurchased();
error MiningPassFacet__InsufficientBalance();
error MiningPassFacet__SeasonEnded();

/// @title MiningPassFacet
/// @notice Facet in charge of purchasing and upgrading mining passes
/// @dev Utilizes 'LDiamond', 'AppStorage'
contract MiningPassFacet {
    AppStorage s;

    event MiningPassPurchase(address indexed user, uint256 indexed tier, uint256 fee, uint256 seasonId);

    /// notice Purchase a mining pass
    /// @param _tier Tier of mining pass to purchase
    function purchase(uint256 _tier) external {
        IERC20 _feeToken = IERC20(s.feeToken);
        uint256 _currentSeasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_currentSeasonId][msg.sender];
        // check _tier is not 0
        if (_tier == 0 || _tier <= _userData.miningPassTier) {
            revert MiningPassFacet__InvalidTier();
        }
        // check if user have enough USDC to purchase
        uint256 _fee = s.miningPassTierToFee[_tier] - s.miningPassTierToFee[_userData.miningPassTier];
        if (_feeToken.balanceOf(msg.sender) < _fee) {
            revert MiningPassFacet__InsufficientBalance();
        }
        // check current season is not ended
        if (s.seasons[_currentSeasonId].endTimestamp <= block.timestamp) {
            revert MiningPassFacet__SeasonEnded();
        }

        // update user's mining pass tier
        _userData.miningPassTier = _tier;
        // transfer USDC from user to contract
        _feeToken.transferFrom(msg.sender, address(this), _fee);

        emit MiningPassPurchase(msg.sender, _tier, _fee, _currentSeasonId);
    }

    /// @notice Get user's mining pass tier and deposit limit
    /// @param _user User address
    function miningPassOf(address _user) external view returns (uint256 _tier, uint256 _depositLimit) {
        UserData memory _userData = s.usersData[s.currentSeasonId][_user];
        return (_userData.miningPassTier, s.miningPassTierToDepositLimit[_userData.miningPassTier]);
    }
}
