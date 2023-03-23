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
}

struct UserData {
    uint256 depositAmount;
    uint256 claimAmount;
    uint256 depositPoints;
    uint256 boostPoints;
    uint256 lastBoostClaimTimestamp;
    uint256 unlockAmount;
    uint256 unlockTimestamp;
    uint256 amountClaimed;
    bool hasWithdrawnOrRestaked;
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
    address[] feeReceivers;
    uint256[] feeReceiversShares;
    ///////////////
    /// UNLOCK ///
    ///////////////
    uint256 unlockFee;
    // mapping: tier => discount percentage
    mapping(uint256 => uint256) unlockDiscountForStratosphereMembers;
    mapping(address => uint256) pendingWithdrawals;
    mapping(uint256 => uint256) depositDiscountForStratosphereMembers;
    mapping(uint256 => uint256) restakeDiscountForStratosphereMembers;
    // mapping: user => lastSeasonParticipated
    mapping(address => uint256) addressToLastSeasonId;
    ////////////////
    /// WITHDRAW ///
    ////////////////
    // TODO: Add withdraw state variables

    ////////////////
    /// BOOST ///
    ////////////////
    address boostFeeToken;
    //mapping: level => USDC fee
    mapping(uint256 => uint256) boostLevelToFee;
    // nested mapping: tier => boostlevel => boost enhance points
    mapping(uint256 => mapping(uint256 => uint256)) boostPercentFromTierToLevel;
    /////////////
    /// CLAIM ///
    /////////////
    uint256 claimFee;
    ///////////////
    /// RESTAKE ///
    ///////////////
    uint256 restakeFee;
    address rewardToken;
    // nested mapping: seasonId => userAddress => amount
    mapping(uint256 => mapping(address => uint256)) claimAmounts;
    // total amount claimed for each season: seasonId => amount
    mapping(uint256 => uint256) totalClaimAmounts;
    ///////////////
    /// GENERAL ///
    ///////////////
    address stratosphereAddress;
    address rewardsControllerAddress;
    uint256 reentrancyGuardStatus;
}
