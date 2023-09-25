// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage, UserData, Season } from "../libraries/AppStorage.sol";
import { LPausable } from "../libraries/LPausable.sol";
import { LPercentages } from "../libraries/LPercentages.sol";

error MiningPassFacet__InvalidTier();
error MiningPassFacet__AlreadyPurchased();
error MiningPassFacet__InsufficientBalance();
error MiningPassFacet__SeasonEnded();
error MiningPassFacet__InvalidFeeReceivers();

/// @title MiningPassFacet
/// @notice Facet in charge of purchasing and upgrading mining passes
/// @dev Utilizes 'LDiamond', 'AppStorage'
contract MiningPassFacet {
    AppStorage s;

    /// @notice Ordering of the events are according to their relevance in the facet
    event MiningPassPurchase(uint256 indexed seasonId, address indexed user, uint256 indexed tier, uint256 fee);

    /// notice Purchase a mining pass
    /// @param _tier Tier of mining pass to purchase
    function purchase(uint256 _tier) external {
        uint256 feeForPassedTier = s.miningPassTierToFee[_tier];
        IERC20 _feeToken = IERC20(s.feeToken);
        uint256 _currentSeasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_currentSeasonId][msg.sender];
        Season storage _currentSeason = s.seasons[_currentSeasonId];
        // check _tier is not 0
        if (_tier == 0 || _tier <= _userData.miningPassTier || feeForPassedTier == 0) {
            revert MiningPassFacet__InvalidTier();
        }
        
        // check current season is not ended
        if (_currentSeason.endTimestamp <= block.timestamp) {
            revert MiningPassFacet__SeasonEnded();
        }

        uint256 _fee = getMiningPassFee(msg.sender, _tier);

        // check if user have enough USDC to purchase
        if (_feeToken.balanceOf(msg.sender) < _fee) {
            revert MiningPassFacet__InsufficientBalance();
        }

        // update user's mining pass tier
        _userData.miningPassTier = _tier;
        // transfer USDC from user to contract
        _applyMiningPassFee(_fee);
        _feeToken.transferFrom(msg.sender, address(this), _fee);

        emit MiningPassPurchase(_currentSeasonId, msg.sender, _tier, _fee);
    }

    /// notice Fee for mining pass
    /// @param _user User to query fee for
    /// @param _tier Tier of mining pass to purchase
    function getMiningPassFee(address _user, uint256 _tier) public view returns(uint256 _fee) {
        uint256 feeForPassedTier = s.miningPassTierToFee[_tier];
        uint256 _currentSeasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_currentSeasonId][_user];
        Season storage _currentSeason = s.seasons[_currentSeasonId];
        // check _tier is not 0
        if (_tier == 0 || _tier <= _userData.miningPassTier || feeForPassedTier == 0) {
            revert MiningPassFacet__InvalidTier();
        }
        // check the difference between current paid fee vs fee to pay
         _fee = feeForPassedTier - s.miningPassTierToFee[_userData.miningPassTier];
        // check current season is not ended
        if (_currentSeason.endTimestamp <= block.timestamp) {
            revert MiningPassFacet__SeasonEnded();
        }

        if (block.timestamp - _currentSeason.startTimestamp >= 14 days) {
            _fee = _fee / 2;
        } else if (block.timestamp - _currentSeason.startTimestamp >= 7 days) {
            _fee = _fee - _fee / 4;
        }
    }   

    /// @notice Get user's mining pass tier and deposit limit
    /// @param _user User address
    function miningPassOf(address _user) external view returns (uint256 _tier, uint256 _depositLimit) {
        UserData memory _userData = s.usersData[s.currentSeasonId][_user];
        return (_userData.miningPassTier, s.miningPassTierToDepositLimit[_userData.miningPassTier]);
    }

    /// @notice Apply mining pass fee to the fee receivers
    /// @param _fee Fee amount
    function _applyMiningPassFee(uint256 _fee) internal {
        address[] memory _receivers = s.miningPassFeeReceivers;
        uint256[] memory _shares = s.miningPassFeeReceiversShares;
        uint256 _length = _receivers.length;

        if (_length != _shares.length) {
            revert MiningPassFacet__InvalidFeeReceivers();
        }
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, _shares[i]);
            s.pendingWithdrawals[_receivers[i]][s.feeToken] += _share;
            unchecked {
                i++;
            }
        }
    }
}
