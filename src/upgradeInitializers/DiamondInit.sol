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

        // DepositFacet
        s.depositFee = _args.depositFee;
        s.depositToken = _args.depositToken;

        // UnlockFacet
        s.unlockFee = _args.unlockFee;
        s.unlockTimestampDiscountForStratosphereMembers[0] = 500;
        s.unlockTimestampDiscountForStratosphereMembers[1] = 550;
        s.unlockTimestampDiscountForStratosphereMembers[2] = 650;
        s.unlockFeeDiscountForStratosphereMembers[0] = 500;
        s.unlockFeeDiscountForStratosphereMembers[1] = 550;
        s.unlockFeeDiscountForStratosphereMembers[2] = 650;
        s.depositDiscountForStratosphereMembers[0] = 500;
        s.depositDiscountForStratosphereMembers[1] = 550;
        s.depositDiscountForStratosphereMembers[2] = 650;
        s.restakeDiscountForStratosphereMembers[0] = 500;
        s.restakeDiscountForStratosphereMembers[1] = 550;
        s.restakeDiscountForStratosphereMembers[2] = 650;

        // BoostFacet
        s.boostFeeToken = _args.boostFeeToken;
        s.boostLevelToFee[0] = 0;
        /// @dev using 1e6 because USDC has 6 decimals
        s.boostLevelToFee[1] = 2 * 1e6;
        s.boostLevelToFee[2] = 3 * 1e6;
        s.boostLevelToFee[3] = 4 * 1e6;
        s.boostForNonStratMembers = 10;
        s.boostPercentFromTierToLevel[0][0] = 20;
        s.boostPercentFromTierToLevel[1][0] = 25;
        s.boostPercentFromTierToLevel[2][0] = 33;
        s.boostPercentFromTierToLevel[3][0] = 45;
        s.boostPercentFromTierToLevel[4][0] = 65;
        s.boostPercentFromTierToLevel[5][0] = 100;
        s.boostPercentFromTierToLevel[0][1] = 22;
        s.boostPercentFromTierToLevel[1][1] = 28;
        s.boostPercentFromTierToLevel[2][1] = 37;
        s.boostPercentFromTierToLevel[3][1] = 51;
        s.boostPercentFromTierToLevel[4][1] = 74;
        s.boostPercentFromTierToLevel[5][1] = 115;
        s.boostPercentFromTierToLevel[0][2] = 24;
        s.boostPercentFromTierToLevel[1][2] = 30;
        s.boostPercentFromTierToLevel[2][2] = 40;
        s.boostPercentFromTierToLevel[3][2] = 55;
        s.boostPercentFromTierToLevel[4][2] = 81;
        s.boostPercentFromTierToLevel[5][2] = 125;
        s.boostPercentFromTierToLevel[0][3] = 26;
        s.boostPercentFromTierToLevel[1][3] = 33;
        s.boostPercentFromTierToLevel[2][3] = 44;
        s.boostPercentFromTierToLevel[3][3] = 60;
        s.boostPercentFromTierToLevel[4][3] = 87;
        s.boostPercentFromTierToLevel[5][3] = 135;

        // ClaimFacet
        s.claimFee = _args.claimFee;

        // RestakeFacet
        s.restakeFee = _args.restakeFee;
        s.rewardToken = _args.rewardToken;
    }
}
