# BoostFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/BoostFacet.sol)

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
function _calculatePoints(UserData storage _userData, uint256 _boostLevel, uint256 _tier)
    internal
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_userData`|`UserData`|User data|
|`_boostLevel`|`uint256`||
|`_tier`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Boost points|


## Events
### ClaimBoost

```solidity
event ClaimBoost(address indexed _user, uint256 _seasonId, uint256 _boostPoints);
```

