# PausationFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/PausationFacet.sol)

Facet in charge of the pausation of certain features

*Utilizes 'LDiamond', 'AppStorage' and 'LPausable'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### paused

Get if features are currently paused


```solidity
function paused() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool if features are paused|


### pause

Pause features


```solidity
function pause() external;
```

### unpause

Unpause features


```solidity
function unpause() external;
```

