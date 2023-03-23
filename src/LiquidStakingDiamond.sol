// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/interfaces/IDiamondCut.sol";
import "clouds/diamond/LDiamond.sol";
import "./libraries/AppStorage.sol";

error LiquidStakingDiamond__InvalidFunction();

/// @title LiquidStaking
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Main contract of the diamond
/// @dev Utilizes 'IDiamondCut', 'LDiamond' and 'AppStorage'
contract LiquidStakingDiamond {
    /////////////
    /// LOGIC ///
    /////////////

    constructor(address _owner, address _diamondCutFacet) payable {
        LDiamond.updateContractOwner(_owner);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory functionSelectors = new bytes4[](1);

        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        LDiamond.diamondCut(cut, address(0), "");
    }

    fallback() external payable {
        LDiamond.DiamondStorage storage ds;

        bytes32 position = LDiamond.DIAMOND_STORAGE_POSITION;

        assembly {
            ds.slot := position
        }

        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;

        if (facet == address(0)) revert LiquidStakingDiamond__InvalidFunction();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
