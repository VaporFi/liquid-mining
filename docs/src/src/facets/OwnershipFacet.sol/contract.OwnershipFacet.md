# OwnershipFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/OwnershipFacet.sol)

**Inherits:**
IERC173

**Author:**
Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat

Facet in charge of administrating the ownership of the contract

Utilizes 'IERC173' and 'LDiamond'


## Functions
### owner

Get contract owner


```solidity
function owner() external view returns (address owner_);
```

### transferOwnership

Transfer ownership


```solidity
function transferOwnership(address _owner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|New owner|


