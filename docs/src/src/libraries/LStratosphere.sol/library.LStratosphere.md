# LStratosphere
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/libraries/LStratosphere.sol)

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


