# WithdrawFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/WithdrawFacet.sol)

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

## Events
### WithdrawUnlockedVPND
EVENTS ///

Ordering of the events are according to their relevance in the facet


```solidity
event WithdrawUnlockedVPND(uint256 indexed seasonId, address indexed to, uint256 amount);
```

