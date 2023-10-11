// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { GelatoResolver, ILiquidMiningDiamond } from "src/GelatoResolver.sol";

contract GelatoResolverTest is Test {
    GelatoResolver gelatoResolver;
    ILiquidMiningDiamond liquidMiningDiamond = ILiquidMiningDiamond(makeAddr("LiquidMiningDiamond"));
    uint256 mainnetFork;

    function setUp() public {
        // vm.createSelectFork(vm.rpcUrl("avalanche"));
        gelatoResolver = new GelatoResolver(liquidMiningDiamond);
    }

    function test_calculateReward() public {
        uint256 seasonId = 1;
        uint256 expectedReward = 15000 * 10 ** 18;
        uint256 actualReward = gelatoResolver.calculateReward(seasonId);
        assertEq(actualReward, expectedReward);

        seasonId = 2;
        expectedReward = 14938200000000000000000;
        actualReward = gelatoResolver.calculateReward(seasonId);
        assertEq(actualReward, expectedReward);

        seasonId = 3;
        expectedReward = 14876654616000000000000;
        actualReward = gelatoResolver.calculateReward(seasonId);
        assertEq(actualReward, expectedReward);

        seasonId = 4;
        expectedReward = 14815362798982080000000;
        actualReward = gelatoResolver.calculateReward(seasonId);
        assertEq(actualReward, expectedReward);

        seasonId = 5;
        expectedReward = 14754323504250273830400;
        actualReward = gelatoResolver.calculateReward(seasonId);
        assertEq(actualReward, expectedReward);
    }

    function test_getNextMonthFirstDayTimestamp() public {
        vm.warp(1696118400); // 2023-10-01 00:00:00
        uint256 expectedTimestamp = 1698796800; // 2023-11-01 00:00:00
        uint256 actualTimestamp = gelatoResolver.getNextMonthFirstDayTimestamp();
        assertEq(actualTimestamp, expectedTimestamp);

        vm.warp(1701388800); // 2023-12-01 00:00:00
        expectedTimestamp = 1704067200; // 2024-01-01 00:00:00
        actualTimestamp = gelatoResolver.getNextMonthFirstDayTimestamp();
        assertEq(actualTimestamp, expectedTimestamp);

        vm.warp(1704067200); // 2024-01-01 00:00:00
        expectedTimestamp = 1706745600; // 2024-02-01 00:00:00
        actualTimestamp = gelatoResolver.getNextMonthFirstDayTimestamp();
        assertEq(actualTimestamp, expectedTimestamp);

        vm.warp(1706745600); // 2024-02-01 00:00:00
        expectedTimestamp = 1709251200; // 2024-03-01 00:00:00 (Leap Year)
        actualTimestamp = gelatoResolver.getNextMonthFirstDayTimestamp();
        assertEq(actualTimestamp, expectedTimestamp);
    }
}
