//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {WithdrawFacet} from "../src/facets/WithdrawFacet.sol";
import {DepositFacet} from "../src/facets/DepositFacet.sol";
import {LiquidStakingDiamond} from "../src/LiquidStakingDiamond.sol";
import {IDiamondCut} from "clouds/interfaces/IDiamondCut.sol";
import {LDiamond} from "clouds/diamond/LDiamond.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {AuthorizationFacet} from "../src/facets/AuthorizationFacet.sol";
import {DiamondInit} from "../src/initializers/DiamondInit.sol";

contract DiamondDeploy is Test {
    address public diamond;
    WithdrawFacet public withdrawFacet;
    DepositFacet public depositFacet;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public diamondOwnershipFacet;
    AuthorizationFacet public authorizationFacet;
    DiamondInit public diamondInit;


    address owner = address(0);
    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);
    address david = address(4);
    address eve = address(5);
    address frank = address(6);
    address grace = address(7);
    address heidi = address(8);
    address ivan = address(9);
    address judy = address(10);
    address karen = address(11); //Not Stratosphere member

function setUp() public virtual {
     vm.startPrank(owner);
    console.log("==================== SETUP BEGINS =====================");
    diamondCutFacet = new DiamondCutFacet();
    diamond = address(new LiquidStakingDiamond(owner, address(diamondCutFacet)));
    diamondLoupeFacet = new DiamondLoupeFacet();
    diamondOwnershipFacet = new OwnershipFacet();
    depositFacet = new DepositFacet();
    withdrawFacet = new WithdrawFacet();
    authorizationFacet = new AuthorizationFacet();
    diamondInit = new DiamondInit();


    {       bytes memory initData = abi.encodeWithSelector(_getSelectors("DiamondInit")[0]);
            IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](5);
            cuts[0] = IDiamondCut.FacetCut({facetAddress: address(diamondLoupeFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: _getSelectors("DiamondLoupeFacet")});
            cuts[1] = IDiamondCut.FacetCut({facetAddress: address(diamondOwnershipFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: _getSelectors("DiamondOwnershipFacet")});
            cuts[2] = IDiamondCut.FacetCut({facetAddress: address(depositFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: _getSelectors("DepositFacet")});
            cuts[3] = IDiamondCut.FacetCut({facetAddress: address(withdrawFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: _getSelectors("WithdrawFacet")});
            cuts[4] = IDiamondCut.FacetCut({facetAddress: address(authorizationFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: _getSelectors("AuthorizationFacet")});
            IDiamondCut(diamond).diamondCut(cuts, address(diamondInit), initData);
            console.log(">>> Diamond initialized");
    }
}






function _getSelectors(string memory _facetName) private returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](5);
        cmd[0] = "yarn";
        cmd[1] = "--silent";
        cmd[2] = "run";
        cmd[3] = "getFuncSelectors";
        cmd[4] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

}