// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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
    uint256 miningPassTier;
    bool hasWithdrawnOrRestaked;
}

struct AppStorage {
    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////
    mapping(address => bool) authorized; // slot 0
    /////////////////
    /// PAUSATION ///
    /////////////////
    bool paused; // slot 1
    //////////////
    /// SEASON ///
    //////////////
    uint256 currentSeasonId; // slot 2
    uint256 seasonsCount; // slot 3
    mapping(uint256 => Season) seasons; // slot 4
    // nested mapping: seasonId => userAddress => UserData
    mapping(uint256 => mapping(address => UserData)) usersData; // slot 5
    ///////////////
    /// UNLOCK ///
    ///////////////
    uint256 unlockFee; // slot 6
    // mapping: tier => discount percentage
    mapping(uint256 => uint256) unlockTimestampDiscountForStratosphereMembers; // slot 7
    // mapping: user => lastSeasonParticipated
    mapping(address => uint256) addressToLastSeasonId; // slot 8
    address[] unlockFeeReceivers; // slot 9
    uint256[] unlockFeeReceiversShares; // slot 10
    ////////////////
    /// BOOST ///
    ////////////////
    uint256 boostForNonStratMembers; // slot 11
    //mapping: level => USDC fee
    mapping(uint256 => uint256) boostLevelToFee; // slot 12
    // nested mapping: tier => boostlevel => boost enhance points
    mapping(uint256 => mapping(uint256 => uint256)) boostPercentFromTierToLevel; // slot 13
    address[] boostFeeReceivers; // slot 14
    uint256[] boostFeeReceiversShares; // slot 15
    ////////////////
    /// WITHDRAW ///
    ////////////////
    // nested mapping: userAddress => tokenAddress => amount
    mapping(address => mapping(address => uint256)) pendingWithdrawals; // slot 16
    ///////////////////
    /// MINING PASS ///
    ///////////////////
    //mapping: level => USDC fee
    mapping(uint256 => uint256) miningPassTierToFee; // slot 17
    mapping(uint256 => uint256) miningPassTierToDepositLimit; // slot 18
    address[] miningPassFeeReceivers; // slot 19
    uint256[] miningPassFeeReceiversShares; // slot 20
    ///////////////
    /// GENERAL ///
    ///////////////
    address depositToken; // slot 21
    address rewardToken; // slot 22
    address feeToken; // slot 23
    address stratosphereAddress; // slot 24
    uint256 reentrancyGuardStatus; // slot 25
    address emissionsManager; // slot 26
    //////////////////////////////////////////
    /// DYNAMIC PRICING (appended safely) ///
    //////////////////////////////////////////
    /// @dev Base fees (original fees set at deployment, used for floor price calculation)
    mapping(uint256 => uint256) baseMiningPassTierToFee; // slot 27
    /// @dev Floor price percentage in basis points (e.g., 2500 = 25%)
    uint256 miningPassFeeFloorBps; // slot 28
    //////////////////
    /// AUTOMATION ///
    //////////////////
    address gelatoExecutor; // slot 29
    mapping(uint256 => bool) isSeasonClaimed; // slot 30
}
