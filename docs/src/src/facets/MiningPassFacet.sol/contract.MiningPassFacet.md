# MiningPassFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/MiningPassFacet.sol)

Facet in charge of purchasing and upgrading mining passes

*Utilizes 'LDiamond', 'AppStorage'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### purchase

notice Purchase a mining pass


```solidity
function purchase(uint256 _tier) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tier`|`uint256`|Tier of mining pass to purchase|


### miningPassOf

Get user's mining pass tier and deposit limit


```solidity
function miningPassOf(address _user) external view returns (uint256 _tier, uint256 _depositLimit);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|User address|


### _applyMiningPassFee

Apply mining pass fee to the fee receivers


```solidity
function _applyMiningPassFee(uint256 _fee) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|Fee amount|


## Events
### MiningPassPurchase
Ordering of the events are according to their relevance in the facet


```solidity
event MiningPassPurchase(uint256 indexed seasonId, address indexed user, uint256 indexed tier, uint256 fee);
```

