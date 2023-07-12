# BoostFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/BoostFacet.sol)

Facet in charge of point's boosts

*Utilizes 'LDiamond', 'AppStorage'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### claimBoost

Claim daily boost points


```solidity
function claimBoost(uint256 boostLevel) external;
```

### _calculatePoints

Calculate boost points

*Utilizes 'LPercentages'.*

*_daysSinceSeasonStart starts from 0 equal to the first day of the season.*


```solidity
function _calculatePoints(UserData storage _userData, uint256 _boostPercent, uint256 _seasonId)
    internal
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_userData`|`UserData`|User data|
|`_boostPercent`|`uint256`|% to boost points|
|`_seasonId`|`uint256`|current seasonId|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Boost points|


### _applyBoostFee

Apply boost fee


```solidity
function _applyBoostFee(uint256 _fee) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|Fee amount|


## Events
### ClaimBoost
Ordering of the events are according to their relevance in the facet


```solidity
event ClaimBoost(
    uint256 indexed seasonId,
    address indexed user,
    uint256 boostLevel,
    uint256 _boostPoints,
    uint256 boostFee,
    uint256 tier
);
```

