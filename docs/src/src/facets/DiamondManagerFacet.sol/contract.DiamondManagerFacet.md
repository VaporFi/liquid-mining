# DiamondManagerFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/DiamondManagerFacet.sol)


## State Variables
### s

```solidity
AppStorage s;
```


### TOTAL_SHARES

```solidity
uint256 public constant TOTAL_SHARES = 10_000;
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

### setDepositToken


```solidity
function setDepositToken(address token) external validAddress(token) onlyOwner;
```

### setCurrentSeasonId


```solidity
function setCurrentSeasonId(uint256 seasonId) external onlyOwner;
```

### setStratosphereAddress


```solidity
function setStratosphereAddress(address stratosphereAddress) external validAddress(stratosphereAddress) onlyOwner;
```

### setSeasonEndTimestamp


```solidity
function setSeasonEndTimestamp(uint256 seasonId, uint256 timestamp) external onlyOwner;
```

### setBoostFeeReceivers


```solidity
function setBoostFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner;
```

### setUnlockFeeReceivers


```solidity
function setUnlockFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner;
```

### setRewardToken


```solidity
function setRewardToken(address token) external validAddress(token) onlyOwner;
```

### startNewSeason


```solidity
function startNewSeason(uint256 _rewardTokenToDistribute) external onlyOwner;
```

### startNewSeasonWithDuration


```solidity
function startNewSeasonWithDuration(uint256 _rewardTokenToDistribute, uint8 _durationDays) external onlyOwner;
```

### getRewardTokenToDistribute


```solidity
function getRewardTokenToDistribute(uint256 _seasonId) external view returns (uint256);
```

### claimTokensForSeason


```solidity
function claimTokensForSeason() external onlyOwner;
```

### setEmissionsManager


```solidity
function setEmissionsManager(address _emissionManager) external onlyOwner;
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

### setUnlockFee


```solidity
function setUnlockFee(uint256 fee) external onlyOwner;
```

### setBoostFee


```solidity
function setBoostFee(uint256 boostLevel, uint256 boostFee) external onlyOwner;
```

### setBoostPercentTierLevel


```solidity
function setBoostPercentTierLevel(uint256 tier, uint256 level, uint256 percent) external onlyOwner;
```

### getUserPoints


```solidity
function getUserPoints(address user, uint256 seasonId) external view returns (uint256, uint256);
```

### getUserLastBoostClaimedAmount


```solidity
function getUserLastBoostClaimedAmount(address user, uint256 seasonId) external view returns (uint256);
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

### getRewardTokensToDistribute


```solidity
function getRewardTokensToDistribute(uint256 seasonId) external view returns (uint256);
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

### VapeClaimedForSeason

```solidity
event VapeClaimedForSeason(uint256 indexed seasonId);
```

### EmissionsManagerSet

```solidity
event EmissionsManagerSet(address indexed emissionManager);
```

### UnlockTimestampDiscountForStratosphereMemberSet

```solidity
event UnlockTimestampDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
```

### UnlockFeeSet

```solidity
event UnlockFeeSet(uint256 fee);
```

### UnlockFeeReceiversSet

```solidity
event UnlockFeeReceiversSet(address[] receivers, uint256[] proportion);
```

### SeasonStarted

```solidity
event SeasonStarted(uint256 indexed seasonId, uint256 rewardTokenToDistribute);
```

### SeasonEnded

```solidity
event SeasonEnded(uint256 indexed seasonId, uint256 rewardTokenDistributed);
```

