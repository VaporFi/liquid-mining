// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/VAPE.sol";

contract VAPETest is Test {
    /////////////////
    /// VARIABLES ///
    /////////////////

    VAPE vape;

    address constant STAKING = address(99);

    address constant OWNER = address(0);
    address constant ALICE = address(1);
    address constant BOB = address(2);

    /////////////
    /// LOGIC ///
    /////////////

    function setUp() public {
        vape = new VAPE(STAKING);
    }

    function testTokenDecimals() public {}

    function testTokenMaxSupply() public {}

    function testTokenMintOnlyStaking() public {}

    function testTokenMint() public {}

    function testTokenTransfer() public {}
}
