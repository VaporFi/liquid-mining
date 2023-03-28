# UserData
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/libraries/AppStorage.sol)


```solidity
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
```

