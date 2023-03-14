// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "clouds/interfaces/IDiamondCut.sol";

import "src/LiquidStakingDiamond.sol";
import "src/facets/DiamondCutFacet.sol";
import "src/facets/DiamondLoupeFacet.sol";
import "src/facets/OwnershipFacet.sol";

contract DiamondTest is Test {
    IDiamondCut.FacetCut[] internal cut;

    function createDiamond() internal returns (LiquidStakingDiamond) {
        DiamondCutFacet diamondCut = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupe = new DiamondLoupeFacet();
        OwnershipFacet ownership = new OwnershipFacet();
        LiquidStakingDiamond diamond = new LiquidStakingDiamond(makeAddr("diamondOwner"), address(diamondCut));
        // vm.startPrank(makeAddr("diamondOwner"));
        bytes4[] memory functionSelectors;
        // Diamond Loupe
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        functionSelectors[1] = DiamondLoupeFacet.facets.selector;
        functionSelectors[2] = DiamondLoupeFacet.facetAddress.selector;
        functionSelectors[3] = DiamondLoupeFacet.facetAddresses.selector;
        functionSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(diamondLoupe),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
        // Ownership Facet
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = OwnershipFacet.transferOwnership.selector;
        functionSelectors[1] = OwnershipFacet.owner.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(ownership),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
        DiamondCutFacet(address(diamond)).diamondCut(cut, address(0), "");
        // vm.stopPrank();
        delete cut;
        return diamond;
        // return LiquidStakingDiamond(payable(address(0)));
    }

    function addFacet(LiquidStakingDiamond _diamond, address _facet, bytes4[] memory _selectors) internal {
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: _facet,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: _selectors
            })
        );

        DiamondCutFacet(address(_diamond)).diamondCut(cut, address(0), "");

        delete cut;
    }
}
