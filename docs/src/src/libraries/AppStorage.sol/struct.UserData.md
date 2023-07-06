# UserData
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/libraries/AppStorage.sol)


```solidity
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
```

