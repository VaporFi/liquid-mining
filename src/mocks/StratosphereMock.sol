// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../interfaces/IStratosphere.sol";
import "lib/forge-std/src/Test.sol";

contract StratosphereMock is IStratosphere, Test {
    StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address stratosphereMemberBasicTierAddress = makeAddr("stratosphere_member_basic");
    address stratosphereMemberSilverTierAddress = makeAddr("stratosphere_member_silver");
    address stratosphereMemberGoldTierAddress = makeAddr("stratosphere_member_gold");

    function tokenIdOf(address account) external view returns (uint256) {
        if (account == stratosphereMemberBasicTierAddress) {
            return 1;
        } else if (account == stratosphereMemberSilverTierAddress) {
            return 2;
        } else if (account == stratosphereMemberGoldTierAddress) {
            return 3;
        } else {
            return 0;
        }
    }
}
