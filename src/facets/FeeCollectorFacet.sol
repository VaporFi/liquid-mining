// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage } from "../libraries/AppStorage.sol";

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

    /// @notice Transfer the collected boost fees to the fee receivers
    /// @dev As long as the boostFeeReceivers and miningPassFeeReceivers
    /// @dev are the same, this function can be used to collect both
    function collectBoostFees() external onlyOwner {
        address[] memory _receivers = s.boostFeeReceivers;
        uint256 _length = _receivers.length;
        address _feeToken = s.feeToken;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][_feeToken];
            s.pendingWithdrawals[_receivers[i]][_feeToken] = 0;

            IERC20(_feeToken).transfer(_receivers[i], amount);
        }
    }

    /// @notice Transfer the collected unlock fees to the fee receivers
    function collectUnlockFees() external onlyOwner {
        address[] memory _receivers = s.unlockFeeReceivers;
        uint256 _length = _receivers.length;
        address _depositToken = s.depositToken;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][_depositToken];
            s.pendingWithdrawals[_receivers[i]][_depositToken] = 0;

            IERC20(_depositToken).transfer(_receivers[i], amount);
        }
    }
}
