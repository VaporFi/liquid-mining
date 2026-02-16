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
    /// @dev deprecated - preserved for storage layout compatibility with 14f06c0 deployment
    mapping(uint256 => uint256) __deprecated_unlockFeeDiscount; // slot 8
    mapping(uint256 => uint256) __deprecated_depositDiscount; // slot 9
    mapping(uint256 => uint256) __deprecated_restakeDiscount; // slot 10
    // mapping: user => lastSeasonParticipated
    mapping(address => uint256) addressToLastSeasonId; // slot 11
    address[] unlockFeeReceivers; // slot 12
    uint256[] unlockFeeReceiversShares; // slot 13
    ////////////////
    /// BOOST ///
    ////////////////
    uint256 boostForNonStratMembers; // slot 14
    //mapping: level => USDC fee
    mapping(uint256 => uint256) boostLevelToFee; // slot 15
    // nested mapping: tier => boostlevel => boost enhance points
    mapping(uint256 => mapping(uint256 => uint256)) boostPercentFromTierToLevel; // slot 16
    address[] boostFeeReceivers; // slot 17
    uint256[] boostFeeReceiversShares; // slot 18
    ///////////////
    /// RESTAKE (deprecated) ///
    ///////////////
    /// @dev deprecated - preserved for storage layout compatibility with 14f06c0 deployment
    uint256 __deprecated_restakeFee; // slot 19
    mapping(uint256 => mapping(address => uint256)) __deprecated_claimAmounts; // slot 20
    mapping(uint256 => uint256) __deprecated_totalClaimAmounts; // slot 21
    ////////////////
    /// WITHDRAW ///
    ////////////////
    // nested mapping: userAddress => tokenAddress => amount
    mapping(address => mapping(address => uint256)) pendingWithdrawals; // slot 22
    ///////////////////
    /// MINING PASS ///
    ///////////////////
    //mapping: level => USDC fee
    mapping(uint256 => uint256) miningPassTierToFee; // slot 23
    mapping(uint256 => uint256) miningPassTierToDepositLimit; // slot 24
    ///////////////
    /// GENERAL ///
    ///////////////
    address depositToken; // slot 25
    address rewardToken; // slot 26
    address feeToken; // slot 27
    address stratosphereAddress; // slot 28
    uint256 reentrancyGuardStatus; // slot 29
    address emissionsManager; // slot 30
    /////////////////////////////////////////
    /// MINING PASS (extended) - appended ///
    /////////////////////////////////////////
    address[] miningPassFeeReceivers; // slot 31
    uint256[] miningPassFeeReceiversShares; // slot 32
    /// @dev Base fees (original fees set at deployment, used for floor price calculation)
    mapping(uint256 => uint256) baseMiningPassTierToFee; // slot 33
    /// @dev Floor price percentage in basis points (e.g., 2500 = 25%)
    uint256 miningPassFeeFloorBps; // slot 34
    //////////////////
    /// AUTOMATION ///
    //////////////////
    address gelatoExecutor; // slot 35
    mapping(uint256 => bool) isSeasonClaimed; // slot 36
}
