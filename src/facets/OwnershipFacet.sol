// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/contracts/interfaces/IERC173.sol";
import "clouds/contracts/LDiamond.sol";

/// @title OwnershipFacet
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Facet in charge of administrating the ownership of the contract
/// @notice Utilizes 'IERC173' and 'LDiamond'
contract OwnershipFacet is IERC173 {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get contract owner
    function owner() external view returns (address owner_) {
        owner_ = LDiamond.contractOwner();
    }

    /// @notice Transfer ownership
    /// @param _owner New owner
    function transferOwnership(address _owner) external {
        LDiamond.enforceIsOwner();
        LDiamond.updateContractOwner(_owner);
    }
}
