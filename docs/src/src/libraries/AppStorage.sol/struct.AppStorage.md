# AppStorage
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/libraries/AppStorage.sol)


```solidity
struct AppStorage {
    mapping(address => bool) authorized;
    bool paused;
    uint256 currentSeasonId;
    uint256 seasonsCount;
    mapping(uint256 => Season) seasons;
    mapping(uint256 => mapping(address => UserData)) usersData;
    uint256 depositFee;
    address[] depositFeeReceivers;
    uint256[] depositFeeReceiversShares;
    uint256 unlockFee;
    mapping(uint256 => uint256) unlockTimestampDiscountForStratosphereMembers;
    mapping(uint256 => uint256) unlockFeeDiscountForStratosphereMembers;
    mapping(uint256 => uint256) depositDiscountForStratosphereMembers;
    mapping(uint256 => uint256) restakeDiscountForStratosphereMembers;
    mapping(address => uint256) addressToLastSeasonId;
    address[] unlockFeeReceivers;
    uint256[] unlockFeeReceiversShares;
    address boostFeeToken;
    mapping(uint256 => uint256) boostLevelToFee;
    mapping(uint256 => mapping(uint256 => uint256)) boostPercentFromTierToLevel;
    address[] boostFeeReceivers;
    uint256[] boostFeeReceiversShares;
    uint256 claimFee;
    address[] claimFeeReceivers;
    uint256[] claimFeeReceiversShares;
    uint256 restakeFee;
    mapping(uint256 => mapping(address => uint256)) claimAmounts;
    mapping(uint256 => uint256) totalClaimAmounts;
    address[] restakeFeeReceivers;
    uint256[] restakeFeeReceiversShares;
    address depositToken;
    address rewardToken;
    address stratosphereAddress;
    uint256 reentrancyGuardStatus;
    mapping(address => mapping(address => uint256)) pendingWithdrawals;
}
```

