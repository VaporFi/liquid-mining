// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";

contract DepositFacet {
    AppStorage internal s;

    error DepositFacet__NotEnoughTokenBalance();
    error DepositFacet__InvalidFeeReceivers();

    /// @notice Deposit token to the contract
    /// @param _amount Amount of token to deposit
    function deposit(uint256 _amount) external {
        // check if user has enough token balance
        if (_amount > s.depositToken.balanceOf(msg.sender)) {
            revert(DepositFacet__NotEnoughTokenBalance());
        }
        uint256 _fee = LPercentages.percentage(_amount, s.depositFee);
        s.totalDepositAmounts[s.currentSeasonId] += (_amount - _fee);
        _applyDepositFee(_fee);
    }

    /// @notice Apply deposit fee
    /// @param _fee Fee amount
    function _applyDepositFee(uint256 _fee) internal {
        if (s.depositFeeReceivers.length != s.depositFeeReceiversShares.length) {
            revert(DepositFacet__InvalidFeeReceivers());
        }
        uint256 _length = s.depositFeeReceivers.length;
        IERC20 _token = IERC20(s.depositToken);
        for (uint256 i; i < _length;) {
            // TODO: add Stratosphere fee discounts
            uint256 _share = LPercentages.percentage(_fee, s.depositFeeReceiversShares[i]);
            _token.transferFrom(msg.sender, s.depositFeeReceivers[i], _share);
            unchecked {
                i++;
            }
        }
    }
}
