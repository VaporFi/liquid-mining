// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LAuthorizable.sol";

/// @title AuthorizationFacet
/// @notice Facet in charge of displaying and setting the authorization variables
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LAuthorizable'
contract AuthorizationFacet {
    AppStorage s;

    /// @notice Get if address is authorized
    /// @param _address Address
    function authorized(address _address) external view returns (bool) {
        return s.authorized[_address];
    }

    /// @notice Authorize address
    /// @param _address Address to authorize
    function authorize(address _address) external {
        LDiamond.enforceIsOwner();

        s.authorized[_address] = true;
    }

    /// @notice Un-authorize address
    /// @param _address Address to un-authorize
    function unAuthorize(address _address) external {
        LDiamond.enforceIsOwner();

        s.authorized[_address] = false;
    }
}
