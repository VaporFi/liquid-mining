# AuthorizationFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/AuthorizationFacet.sol)

Facet in charge of displaying and setting the authorization variables

*Utilizes 'LDiamond', 'AppStorage' and 'LAuthorizable'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### authorized

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


