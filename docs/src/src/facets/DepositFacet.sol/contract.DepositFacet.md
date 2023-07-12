# DepositFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/DepositFacet.sol)

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
function _applyPoints(uint256 _amount, uint256 _seasonId, UserData storage _userData) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of token to apply points|
|`_seasonId`|`uint256`||
|`_userData`|`UserData`||


## Events
### Deposit
Ordering of the events are according to their relevance in the facet


```solidity
event Deposit(uint256 indexed seasonId, address indexed user, uint256 amount);
```

