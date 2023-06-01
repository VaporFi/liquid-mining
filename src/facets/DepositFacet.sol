// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";
import "../interfaces/IStratosphere.sol";
import "../libraries/LStratosphere.sol";

error DepositFacet__NotEnoughTokenBalance();
error DepositFacet__InvalidFeeReceivers();
error DepositFacet__ReentrancyGuard__ReentrantCall();
error DepositFacet__SeasonEnded();
error DepositFacet__FundsInPrevSeason();

/// @title DepositFacet
/// @notice Facet in charge of depositing VPND tokens
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LPercentages'
contract DepositFacet {
    event Deposit(address indexed depositor, uint256 amount, uint256 seasonId, uint256 depositFee);

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
        uint256 _currentSeasonId = s.currentSeasonId;
        IERC20 _token = IERC20(s.depositToken);
        // checks
        if (_amount > IERC20(_token).balanceOf(msg.sender)) {
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

        if (isFundsInPrevSeason) {
            revert DepositFacet__FundsInPrevSeason();
        }
        if (isNewSeasonForUser) {
            _userDataForCurrentSeason.lastBoostClaimTimestamp = block.timestamp; //BoostFacet#_calculatePoints over/underflow fix
        }
        //effects
        s.addressToLastSeasonId[msg.sender] = _currentSeasonId;

        uint256 _fee = _getDepositFee(_amount);
        uint256 _amountMinusFee = _amount - _fee;

        _applyPoints(_amountMinusFee, _currentSeasonId, _userDataForCurrentSeason);
        _applyDepositFee(_fee);

        emit Deposit(msg.sender, _amount, _currentSeasonId, _fee);

        //interactions
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    ///@dev self-explainatory
    function _getDepositFee(uint256 _amount) internal view returns (uint256) {
        uint256 _discount = 0;

        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _discount = s.depositDiscountForStratosphereMembers[tier];
        }
        uint256 _depositFeeFromState = s.depositFee;
        uint256 _fee = LPercentages.percentage(
            _amount,
            _depositFeeFromState - (_discount * _depositFeeFromState) / 10000
        );
        return _fee;
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

    /// @notice Apply deposit fee
    /// @param _fee Fee amount
    function _applyDepositFee(uint256 _fee) internal {
        address[] storage _receivers = s.depositFeeReceivers;
        uint256[] storage _shares = s.depositFeeReceiversShares;
        uint256 _length = _receivers.length;

        if (_length != _shares.length) {
            revert DepositFacet__InvalidFeeReceivers();
        }
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, _shares[i]);
            s.pendingWithdrawals[_receivers[i]][s.depositToken] += _share;
            unchecked {
                i++;
            }
        }
    }
}
