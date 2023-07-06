# DiamondInit
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/upgradeInitializers/DiamondInit.sol)

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
    uint256 unlockFee;
    address depositToken;
    address feeToken;
    address rewardToken;
    address stratosphere;
    address xVAPE;
    address passport;
    address replenishmentPool;
    address labsMultisig;
    address burnWallet;
}
```

