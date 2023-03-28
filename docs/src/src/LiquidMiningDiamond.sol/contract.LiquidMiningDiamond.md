# LiquidMiningDiamond
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/LiquidMiningDiamond.sol)

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

