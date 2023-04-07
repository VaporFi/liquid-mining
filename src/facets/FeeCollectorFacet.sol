// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";

/// @title FeeCollectorFacet
/// @notice Facet in charge of collecting fees
/// @dev Utilizes 'LDiamond' and 'AppStorage'
contract FeeCollectorFacet {
    AppStorage s;
    error FeeCollectorFacet__Only_Owner();

    modifier onlyOwner() {
        if (msg.sender != LDiamond.contractOwner()) revert FeeCollectorFacet__Only_Owner();
        _;
    }

    /// @notice Transfer the collected fees to the fee receivers
    function collectBoostFees() external onlyOwner {
        address[] storage _receivers = s.boostFeeReceivers;
        uint256 _length = _receivers.length;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][s.boostFeeToken];
            s.pendingWithdrawals[_receivers[i]][s.boostFeeToken] = 0;

            IERC20(s.boostFeeToken).transfer(_receivers[i], amount);
        }
    }

    function collectClaimFees() external onlyOwner {
        address[] storage _receivers = s.claimFeeReceivers;
        uint256 _length = _receivers.length;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][s.rewardToken];
            s.pendingWithdrawals[_receivers[i]][s.rewardToken] = 0;

            IERC20(s.rewardToken).transfer(_receivers[i], amount);
        }
    }

    function collectDepositFees() external onlyOwner {
        address[] storage _receivers = s.depositFeeReceivers;
        uint256 _length = _receivers.length;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][s.depositToken];
            s.pendingWithdrawals[_receivers[i]][s.depositToken] = 0;

            IERC20(s.depositToken).transfer(_receivers[i], amount);
        }
    }

    function collectRestakeFees() external onlyOwner {
        address[] storage _receivers = s.restakeFeeReceivers;
        uint256 _length = _receivers.length;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][s.depositToken];
            s.pendingWithdrawals[_receivers[i]][s.depositToken] = 0;

            IERC20(s.depositToken).transfer(_receivers[i], amount);
        }
    }

    function collectUnlockFees() external onlyOwner {
        address[] storage _receivers = s.unlockFeeReceivers;
        uint256 _length = _receivers.length;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][s.depositToken];
            s.pendingWithdrawals[_receivers[i]][s.depositToken] = 0;

            IERC20(s.depositToken).transfer(_receivers[i], amount);
        }
    }
}
