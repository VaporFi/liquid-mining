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
    uint256 lastBoostClaimAmount;
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
    address[] depositFeeReceivers;
    uint256[] depositFeeReceiversShares;
    ///////////////
    /// UNLOCK ///
    ///////////////
    uint256 unlockFee;
    // mapping: tier => discount percentage
    mapping(uint256 => uint256) unlockTimestampDiscountForStratosphereMembers;
    mapping(uint256 => uint256) unlockFeeDiscountForStratosphereMembers;
    mapping(uint256 => uint256) depositDiscountForStratosphereMembers;
    mapping(uint256 => uint256) restakeDiscountForStratosphereMembers;
    // mapping: user => lastSeasonParticipated
    mapping(address => uint256) addressToLastSeasonId;
    address[] unlockFeeReceivers;
    uint256[] unlockFeeReceiversShares;
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
    address[] boostFeeReceivers;
    uint256[] boostFeeReceiversShares;
    /////////////
    /// CLAIM ///
    /////////////
    uint256 claimFee;
    address[] claimFeeReceivers;
    uint256[] claimFeeReceiversShares;
    ///////////////
    /// RESTAKE ///
    ///////////////
    uint256 restakeFee;
    // nested mapping: seasonId => userAddress => amount
    mapping(uint256 => mapping(address => uint256)) claimAmounts;
    // total amount claimed for each season: seasonId => amount
    mapping(uint256 => uint256) totalClaimAmounts;
    address[] restakeFeeReceivers;
    uint256[] restakeFeeReceiversShares;
    ///////////////
    /// GENERAL ///
    ///////////////
    address depositToken;
    address rewardToken;
    address stratosphereAddress;
    uint256 reentrancyGuardStatus;
    // nested mapping: userAddress => tokenAddress => amount
    mapping(address => mapping(address => uint256)) pendingWithdrawals;
    // Upgrade
    uint256 boostForNonStratMembers;
}
