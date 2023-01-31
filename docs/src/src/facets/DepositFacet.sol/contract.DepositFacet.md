# DepositFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/facets/DepositFacet.sol)


## State Variables
### s
STORAGE ///


```solidity
AppStorage s;
```


## Functions
### deposit

LOGIC ///

Deposit token to the contract


```solidity
function deposit(uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of token to deposit|


### _applyPoints

Apply points


```solidity
function _applyPoints(uint256 _amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of token to apply points|


### _applyDepositFee

Apply deposit fee


```solidity
function _applyDepositFee(uint256 _fee) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|Fee amount|


## Errors
### DepositFacet__NotEnoughTokenBalance
ERRORS ///


```solidity
error DepositFacet__NotEnoughTokenBalance();
```

### DepositFacet__InvalidFeeReceivers

```solidity
error DepositFacet__InvalidFeeReceivers();
```

