# LiquidMiningDiamond
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/LiquidMiningDiamond.sol)

**Author:**
Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat

Main contract of the diamond

*Utilizes 'IDiamondCut', 'LDiamond' and 'AppStorage'*


## Functions
### constructor

LOGIC ///


```solidity
constructor(address _owner, address _diamondCutFacet) payable;
```

### fallback


```solidity
fallback() external payable;
```

