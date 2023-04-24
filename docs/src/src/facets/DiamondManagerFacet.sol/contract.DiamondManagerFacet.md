# DiamondManagerFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/DiamondManagerFacet.sol)


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### onlyOwner


```solidity
modifier onlyOwner();
```

### validAddress


```solidity
modifier validAddress(address token);
```

### withdrawBoostFee


```solidity
function withdrawBoostFee(address to, uint256 amount) external onlyOwner;
```

### setDepositToken


```solidity
function setDepositToken(address token) external validAddress(token) onlyOwner;
```

### setCurrentSeasonId


```solidity
function setCurrentSeasonId(uint256 seasonId) external onlyOwner;
```

### setDepositDiscountForStratosphereMember


```solidity
function setDepositDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints) external onlyOwner;
```

### setDepositFee


```solidity
function setDepositFee(uint256 fee) external onlyOwner;
```

### setStratosphereAddress


```solidity
function setStratosphereAddress(address stratosphereAddress) external validAddress(stratosphereAddress) onlyOwner;
```

### setSeasonEndTimestamp


```solidity
function setSeasonEndTimestamp(uint256 seasonId, uint256 timestamp) external onlyOwner;
```

### setDepositFeeReceivers


```solidity
function setDepositFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner;
```

### setBoostFeeReceivers


```solidity
function setBoostFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner;
```

### setClaimFeeReceivers


```solidity
function setClaimFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner;
```

### setRestakeFeeReceivers


```solidity
function setRestakeFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner;
```

### setUnlockFeeReceivers


```solidity
function setUnlockFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner;
```

### setRestakeDiscountForStratosphereMember


```solidity
function setRestakeDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints) external onlyOwner;
```

### setRestakeFee


```solidity
function setRestakeFee(uint256 fee) external onlyOwner;
```

### setRewardToken


```solidity
function setRewardToken(address token) external validAddress(token) onlyOwner;
```

### startNewSeason


```solidity
function startNewSeason(uint256 _rewardTokenToDistribute) external onlyOwner;
```

### getUserDepositAmount


```solidity
function getUserDepositAmount(address user, uint256 seasonId) external view returns (uint256, uint256);
```

### getUserClaimedRewards


```solidity
function getUserClaimedRewards(address user, uint256 seasonId) external view returns (uint256);
```

### getRewardTokenBalancePool


```solidity
function getRewardTokenBalancePool(uint256 seasonId) external view returns (uint256);
```

### getSeasonTotalPoints


```solidity
function getSeasonTotalPoints(uint256 seasonId) external view returns (uint256);
```

### getSeasonTotalClaimedRewards


```solidity
function getSeasonTotalClaimedRewards(uint256 seasonId) external view returns (uint256);
```

### getUserTotalPoints


```solidity
function getUserTotalPoints(uint256 seasonId, address user) external view returns (uint256);
```

### getPendingWithdrawals


```solidity
function getPendingWithdrawals(address feeReceiver, address token) external view returns (uint256);
```

### getDepositAmountOfUser


```solidity
function getDepositAmountOfUser(address user, uint256 seasonId) external view returns (uint256);
```

### getDepositPointsOfUser


```solidity
function getDepositPointsOfUser(address user, uint256 seasonId) external view returns (uint256);
```

### getTotalDepositAmountOfSeason


```solidity
function getTotalDepositAmountOfSeason(uint256 seasonId) external view returns (uint256);
```

### getTotalPointsOfSeason


```solidity
function getTotalPointsOfSeason(uint256 seasonId) external view returns (uint256);
```

### setUnlockTimestampDiscountForStratosphereMember


```solidity
function setUnlockTimestampDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints)
    external
    onlyOwner;
```

### setUnlockFeeDiscountForStratosphereMember


```solidity
function setUnlockFeeDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints) external onlyOwner;
```

### setUnlockFee


