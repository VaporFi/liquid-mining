# WithdrawFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/WithdrawFacet.sol)

Facet in charge of withdrawing unlocked VPND

*Utilizes 'LDiamond', 'AppStorage' and 'IERC20'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### withdrawUnlocked

EXTERNAL LOGIC ///

Withdraw prematurely unlocked VPND

*User cannot participate in new seasons until they withdraw*


```solidity
function withdrawUnlocked() external;
```

### withdraw

Withdraw unlocked VPND

*User cannot participate in new seasons until they withdraw*


```solidity
function withdraw() external;
```

### withdrawAll

Withdraw all unlocked VPND

*User cannot participate in new seasons until they withdraw*


```solidity
function withdrawAll() external;
```

## Events
### WithdrawUnlockedVPND
EVENTS ///


```solidity
event WithdrawUnlockedVPND(uint256 amount, address indexed to);
```

### WithdrawVPND

```solidity
event WithdrawVPND(uint256 amount, address indexed to);
```

### WithdrawAll

```solidity
event WithdrawAll(uint256 amount, address indexed to);
```

