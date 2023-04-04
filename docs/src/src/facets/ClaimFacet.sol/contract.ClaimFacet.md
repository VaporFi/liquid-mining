# ClaimFacet
[Git Source](https://github.com/VaporFi/liquid-staking/blob/3b515db4cbed442e9d462b37141dae8e14c9c9d0/src/facets/ClaimFacet.sol)

Facet in charge of claiming VAPE rewards

*Utilizes 'LDiamond' and 'AppStorage'*


## State Variables
### s

```solidity
AppStorage s;
```


## Functions
### claim

EXTERNAL LOGIC ///

Claim accrued VAPE reward token


```solidity
function claim() external;
```

### _calculateShare

INTERNAL LOGIC ///

Calculate the share of the User based on totalPoints of season


```solidity
function _calculateShare(uint256 _totalPoints, uint256 _seasonId) internal view returns (uint256);
```

### _vapeToDistribute

Calculate VAPE earned by User through share of the totalPoints


```solidity
function _vapeToDistribute(uint256 _userShare, uint256 _seasonId) internal view returns (uint256);
```

### _applyClaimFee


```solidity
function _applyClaimFee(uint256 _fee) internal;
```

## Events
### Claim
EVENTS ///


```solidity
event Claim(uint256 amount, address indexed claimer);
```

