# DiamondCutFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/facets/DiamondCutFacet.sol)

**Inherits:**
IDiamondCut

**Authors:**
mektigboy, Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat

Facet in charge of the diamond cut

*Utilizes 'IDiamondCut' and 'LDiamond'*


## Functions
### diamondCut

LOGIC ///

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


