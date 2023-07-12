# AppStorage
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/libraries/AppStorage.sol)


```solidity
struct AppStorage {
    mapping(address => bool) authorized;
    bool paused;
    uint256 currentSeasonId;
    uint256 seasonsCount;
    mapping(uint256 => Season) seasons;
    mapping(uint256 => mapping(address => UserData)) usersData;
    uint256 unlockFee;
    mapping(uint256 => uint256) unlockTimestampDiscountForStratosphereMembers;
    mapping(address => uint256) addressToLastSeasonId;
    address[] unlockFeeReceivers;
    uint256[] unlockFeeReceiversShares;
    uint256 boostForNonStratMembers;
    mapping(uint256 => uint256) boostLevelToFee;
    mapping(uint256 => mapping(uint256 => uint256)) boostPercentFromTierToLevel;
    address[] boostFeeReceivers;
    uint256[] boostFeeReceiversShares;
    mapping(address => mapping(address => uint256)) pendingWithdrawals;
    mapping(uint256 => uint256) miningPassTierToFee;
    mapping(uint256 => uint256) miningPassTierToDepositLimit;
    address[] miningPassFeeReceivers;
    uint256[] miningPassFeeReceiversShares;
    address depositToken;
    address rewardToken;
    address feeToken;
    address stratosphereAddress;
    uint256 reentrancyGuardStatus;
    address emissionsManager;
}
```

