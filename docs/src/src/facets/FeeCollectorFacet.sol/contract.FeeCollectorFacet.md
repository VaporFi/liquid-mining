# FeeCollectorFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/FeeCollectorFacet.sol)

Facet in charge of collecting fees

*Utilizes 'LDiamond' and 'AppStorage'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### onlyOwner


```solidity
modifier onlyOwner();
```

### collectBoostFees

Transfer the collected boost fees to the fee receivers

*As long as the boostFeeReceivers and miningPassFeeReceivers*

*are the same, this function can be used to collect both*


```solidity
function collectBoostFees() external onlyOwner;
```

### collectUnlockFees

Transfer the collected unlock fees to the fee receivers


```solidity
function collectUnlockFees() external onlyOwner;
```

## Errors
### FeeCollectorFacet__Only_Owner

```solidity
error FeeCollectorFacet__Only_Owner();
```

