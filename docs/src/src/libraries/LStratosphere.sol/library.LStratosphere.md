# LStratosphere
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/libraries/LStratosphere.sol)

Library in charge of Stratosphere related logic


## Functions
### getDetails

LOGIC ///

Get Stratosphere membership details


```solidity
function getDetails(AppStorage storage s, address _address)
    internal
    view
    returns (bool isStratosphereMember, uint8 tier);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`s`|`AppStorage`|AppStorage|
|`_address`|`address`|Address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isStratosphereMember`|`bool`|Is Stratosphere member|
|`tier`|`uint8`|Tier|


