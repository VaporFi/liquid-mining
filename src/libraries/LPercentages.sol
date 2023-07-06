// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LPercentages {
    /// @notice Calculates the percentage of a number using basis points
    /// @dev 1% = 100 basis points
    /// @param _number Number
    /// @param _percentage Percentage in bps
    /// @return Percentage of a number
    function percentage(uint256 _number, uint256 _percentage) internal pure returns (uint256) {
        return (_number * _percentage) / 10_000;
    }
}
