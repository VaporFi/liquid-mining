# DepositFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/DepositFacet.sol)

Facet in charge of depositing VPND tokens

*Utilizes 'LDiamond', 'AppStorage' and 'LPercentages'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### nonReentrant


```solidity
modifier nonReentrant();
```

### deposit

Deposit token to the contract


```solidity
function deposit(uint256 _amount) external nonReentrant;
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


## Events
### Deposit

```solidity
event Deposit(address indexed depositor, uint256 amount);
```

