# WithdrawFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/facets/WithdrawFacet.sol)


## State Variables
### s
STORAGE ///


```solidity
AppStorage s;
```


## Functions
### withdraw

LOGIC ///

Withdraws the staked amount from previous stake seasons


```solidity
function withdraw(uint256 _seasonId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_seasonId`|`uint256`||


## Errors
### WithdrawFacet__InProgressSeason
ERRORS ///


```solidity
error WithdrawFacet__InProgressSeason();
```

