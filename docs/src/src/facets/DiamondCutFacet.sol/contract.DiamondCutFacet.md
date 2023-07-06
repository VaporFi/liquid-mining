# DiamondCutFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/DiamondCutFacet.sol)

**Inherits:**
IDiamondCut

**Author:**
Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat

Facet in charge of the diamond cut

*Utilizes 'IDiamondCut' and 'LDiamond'*


## Functions
### diamondCut

Diamond cut


```solidity
function diamondCut(FacetCut[] calldata _cut, address _init, bytes calldata _data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cut`|`FacetCut[]`|Facet cut|
|`_init`|`address`|Address of the initialization contract|
|`_data`|`bytes`|Data|


