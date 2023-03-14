// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LDiamond} from "clouds/diamond/LDiamond.sol";
import {IDiamondLoupe} from "clouds/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "clouds/interfaces/IDiamondCut.sol";
import {IERC173} from "clouds/interfaces/IERC173.sol";
import {IERC165} from "clouds/interfaces/IERC165.sol";
import {AppStorage} from "../libraries/AppStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

// Adding parameters to the `init` or other functions you add here can make a single deployed
// DiamondInit contract reusable accross upgrades, and can be used for multiple diamonds.

contract DiamondInit {
    AppStorage s;

    struct Args {
        uint256 depositFee;
        uint256 claimFee;
        uint256 restakeFee;
        uint256 unlockFee;
        address depositToken;
        address boostFeeToken;
        address rewardToken;
        address stratosphere;
        address rewardsController;
    }

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(Args memory _args) external {
        // adding ERC165 data
        LDiamond.DiamondStorage storage ds = LDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        // General
        s.stratosphereAddress = _args.stratosphere;
        s.rewardsControllerAddress = _args.rewardsController;

        // DepositFacet
        s.depositFee = _args.depositFee;
        s.depositToken = _args.depositToken;

        // UnlockFacet
        s.unlockFee = _args.unlockFee;
        s.unlockDiscountForStratosphereMembers[0] = 0;
        s.depositDiscountForStratosphereMembers[0] = 0;
        s.restakeDiscountForStratosphereMembers[0] = 0;

        // BoostFacet
        s.boostFeeToken = _args.boostFeeToken;
        s.boostLevelToFee[0] = 0;
        s.boostPercentFromTierToLevel[0][0] = 0;

        // ClaimFacet
        s.claimFee = _args.claimFee;

        // RestakeFacet
        s.restakeFee = _args.restakeFee;
        s.rewardToken = _args.rewardToken;
    }
}
