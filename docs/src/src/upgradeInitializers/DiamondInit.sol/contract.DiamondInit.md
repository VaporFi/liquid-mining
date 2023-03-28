# DiamondInit
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/upgradeInitializers/DiamondInit.sol)

\
Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
Implementation of a diamond.
/*****************************************************************************


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### init


```solidity
function init(Args memory _args) external;
```

## Structs
### Args

```solidity
struct Args {
    uint256 depositFee;
    uint256 claimFee;
    uint256 restakeFee;
    uint256 unlockFee;
    address depositToken;
    address boostFeeToken;
    address rewardToken;
    address stratosphere;
}
```

