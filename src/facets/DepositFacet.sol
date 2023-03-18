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
    event Deposit(address indexed depositor, uint256 amount);

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
        IERC20 _token = IERC20(s.depositToken);
        // checks
        if (_amount > IERC20(_token).balanceOf(msg.sender)) {
            revert DepositFacet__NotEnoughTokenBalance();
        }
        uint256 lastSeasonParticipated = s.addressToLastSeasonId[msg.sender];

        if (
            s.usersData[lastSeasonParticipated][msg.sender].unlockAmount > 0 ||
            s.usersData[lastSeasonParticipated][msg.sender].hasWithdrawnOrRestaked == false
        ) {
            revert DepositFacet__FundsInPrevSeason();
        }

        //effects
        uint256 _discount = 0;
        s.addressToLastSeasonId[msg.sender] = s.currentSeasonId;
        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _discount = s.depositDiscountForStratosphereMembers[tier];
        }
        uint256 _fee = LPercentages.percentage(_amount, s.depositFee - (_discount * s.depositFee) / 10000);
        uint256 _amountMinusFee = _amount - _fee;
        _applyPoints(_amountMinusFee);
        _applyDepositFee(_fee);
        emit Deposit(msg.sender, _amount);

        //interactions
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Apply points
    /// @param _amount Amount of token to apply points
    function _applyPoints(uint256 _amount) internal {
        uint256 _seasonId = s.currentSeasonId;
        if (block.timestamp > s.seasons[_seasonId].endTimestamp) {
            revert DepositFacet__SeasonEnded();
        }
        uint256 _daysUntilSeasonEnd = (s.seasons[_seasonId].endTimestamp - block.timestamp) / 1 days;
        UserData storage _userData = s.usersData[_seasonId][msg.sender];
        _userData.depositAmount += _amount;
        _userData.depositPoints += _amount * _daysUntilSeasonEnd;
        s.seasons[_seasonId].totalDepositAmount += _amount;
        s.seasons[_seasonId].totalPoints += _amount * _daysUntilSeasonEnd;
    }

    /// @notice Apply deposit fee
    /// @param _fee Fee amount
    function _applyDepositFee(uint256 _fee) internal {
        if (s.feeReceivers.length != s.feeReceiversShares.length) {
            revert DepositFacet__InvalidFeeReceivers();
        }
        uint256 _length = s.feeReceivers.length;
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, s.feeReceiversShares[i]);
            s.pendingWithdrawals[s.feeReceivers[i]] += _share;
            unchecked {
                i++;
            }
        }
    }
}
