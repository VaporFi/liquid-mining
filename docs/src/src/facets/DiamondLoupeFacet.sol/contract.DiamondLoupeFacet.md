# DiamondLoupeFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/DiamondLoupeFacet.sol)

**Inherits:**
IDiamondLoupe, IERC165

**Author:**
Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat

Facet in charge of the diamond loupe

*Utilizes 'IDiamondLoupe', 'IERC165' and 'LDiamond'*


## Functions
### facets

Get all the facets within the diamond


```solidity
function facets() external view returns (Facet[] memory facets_);
```

### facetFunctionSelectors

Get facet function selectors


```solidity
function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_facet`|`address`|Address of the facet|


### facetAddresses

Get addresses of facets


```solidity
function facetAddresses() external view returns (address[] memory facetAddresses_);
```

### facetAddress

Get facet address of function selector


```solidity
function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_functionSelector`|`bytes4`|Function selector|


### supportsInterface

Get if contract supports interface


```solidity
function supportsInterface(bytes4 _id) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_id`|`bytes4`|Interface ID|


