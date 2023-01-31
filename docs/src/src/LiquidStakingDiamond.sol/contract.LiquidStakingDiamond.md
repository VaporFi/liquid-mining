# LiquidStakingDiamond
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/LiquidStakingDiamond.sol)

**Authors:**
mektigboy, Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat

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

