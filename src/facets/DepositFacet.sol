// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";

/// @title DepositFacet
/// @notice Facet in charge of depositing VPND tokens
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LPercentages'
contract DepositFacet {
    error DepositFacet__NotEnoughTokenBalance();
    error DepositFacet__InvalidFeeReceivers();

    AppStorage s;

    /// @notice Deposit token to the contract
    /// @param _amount Amount of token to deposit
    function deposit(uint256 _amount) external {
        // check if user has enough token balance
        if (_amount > IERC20(s.depositToken).balanceOf(msg.sender)) {
            revert DepositFacet__NotEnoughTokenBalance();
        }
        uint256 _fee = LPercentages.percentage(_amount, s.depositFee);
        uint256 _amountMinusFee = _amount - _fee;
        _applyPoints(_amountMinusFee);
        _applyDepositFee(_fee);
    }

    /// @notice Apply points
    /// @param _amount Amount of token to apply points
    function _applyPoints(uint256 _amount) internal {
        uint256 _seasonId = s.currentSeasonId;
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
        if (s.depositFeeReceivers.length != s.depositFeeReceiversShares.length) {
            revert DepositFacet__InvalidFeeReceivers();
        }
        uint256 _length = s.depositFeeReceivers.length;
        IERC20 _token = IERC20(s.depositToken);
        for (uint256 i; i < _length; ) {
            // TODO: add Stratosphere fee discounts
            uint256 _share = LPercentages.percentage(_fee, s.depositFeeReceiversShares[i]);
            _token.transferFrom(msg.sender, s.depositFeeReceivers[i], _share);
            unchecked {
                i++;
            }
        }
    }
}
