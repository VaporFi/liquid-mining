// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDateTime } from "./libraries/LDateTime.sol";

interface ILiquidMiningDiamond {
    function getSeasonEndTimestamp(uint256 seasonId) external view returns (uint256);

    function getCurrentSeasonId() external view returns (uint256);

    function getSeasonIsClaimed(uint256 seasonId) external view returns (bool);

    function startNewSeasonWithEndTimestamp(uint256 _rewardTokenToDistribute, uint256 _endTimestamp) external;

    function claimTokensForSeason() external;
}

contract GelatoResolver {
    ILiquidMiningDiamond public immutable liquidMiningDiamond;

    constructor(ILiquidMiningDiamond _liquidMiningDiamond) {
        liquidMiningDiamond = _liquidMiningDiamond;
    }

    /// @notice Calculates the reward for a given season
    /// @dev The reward is calculated by multiplying the initial reward with a reduction factor of 0.41217% per season
    /// @dev The inital reward for the 1st season is 15,000 tokens, with 18 decimals
    /// @param seasonId The season ID
    /// @return The reward for the given season
    function calculateReward(uint256 seasonId) public pure returns (uint256) {
        uint256 initialReward = 15000 * 10 ** 18; // 15,000 tokens, with 18 decimals
        uint256 reductionFactor = (100000 - 412) * 10 ** 18; // 0.412% reduction per season, with 18 decimals
        for (uint256 i = 0; i < seasonId - 1; i++) {
            initialReward = (initialReward * reductionFactor) / (100000 * 10 ** 18);
        }
        return initialReward;
    }

    function isLeapYear(uint256 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        } else if (year % 100 != 0) {
            return true;
        } else if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function getNextMonthFirstDayTimestamp() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        LDateTime._DateTime memory dateTime = LDateTime.parseTimestamp(currentTime);

        uint16 year = dateTime.year;
        uint8 month = dateTime.month;

        if (month == 12) {
            year += 1;
            month = 1;
        } else {
            month += 1;
        }

        return LDateTime.toTimestamp(year, month, 1);
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        uint256 currentSeasonId = liquidMiningDiamond.getCurrentSeasonId();
        uint256 currentSeasonEndTimestamp = liquidMiningDiamond.getSeasonEndTimestamp(currentSeasonId);
        bool currentSeasonIsClaimed = liquidMiningDiamond.getSeasonIsClaimed(currentSeasonId);

        if (currentSeasonIsClaimed && block.timestamp > currentSeasonEndTimestamp) {
            uint256 nextSeasonReward = calculateReward(currentSeasonId + 1);
            uint256 nextMonthFirstDayTimestamp = getNextMonthFirstDayTimestamp();

            execPayload = abi.encodeCall(
                ILiquidMiningDiamond.startNewSeasonWithEndTimestamp,
                (nextSeasonReward, nextMonthFirstDayTimestamp)
            );
            return (true, execPayload);
        }

        return (false, bytes("Current season is not over yet"));
    }
}
