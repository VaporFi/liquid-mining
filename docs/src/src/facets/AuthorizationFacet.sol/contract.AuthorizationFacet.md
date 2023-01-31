# AuthorizationFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/5d323fd7888bb01e362cdf4c980f8c20b18b712f/src/facets/AuthorizationFacet.sol)

**Author:**
mektigboy

Facet in charge of displaying and setting the authorization variables

*Utilizes 'LDiamond', 'AppStorage' and 'LAuthorizable'*


## State Variables
### s
APP STORAGE ///


```solidity
AppStorage s;
```


## Functions
### authorized

LOGIC ///

Get if address is authorized


```solidity
function authorized(address _address) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_address`|`address`|Address|


### authorize

Authorize address


```solidity
function authorize(address _address) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_address`|`address`|Address to authorize|


### unAuthorize

Un-authorize address


```solidity
function unAuthorize(address _address) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_address`|`address`|Address to un-authorize|


