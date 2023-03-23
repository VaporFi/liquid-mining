// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStratosphere {
    function tokenIdOf(address account) external view returns (uint256);

    function tierOf(uint256 tokenId) external view returns (uint8);
}
