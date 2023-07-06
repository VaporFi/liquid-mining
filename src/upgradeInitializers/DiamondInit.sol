// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IDiamondLoupe } from "clouds/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "clouds/interfaces/IDiamondCut.sol";
import { IERC173 } from "clouds/interfaces/IERC173.sol";
import { IERC165 } from "clouds/interfaces/IERC165.sol";
import { AppStorage } from "../libraries/AppStorage.sol";

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
        uint256 unlockFee;
        address depositToken;
        address feeToken;
        address rewardToken;
        address stratosphere;
        address xVAPE;
        address passport;
        address replenishmentPool;
        address labsMultisig;
        address burnWallet;
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
        s.feeToken = _args.feeToken;
        s.rewardToken = _args.rewardToken;

        // DepositFacet
        s.depositToken = _args.depositToken;
        s.depositDiscountForStratosphereMembers[0] = 500; // 5%º
        s.depositDiscountForStratosphereMembers[1] = 550; // 5.5%
        s.depositDiscountForStratosphereMembers[2] = 650; // 6.5%
        s.depositDiscountForStratosphereMembers[3] = 800; // 8%
        s.depositDiscountForStratosphereMembers[4] = 1000; // 10%
        s.depositDiscountForStratosphereMembers[5] = 1500; // 15%

        // UnlockFacet
        s.unlockFee = _args.unlockFee;
        s.unlockFeeDiscountForStratosphereMembers[0] = 500; // 5%
        s.unlockFeeDiscountForStratosphereMembers[1] = 550; // 5.5%
        s.unlockFeeDiscountForStratosphereMembers[2] = 650; // 6.5%
        s.unlockFeeDiscountForStratosphereMembers[3] = 800; // 8%
        s.unlockFeeDiscountForStratosphereMembers[4] = 1000; // 10%
        s.unlockFeeDiscountForStratosphereMembers[5] = 1500; // 15%
        s.unlockTimestampDiscountForStratosphereMembers[0] = 500; // 5%
        s.unlockTimestampDiscountForStratosphereMembers[1] = 550; // 5.5%
        s.unlockTimestampDiscountForStratosphereMembers[2] = 650; // 6.5%
        s.unlockTimestampDiscountForStratosphereMembers[3] = 800; // 8%
        s.unlockTimestampDiscountForStratosphereMembers[4] = 1000; // 10%
        s.unlockTimestampDiscountForStratosphereMembers[5] = 1500; // 15%
        s.unlockFeeReceivers.push(_args.replenishmentPool);
        s.unlockFeeReceivers.push(_args.labsMultisig);
        s.unlockFeeReceivers.push(_args.burnWallet);
        s.unlockFeeReceiversShares.push(8000); // 80%
        s.unlockFeeReceiversShares.push(1000); // 10%
        s.unlockFeeReceiversShares.push(1000); // 10%

        // BoostFacet
        s.boostLevelToFee[0] = 0;
        /// @dev using 1e6 because USDC has 6 decimals
        s.boostLevelToFee[1] = 2 * 1e6;
        s.boostLevelToFee[2] = 3 * 1e6;
        s.boostLevelToFee[3] = 4 * 1e6;
        s.boostForNonStratMembers = 10;
        s.boostPercentFromTierToLevel[0][0] = 20; // 0.20%
        s.boostPercentFromTierToLevel[1][0] = 25; // 0.25%
        s.boostPercentFromTierToLevel[2][0] = 33; // 0.33%
        s.boostPercentFromTierToLevel[3][0] = 45; // 0.45%
        s.boostPercentFromTierToLevel[4][0] = 65; // 0.65%
        s.boostPercentFromTierToLevel[5][0] = 100; // 1.00%
        s.boostPercentFromTierToLevel[0][1] = 22; // 0.22%
        s.boostPercentFromTierToLevel[1][1] = 28; // 0.28%
        s.boostPercentFromTierToLevel[2][1] = 37; // 0.37%
        s.boostPercentFromTierToLevel[3][1] = 51; // 0.51%
        s.boostPercentFromTierToLevel[4][1] = 74; // 0.74%
        s.boostPercentFromTierToLevel[5][1] = 115; // 1.15%
        s.boostPercentFromTierToLevel[0][2] = 24; // 0.24%
        s.boostPercentFromTierToLevel[1][2] = 30; // 0.30%
        s.boostPercentFromTierToLevel[2][2] = 40; // 0.40%
        s.boostPercentFromTierToLevel[3][2] = 55; // 0.55%
        s.boostPercentFromTierToLevel[4][2] = 81; // 0.81%
        s.boostPercentFromTierToLevel[5][2] = 125; // 1.25%
        s.boostPercentFromTierToLevel[0][3] = 28; // 0.28%
        s.boostPercentFromTierToLevel[1][3] = 35; // 0.35%
        s.boostPercentFromTierToLevel[2][3] = 47; // 0.47%
        s.boostPercentFromTierToLevel[3][3] = 64; // 0.64%
        s.boostPercentFromTierToLevel[4][3] = 94; // 0.94%
        s.boostPercentFromTierToLevel[5][3] = 145; // 1.45%

        // MiningPassFacet
        /// @dev fee is paid in USDC
        s.miningPassTierToFee[0] = 0;
        s.miningPassTierToFee[1] = 0.5 * 1e6;
        s.miningPassTierToFee[2] = 1 * 1e6;
        s.miningPassTierToFee[3] = 2 * 1e6;
        s.miningPassTierToFee[4] = 4 * 1e6;
        s.miningPassTierToFee[5] = 8 * 1e6;
        s.miningPassTierToFee[6] = 15 * 1e6;
        s.miningPassTierToFee[7] = 30 * 1e6;
        s.miningPassTierToFee[8] = 50 * 1e6;
        s.miningPassTierToFee[9] = 75 * 1e6;
        s.miningPassTierToFee[10] = 100 * 1e6;
        /// @dev deposit limit is in VPND
        s.miningPassTierToDepositLimit[0] = 5_000 * 1e18;
        s.miningPassTierToDepositLimit[1] = 10_000 * 1e18;
        s.miningPassTierToDepositLimit[2] = 25_000 * 1e18;
        s.miningPassTierToDepositLimit[3] = 60_000 * 1e18;
        s.miningPassTierToDepositLimit[4] = 150_000 * 1e18;
        s.miningPassTierToDepositLimit[5] = 350_000 * 1e18;
        s.miningPassTierToDepositLimit[6] = 800_000 * 1e18;
        s.miningPassTierToDepositLimit[7] = 1_800_000 * 1e18;
        s.miningPassTierToDepositLimit[8] = 4_500_000 * 1e18;
        s.miningPassTierToDepositLimit[9] = 12_000_000 * 1e18;
        s.miningPassTierToDepositLimit[10] = type(uint256).max;
    }
}
