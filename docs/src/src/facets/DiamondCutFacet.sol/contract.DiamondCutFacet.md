# DiamondCutFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/DiamondCutFacet.sol)

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


