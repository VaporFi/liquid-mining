# Season
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/libraries/AppStorage.sol)

*rewardTokenToDistribute is the amount of reward token to distribute to users*

*rewardTokenBalance is the amount of reward token that is currently in the contract*


```solidity
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
```

