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
        address _feeToken = s.feeToken;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][_feeToken];
            s.pendingWithdrawals[_receivers[i]][_feeToken] = 0;

            IERC20(_feeToken).transfer(_receivers[i], amount);
        }
    }

    function collectUnlockFees() external onlyOwner {
        address[] storage _receivers = s.unlockFeeReceivers;
        uint256 _length = _receivers.length;
        address _depositToken = s.depositToken;

        for (uint256 i = 0; i < _length; i++) {
            uint256 amount = s.pendingWithdrawals[_receivers[i]][_depositToken];
            s.pendingWithdrawals[_receivers[i]][_depositToken] = 0;

            IERC20(_depositToken).transfer(_receivers[i], amount);
        }
    }

    // TODO: add minig pass fees
}
