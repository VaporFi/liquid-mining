// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/contracts/LDiamond.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LAuthorizable.sol";

/// @title AuthorizationFacet
/// @author mektigboy
/// @notice Facet in charge of displaying and setting the authorization variables
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LAuthorizable'
contract AuthorizationFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

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

    /// @notice Unauthorize address
    /// @param _address Address to unauthorize
    function unauthorize(address _address) external {
        LDiamond.enforceIsOwner();

        s.authorized[_address] = false;
    }
}
