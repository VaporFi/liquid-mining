# UnlockFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/UnlockFacet.sol)


## State Variables
### s

```solidity
AppStorage s;
```


### COOLDOWN_PERIOD

```solidity
uint256 public constant COOLDOWN_PERIOD = 72 * 3600;
```


## Functions
### unlock


```solidity
function unlock(uint256 _amount) external;
```

### _deductPoints

deduct points


```solidity
function _deductPoints(uint256 _amount, uint256 _seasonEndTimestamp, UserData storage _userData, Season storage _season)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of token to deduct points|
|`_seasonEndTimestamp`|`uint256`||
|`_userData`|`UserData`||
|`_season`|`Season`||


### _applyUnlockFee

Apply deposit fee


```solidity
function _applyUnlockFee(uint256 _fee) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|Fee amount|


## Events
### Unlocked
Ordering of the events are according to their relevance in the facet


```solidity
event Unlocked(uint256 indexed seasonId, address indexed user, uint256 amount, uint256 unlockFee);
```

