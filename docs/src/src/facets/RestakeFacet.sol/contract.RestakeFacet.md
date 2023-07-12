# RestakeFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/RestakeFacet.sol)


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### restake


```solidity
function restake() external;
```

### _restake


```solidity
function _restake(uint256 _amount) internal;
```

### _applyPoints

Apply points


```solidity
function _applyPoints(uint256 _amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of token to apply points|


### _applyRestakeFee

Apply restake fee


```solidity
function _applyRestakeFee(uint256 _fee) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|Fee amount|


## Events
### Restake

```solidity
event Restake(address indexed depositor, uint256 amount);
```

