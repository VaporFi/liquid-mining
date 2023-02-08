// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRewardsController {
    function tierOf(bytes32 program, uint256 tokenId) external view returns (uint256);
}
