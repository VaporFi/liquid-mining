# AppStorage
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/libraries/AppStorage.sol)


```solidity
struct AppStorage {
    mapping(address => bool) authorized;
    bool paused;
    uint256 currentSeasonId;
    uint256 seasonsCount;
    mapping(uint256 => Season) seasons;
    mapping(uint256 => mapping(address => UserData)) usersData;
    uint256 depositFee;
    address depositToken;
    address[] depositFeeReceivers;
    address[] depositFeeReceiversShares;
    mapping(uint256 => mapping(address => uint256)) depositAmounts;
    mapping(uint256 => uint256) totalDepositAmounts;
    uint256 claimFee;
    address rewardToken;
    mapping(uint256 => mapping(address => uint256)) claimAmounts;
    mapping(uint256 => uint256) totalClaimAmounts;
}
```