```solidity
function setUnlockFee(uint256 fee) external onlyOwner;
```

### setBoostFee


```solidity
function setBoostFee(uint256 boostLevel, uint256 boostFee) external onlyOwner;
```

### setBoostFeeToken


```solidity
function setBoostFeeToken(address boostFeeToken) external onlyOwner;
```

### setBoostPercentTierLevel


```solidity
function setBoostPercentTierLevel(uint256 tier, uint256 level, uint256 percent) external onlyOwner;
```

### getUserPoints


```solidity
function getUserPoints(address user, uint256 seasonId) external view returns (uint256, uint256);
```

### getUnlockAmountOfUser


```solidity
function getUnlockAmountOfUser(address user, uint256 seasonId) external view returns (uint256);
```

### getUnlockTimestampOfUser


```solidity
function getUnlockTimestampOfUser(address user, uint256 seasonId) external view returns (uint256);
```

### getCurrentSeasonId


```solidity
function getCurrentSeasonId() external view returns (uint256);
```

### getSeasonEndTimestamp


```solidity
function getSeasonEndTimestamp(uint256 seasonId) external view returns (uint256);
```

### getWithdrawRestakeStatus


```solidity
function getWithdrawRestakeStatus(address user, uint256 seasonId) external view returns (bool);
```

### getUserDataForSeason


```solidity
function getUserDataForSeason(address user, uint256 seasonId) external view returns (UserData memory);
```

### getUserDataForCurrentSeason


```solidity
function getUserDataForCurrentSeason(address user) external view returns (UserData memory);
```

### getCurrentSeasonData


```solidity
function getCurrentSeasonData() external view returns (Season memory);
```

### getSeasonData


```solidity
function getSeasonData(uint256 seasonId) external view returns (Season memory);
```

### getStratosphereAddress


```solidity
function getStratosphereAddress() external view returns (address);
```

## Events
### BoostFeeWithdrawn

```solidity
event BoostFeeWithdrawn(address indexed to, uint256 amount);
```

### DepositTokenSet

```solidity
event DepositTokenSet(address indexed token);
```

### SeasonIdSet

```solidity
event SeasonIdSet(uint256 indexed seasonId);
```

### DepositDiscountForStratosphereMemberSet

```solidity
event DepositDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
```

### DepositFeeSet

```solidity
event DepositFeeSet(uint256 fee);
```

### StratosphereAddressSet

```solidity
event StratosphereAddressSet(address indexed stratosphereAddress);
```

### RewardsControllerAddressSet

```solidity
event RewardsControllerAddressSet(address indexed rewardsControllerAddress);
```

### SeasonEndTimestampSet

```solidity
event SeasonEndTimestampSet(uint256 indexed season, uint256 endTimestamp);
```

### DepositFeeReceiversSet

```solidity
event DepositFeeReceiversSet(address[] receivers, uint256[] proportion);
```

### BoostFeeReceiversSet

```solidity
event BoostFeeReceiversSet(address[] receivers, uint256[] proportion);
```

### ClaimFeeReceiversSet

```solidity
event ClaimFeeReceiversSet(address[] receivers, uint256[] proportion);
```

### RestakeFeeReceiversSet

```solidity
event RestakeFeeReceiversSet(address[] receivers, uint256[] proportion);
```

### RestakeFeeSet

```solidity
event RestakeFeeSet(uint256 fee);
```

### RestakeDiscountForStratosphereMemberSet

```solidity
event RestakeDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
```

### UnlockTimestampDiscountForStratosphereMemberSet

```solidity
event UnlockTimestampDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
```

### UnlockFeeDiscountForStratosphereMemberSet

```solidity
event UnlockFeeDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
```

### UnlockFeeSet

```solidity
event UnlockFeeSet(uint256 fee);
```

### UnlockFeeReceiversSet

```solidity
event UnlockFeeReceiversSet(address[] receivers, uint256[] proportion);
```

