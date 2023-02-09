// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error WithdrawFacet__InvalidAmount();

contract UnlockFacet {
    AppStorage s;

    function unlock(uint256 seasonId, uint256 amount) external {}
}
