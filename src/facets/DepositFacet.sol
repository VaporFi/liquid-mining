// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage, UserData, Season } from "../libraries/AppStorage.sol";
import { LPercentages } from "../libraries/LPercentages.sol";
import { IStratosphere } from "../interfaces/IStratosphere.sol";
import { LStratosphere } from "../libraries/LStratosphere.sol";

error DepositFacet__NotEnoughTokenBalance();
error DepositFacet__ReentrancyGuard__ReentrantCall();
error DepositFacet__SeasonEnded();
error DepositFacet__FundsInPrevSeason();
error DepositFacet__InvalidMiningPass();

/// @title DepositFacet
/// @notice Facet in charge of depositing VPND tokens
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LPercentages'
contract DepositFacet {
    /// @notice Ordering of the events are according to their relevance in the facet
    event Deposit(uint256 indexed seasonId, address indexed user, uint256 amount);

    AppStorage s;

    modifier nonReentrant() {
        if (s.reentrancyGuardStatus == 2) revert DepositFacet__ReentrancyGuard__ReentrantCall();
        s.reentrancyGuardStatus = 2;
        _;
        s.reentrancyGuardStatus = 1;
    }

    /// @notice Deposit token to the contract
    /// @param _amount Amount of token to deposit
    function deposit(uint256 _amount) external nonReentrant {
        IERC20 _depositToken = IERC20(s.depositToken);
        uint256 _currentSeasonId = s.currentSeasonId;
        // checks
        if (_amount > _depositToken.balanceOf(msg.sender)) {
            revert DepositFacet__NotEnoughTokenBalance();
        }

        UserData storage _userDataForCurrentSeason = s.usersData[_currentSeasonId][msg.sender];

        if (
            _userDataForCurrentSeason.depositAmount + _amount >
            s.miningPassTierToDepositLimit[_userDataForCurrentSeason.miningPassTier]
        ) {
            revert DepositFacet__InvalidMiningPass();
        }

        // effects
        if (_userDataForCurrentSeason.depositAmount == 0) {
            _userDataForCurrentSeason.lastBoostClaimTimestamp = block.timestamp; //BoostFacet#_calculatePoints over/underflow fix
        }
        s.addressToLastSeasonId[msg.sender] = _currentSeasonId;

        _applyPoints(_amount, _currentSeasonId, _userDataForCurrentSeason);

        // interactions
        _depositToken.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(_currentSeasonId, msg.sender, _amount);
    }

    /// @notice Apply points
    /// @param _amount Amount of token to apply points
    function _applyPoints(uint256 _amount, uint256 _seasonId, UserData storage _userData) internal {
        Season storage _season = s.seasons[_seasonId];
        if (block.timestamp > _season.endTimestamp) {
            revert DepositFacet__SeasonEnded();
        }
        uint256 _daysUntilSeasonEnd = (_season.endTimestamp - block.timestamp) / 1 days;
        _userData.depositAmount += _amount;
        _userData.depositPoints += _amount * _daysUntilSeasonEnd;
        _season.totalDepositAmount += _amount;
        _season.totalPoints += _amount * _daysUntilSeasonEnd;
    }
}
