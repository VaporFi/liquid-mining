# BoostFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/facets/BoostFacet.sol)

Facet in charge of point's boosts

*Utilizes 'LDiamond', 'AppStorage'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### claimBoost

Claim boost


```solidity
function claimBoost() external;
```

### _calculatePoints

Calculate boost points

*Utilizes 'LPercentages'.
_daysSinceSeasonStart is the number of days since the season started starting from 0*


```solidity
function _calculatePoints(UserData _useData) internal returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_useData`|`UserData`|User data|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Boost points|


## Errors
### BoostFacet__BoostAlreadyClaimed

```solidity
error BoostFacet__BoostAlreadyClaimed();
```

