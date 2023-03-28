# UnlockFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/UnlockFacet.sol)


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
function _deductPoints(uint256 _amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of token to deduct points|


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

```solidity
event Unlocked(address indexed user, uint256 amount);
```

