// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../libraries/LStratosphere.sol";

error DepositFacet__NotEnoughTokenBalance();
error DepositFacet__ReentrancyGuard__ReentrantCall();
error DepositFacet__SeasonEnded();
error DepositFacet__FundsInPrevSeason();
error DepositFacet__InvalidMiningPass(uint256 tier);

/// @title DepositFacet
/// @notice Facet in charge of depositing VPND tokens
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LPercentages'
contract DepositFacet {
    event Deposit(address indexed depositor, uint256 amount, uint256 seasonId);

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
        // checks
        if (_amount > _depositToken.balanceOf(msg.sender)) {
            revert DepositFacet__NotEnoughTokenBalance();
        }
        // check depositAmount + deposit is not greater than MiningPass's deposit limit
        uint256 _currentSeasonId = s.currentSeasonId;
        UserData memory _currentSeasonUserData = s.usersData[_currentSeasonId][msg.sender];
        if (
            _currentSeasonUserData.depositAmount + _amount >
            s.miningPassTierToDepositLimit[_currentSeasonUserData.miningPassTier] * 1e18
        ) {
            revert DepositFacet__InvalidMiningPass(_currentSeasonUserData.miningPassTier);
        }

        uint256 lastSeasonParticipated = s.addressToLastSeasonId[msg.sender];
        bool isNewSeasonForUser = lastSeasonParticipated != 0 && _currentSeasonUserData.depositAmount == 0;
        bool isFundsInPrevSeason = isNewSeasonForUser &&
            (s.usersData[lastSeasonParticipated][msg.sender].unlockAmount > 0 ||
                s.usersData[lastSeasonParticipated][msg.sender].hasWithdrawnOrRestaked == false);

        if (isFundsInPrevSeason) {
            revert DepositFacet__FundsInPrevSeason();
        }

        // effects
        uint256 _discount = 0;
        s.addressToLastSeasonId[msg.sender] = _currentSeasonId;
        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _discount = s.depositDiscountForStratosphereMembers[tier];
        }
        _applyPoints(_amount);

        // interactions
        _depositToken.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount, _currentSeasonId);
    }

    /// @notice Apply points
    /// @param _amount Amount of token to apply points
    function _applyPoints(uint256 _amount) internal {
        uint256 _seasonId = s.currentSeasonId;
        Season storage _season = s.seasons[_seasonId];

        if (block.timestamp > _season.endTimestamp) {
            revert DepositFacet__SeasonEnded();
        }

        uint256 _daysUntilSeasonEnd = (_season.endTimestamp - block.timestamp) / 1 days;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        _userData.depositAmount += _amount;
        _userData.depositPoints += _amount * _daysUntilSeasonEnd;
        _season.totalDepositAmount += _amount;
        _season.totalPoints += _amount * _daysUntilSeasonEnd;
    }
}
