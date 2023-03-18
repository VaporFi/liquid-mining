// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../interfaces/IStratosphere.sol";
import "lib/forge-std/src/Test.sol";

contract StratosphereMock is IStratosphere, Test {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");
    address stratosphereMemberSilver = makeAddr("stratosphereMemberSilver");
    address stratosphereMemberGold = makeAddr("stratosphereMemberGold");

    function tokenIdOf(address account) external view returns (uint256) {
        if (account == stratosphereMemberBasic) {
            return 1;
        } else if (account == stratosphereMemberSilver) {
            return 2;
        } else if (account == stratosphereMemberGold) {
            return 3;
        } else {
            return 0;
        }
    }

    function tierOf(uint256 tokenId) external pure returns (uint8) {
        if (tokenId == 0 || tokenId > 3) {
            return 0;
        } else {
            return uint8(tokenId);
        }
    }
}
