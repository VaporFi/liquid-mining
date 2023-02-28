// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../interfaces/IRewardsController.sol";

contract RewardsControllerMock is IRewardsController {
    function tierOf(bytes32 program, uint256 tokenId) external view returns (uint256) {
        if (tokenId == 0 || tokenId > 3) {
            return 0;
        } else {
            return tokenId;
        }
    }
}
