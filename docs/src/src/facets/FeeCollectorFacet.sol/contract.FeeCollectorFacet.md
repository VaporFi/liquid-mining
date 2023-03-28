# FeeCollectorFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/FeeCollectorFacet.sol)

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

Transfer the collected fees to the fee receivers


```solidity
function collectBoostFees() external onlyOwner;
```

### collectClaimFees


```solidity
function collectClaimFees() external onlyOwner;
```

### collectDepositFees


```solidity
function collectDepositFees() external onlyOwner;
```

### collectRestakeFees


```solidity
function collectRestakeFees() external onlyOwner;
```

### collectUnlockFees


```solidity
function collectUnlockFees() external onlyOwner;
```

## Errors
### FeeCollectorFacet__Only_Owner

```solidity
error FeeCollectorFacet__Only_Owner();
```

