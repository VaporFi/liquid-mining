# LPercentages
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/libraries/LPercentages.sol)


## Functions
### percentage

Calculates the percentage of a number using basis points

*1% = 100 basis points*


```solidity
function percentage(uint256 _number, uint256 _percentage) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_number`|`uint256`|Number|
|`_percentage`|`uint256`|Percentage in bps|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Percentage of a number|


