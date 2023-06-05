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
error DepositFacet__InvalidMiningPass();

/// @title DepositFacet
/// @notice Facet in charge of depositing VPND tokens
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LPercentages'
contract DepositFacet {
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
        UserData storage _userDataForLastSeasonParticipated = s.usersData[s.addressToLastSeasonId[msg.sender]][
            msg.sender
        ];

        bool isNewSeasonForUser = s.addressToLastSeasonId[msg.sender] != 0 &&
            _userDataForCurrentSeason.depositAmount == 0;

        bool isFundsInPrevSeason = isNewSeasonForUser &&
            (_userDataForLastSeasonParticipated.unlockAmount > 0 ||
                _userDataForLastSeasonParticipated.hasWithdrawnOrRestaked == false);
        if (
            _currentSeasonUserData.depositAmount + _amount >
            s.miningPassTierToDepositLimit[_currentSeasonUserData.miningPassTier]
        ) {
            revert DepositFacet__InvalidMiningPass();
        }

        if (isFundsInPrevSeason) {
            revert DepositFacet__FundsInPrevSeason();
        }
        if (isNewSeasonForUser) {
            _userDataForCurrentSeason.lastBoostClaimTimestamp = block.timestamp; //BoostFacet#_calculatePoints over/underflow fix
        }
        //effects
        uint256 _discount = 0;
        s.addressToLastSeasonId[msg.sender] = _currentSeasonId;

        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _discount = s.depositDiscountForStratosphereMembers[tier];
        }

        _applyPoints(_amount);

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
