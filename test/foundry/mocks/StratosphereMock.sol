// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "src/interfaces/IStratosphere.sol";

contract StratosphereMock is IStratosphere, Test {
    // StdCheats cheats = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address stratosphereMemberBasic = makeAddr("stratosphereMemberBasic");
    address stratosphereMemberSilver = makeAddr("stratosphereMemberSilver");
    address stratosphereMemberGold = makeAddr("stratosphereMemberGold");
    address stratosphereMemberPlatinum = makeAddr("stratosphereMemberPlatinum");
    address stratosphereMemberDiamond = makeAddr("stratosphereMemberDiamond");
    address stratosphereMemberObsidian = makeAddr("stratosphereMemberObsidian");

    function tokenIdOf(address account) external view returns (uint256) {
        if (account == stratosphereMemberBasic) {
            return 1;
        } else if (account == stratosphereMemberSilver) {
            return 2;
        } else if (account == stratosphereMemberGold) {
            return 3;
        } else if (account == stratosphereMemberPlatinum) {
            return 4;
        } else if (account == stratosphereMemberDiamond) {
            return 5;
        } else if (account == stratosphereMemberObsidian) {
            return 6;
        } else {
            return 0;
        }
    }

    function tierOf(uint256 tokenId) external pure returns (uint8 _tier) {
        if (tokenId == 1) {
            _tier = 0;
        } else if (tokenId == 2) {
            _tier = 1;
        } else if (tokenId == 3) {
            _tier = 2;
        } else if (tokenId == 4) {
            _tier = 3;
        } else if (tokenId == 5) {
            _tier = 4;
        } else if (tokenId == 6) {
            _tier = 5;
        } else {
            _tier = uint8(tokenId - 1);
        }
    }
}
