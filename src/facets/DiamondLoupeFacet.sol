// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/contracts/interfaces/IDiamondLoupe.sol";
import "clouds/contracts/interfaces/IERC165.sol";
import "clouds/contracts/LDiamond.sol";

/// @title DiamondLoupeFacet
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Facet in charge of the diamond loupe
/// @dev Utilizes 'IDiamondLoupe', 'IERC165' and 'LDiamond'
contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get all the facets within the diamond
    function facets() external view returns (Facet[] memory facets_) {
        LDiamond.DiamondStorage storage ds = LDiamond.diamondStorage();

        uint256 numFacets = ds.facetAddresses.length;

        facets_ = new Facet[](numFacets);

        for (uint256 i; i < numFacets; ++i) {
            address facetAddress_ = ds.facetAddresses[i];

            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds
                .facetFunctionSelectors[facetAddress_]
                .functionSelectors;
        }
    }

    /// @notice Get facet function selectors
    /// @param _facet Address of the facet
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_) {
        LDiamond.DiamondStorage storage ds = LDiamond.diamondStorage();

        facetFunctionSelectors_ = ds
            .facetFunctionSelectors[_facet]
            .functionSelectors;
    }

    /// @notice Get addresses of facets
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {
        LDiamond.DiamondStorage storage ds = LDiamond.diamondStorage();

        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Get facet address of function selector
    /// @param _functionSelector Function selector
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_) {
        LDiamond.DiamondStorage storage ds = LDiamond.diamondStorage();

        facetAddress_ = ds
            .selectorToFacetAndPosition[_functionSelector]
            .facetAddress;
    }

    /// @notice Get if contract supports interface
    /// @param _id Interface ID
    function supportsInterface(bytes4 _id) external view returns (bool) {
        LDiamond.DiamondStorage storage ds = LDiamond.diamondStorage();

        return ds.supportedInterfaces[_id];
    }
}
