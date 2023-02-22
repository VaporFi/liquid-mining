// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev rewardTokenToDistribute is the amount of reward token to distribute to users
/// @dev rewardTokenBalance is the amount of reward token that is currently in the contract
struct Season {
    uint256 id;
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 rewardTokensToDistribute;
    uint256 rewardTokenBalance;
    uint256 totalDepositAmount;
    uint256 totalClaimAmount;
    uint256 totalPoints;
    uint256 depositFee;
    uint256 restakeFee;
}

struct UserData {
    uint256 depositAmount;
    uint256 claimAmount;
    uint256 depositPoints;
    uint256 boostPoints;
    uint256 lastBoostClaimTimestamp;
    uint256 unlockAmount;
    uint256 unlockTimestamp;
    bool hasWithdrawnOrRestaked;
    bool hasClaimed;
}

struct AppStorage {
    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////
    mapping(address => bool) authorized;
    /////////////////
    /// PAUSATION ///
    /////////////////
    bool paused;
    //////////////
    /// SEASON ///
    //////////////
    uint256 currentSeasonId;
    uint256 seasonsCount;
    mapping(uint256 => Season) seasons;
    // nested mapping: seasonId => userAddress => UserData
    mapping(uint256 => mapping(address => UserData)) usersData;
    ///////////////
    /// DEPOSIT ///
    ///////////////
    uint256 depositFee;
    address depositToken;
    address[] depositFeeReceivers;
    uint256[] depositFeeReceiversShares;
    mapping(address => uint256) pendingWithdrawals;
    mapping(uint256 => uint256) depositDiscountForStratosphereMembers;
    // mapping: user => lastSeasonParticipated
    mapping(address => uint256) addressToLastSeasonId;
    ////////////////
    /// WITHDRAW ///
    ////////////////
    // TODO: Add withdraw state variables

    /////////////
    /// CLAIM ///
    /////////////
    uint256 claimFee;
    address rewardToken;
    // nested mapping: seasonId => userAddress => amount
    mapping(uint256 => mapping(address => uint256)) claimAmounts;
    // total amount claimed for each season: seasonId => amount
    mapping(uint256 => uint256) totalClaimAmounts;
    ///////////////
    /// GENERAL ///
    ///////////////
    address stratoshpereAddress;
    address rewardsControllerAddress;
}
