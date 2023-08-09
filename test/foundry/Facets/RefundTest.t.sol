pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { DiamondTest, LiquidMiningDiamond } from "../utils/DiamondTest.sol";
import { ClaimFacet, ClaimFacet__NotEnoughPoints, ClaimFacet__InProgressSeason, ClaimFacet__AlreadyClaimed } from "src/facets/ClaimFacet.sol";

//JUST FOR ILLUSTRATION PURPOSE

contract RefundTest is Test {
    string public MAINNET_RPC_URL = vm.envString("AVALANCHE_RPC_URL");
    address public liquidMiningDiamondAddress = 0xAe950fdd0CC79DDE64d3Fffd40fabec3f7ba368B;
    ClaimFacet public claimfacet;

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL, 33696496);
        claimfacet = ClaimFacet(liquidMiningDiamondAddress);

        
    }

    function test_claim() public {
        vm.startPrank(0xb246A2a842EadF307cF4d076A81367fb3E369963);
        claimfacet.automatedClaim(1, 0x8734382c5E988c1EE1c750b16d5D1feFd3423b09);
    }

}