# LPercentages
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/libraries/LPercentages.sol)


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


