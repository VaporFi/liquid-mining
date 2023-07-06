# ClaimFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/4b4d0d561b5718174cc348f0e7fc8a94c51e2caa/src/facets/ClaimFacet.sol)

Facet in charge of claiming VAPE rewards

*Utilizes 'LDiamond' and 'AppStorage'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### automatedClaimBatch

EXTERNAL LOGIC ///

Claim accrued VAPE rewards during the current season and withdraw unlocked VPND


```solidity
function automatedClaimBatch(uint256 _seasonId, address[] memory _users) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_seasonId`|`uint256`|The season ID|
|`_users`|`address[]`|The users to claim for|


### automatedClaim


```solidity
function automatedClaim(uint256 _seasonId, address _user) external;
```

### _calculateShare

INTERNAL LOGIC ///

Calculate the share of the User based on totalPoints of season


```solidity
function _calculateShare(uint256 _totalPoints, Season storage season) internal view returns (uint256);
```

### _vapeToDistribute

Calculate VAPE earned by User through share of the totalPoints


```solidity
function _vapeToDistribute(uint256 _userShare, Season storage season) internal view returns (uint256);
```

## Events
### Claim
EVENTS ///

Ordering of the events are according to their relevance in the facet


```solidity
event Claim(uint256 indexed seasonId, address indexed user, uint256 rewardsAmount, uint256 depositAmount);
```

