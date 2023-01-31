# OwnershipFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/facets/OwnershipFacet.sol)

**Inherits:**
IERC173

**Authors:**
mektigboy, Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat

Facet in charge of administrating the ownership of the contract

Utilizes 'IERC173' and 'LDiamond'


## Functions
### owner

LOGIC ///

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


