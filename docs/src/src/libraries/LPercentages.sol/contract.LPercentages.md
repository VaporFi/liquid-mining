# LPercentages
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/libraries/LPercentages.sol)


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


