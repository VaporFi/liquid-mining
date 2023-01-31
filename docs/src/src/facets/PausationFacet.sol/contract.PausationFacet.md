# PausationFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/facets/PausationFacet.sol)

**Author:**
mektigboy

Facet in charge of the pausation of certain features

*Utilizes 'LDiamond', 'AppStorage' and 'LPausable'*


## State Variables
### s
APP STORAGE ///


```solidity
AppStorage s;
```


## Functions
### paused

LOGIC ///

Get if features are currently paused


```solidity
function paused() external view returns (bool);
```

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

