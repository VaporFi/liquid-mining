// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "clouds/interfaces/IDiamondCut.sol";

import "src/LiquidStakingDiamond.sol";
import "src/facets/DiamondCutFacet.sol";
import "src/facets/DiamondLoupeFacet.sol";
import "src/facets/OwnershipFacet.sol";
import "src/facets/AuthorizationFacet.sol";
import "src/facets/BoostFacet.sol";
import "src/facets/ClaimFacet.sol";
import "src/facets/DepositFacet.sol";
import "src/facets/DiamondManagerFacet.sol";
import "src/facets/PausationFacet.sol";
import "src/facets/RestakeFacet.sol";
import "src/facets/UnlockFacet.sol";
import "src/facets/WithdrawFacet.sol";
import "src/upgradeInitializers/DiamondInit.sol";

contract DeployFuji is Script {
    IDiamondCut.FacetCut[] internal cut;
    DiamondInit.Args internal initArgs;
    address public constant VPND = 0x096F22B7891DeA0e9340365Be2021eEa562D0b55;
    address public constant STRATOSPHERE = 0x26b794235422e7c6f3ac6c717b10598C2a144203;
    address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public constant VAPE = 0x3bD01B76BB969ef2D5103b5Ea84909AD8d345663;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiamondCutFacet diamondCut = new DiamondCutFacet();
        LiquidStakingDiamond diamond = new LiquidStakingDiamond(vm.addr(deployerPrivateKey), address(diamondCut));
        DiamondInit diamondInit = new DiamondInit();

        setDiamondLoupeFacet();
        setOwnershipFacet();
        setAuthorizationFacet();
        setBoostFacet();
        setClaimFacet();
        setDepositFacet();
        setDiamondManagerFacet();
        setPausationFacet();
        setRestakeFacet();
        setUnlockFacet();
        setWithdrawFacet();

        initArgs.depositFee = 5;
        initArgs.claimFee = 5;
        initArgs.restakeFee = 3;
        initArgs.unlockFee = 10;
        initArgs.depositToken = VPND;
        initArgs.boostFeeToken = USDC;
        initArgs.rewardToken = VAPE;
        initArgs.stratosphere = STRATOSPHERE;
        bytes memory data = abi.encodeWithSelector(DiamondInit.init.selector, initArgs);
        DiamondCutFacet(address(diamond)).diamondCut(cut, address(diamondInit), data);

        vm.stopBroadcast();
    }

    function setDiamondLoupeFacet() private {
        DiamondLoupeFacet diamondLoupe = new DiamondLoupeFacet();
        bytes4[] memory functionSelectors;
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
    }

    function setOwnershipFacet() private {
        OwnershipFacet ownership = new OwnershipFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = OwnershipFacet.owner.selector;
        functionSelectors[1] = OwnershipFacet.transferOwnership.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(ownership),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setAuthorizationFacet() private {
        AuthorizationFacet authorization = new AuthorizationFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](3);
        functionSelectors[0] = AuthorizationFacet.authorized.selector;
        functionSelectors[1] = AuthorizationFacet.authorize.selector;
        functionSelectors[2] = AuthorizationFacet.unAuthorize.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(authorization),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setBoostFacet() private {
        BoostFacet boost = new BoostFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](1);
        functionSelectors[0] = BoostFacet.claimBoost.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(boost),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setClaimFacet() private {
        ClaimFacet claim = new ClaimFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](1);
        functionSelectors[0] = ClaimFacet.claim.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(claim),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setDepositFacet() private {
        DepositFacet deposit = new DepositFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](1);
        functionSelectors[0] = DepositFacet.deposit.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(deposit),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setDiamondManagerFacet() private {
        DiamondManagerFacet diamondManager = new DiamondManagerFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](33);
        functionSelectors[0] = diamondManager.setDepositToken.selector;
        functionSelectors[1] = diamondManager.setCurrentSeasonId.selector;
        functionSelectors[2] = diamondManager.setDepositDiscountForStratosphereMember.selector;
        functionSelectors[3] = diamondManager.setDepositFee.selector;
        functionSelectors[4] = diamondManager.setStratosphereAddress.selector;
        functionSelectors[6] = diamondManager.setSeasonEndTimestamp.selector;
        functionSelectors[7] = diamondManager.setDepositFeeReceivers.selector;
        functionSelectors[8] = diamondManager.getPendingWithdrawals.selector;
        functionSelectors[9] = diamondManager.getDepositAmountOfUser.selector;
        functionSelectors[10] = diamondManager.getDepositPointsOfUser.selector;
        functionSelectors[11] = diamondManager.getTotalDepositAmountOfSeason.selector;
        functionSelectors[12] = diamondManager.getTotalPointsOfSeason.selector;
        functionSelectors[13] = diamondManager.setRestakeDiscountForStratosphereMember.selector;
        functionSelectors[14] = diamondManager.setRestakeFee.selector;
        functionSelectors[15] = diamondManager.getCurrentSeasonId.selector;
        functionSelectors[16] = diamondManager.getSeasonEndTimestamp.selector;
        functionSelectors[17] = diamondManager.getWithdrawRestakeStatus.selector;
        functionSelectors[18] = diamondManager.startNewSeason.selector;
        functionSelectors[19] = diamondManager.getUserDepositAmount.selector;
        functionSelectors[20] = diamondManager.setRewardToken.selector;
        functionSelectors[21] = diamondManager.getUserClaimedRewards.selector;
        functionSelectors[22] = diamondManager.getSeasonTotalPoints.selector;
        functionSelectors[23] = diamondManager.getSeasonTotalClaimedRewards.selector;
        functionSelectors[24] = diamondManager.getUserTotalPoints.selector;
        functionSelectors[25] = diamondManager.setBoostFee.selector;
        functionSelectors[26] = diamondManager.setBoostFeeToken.selector;
        functionSelectors[27] = diamondManager.setBoostPercentTierLevel.selector;
        functionSelectors[28] = diamondManager.getUserPoints.selector;
        functionSelectors[29] = diamondManager.getUnlockAmountOfUser.selector;
        functionSelectors[30] = diamondManager.getUnlockTimestampOfUser.selector;
        functionSelectors[31] = diamondManager.getStratosphereAddress.selector;
        functionSelectors[32] = diamondManager.setUnlockTimestampDiscountForStratosphereMember.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(diamondManager),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setPausationFacet() private {
        PausationFacet pausation = new PausationFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](3);
        functionSelectors[0] = PausationFacet.paused.selector;
        functionSelectors[1] = PausationFacet.pause.selector;
        functionSelectors[2] = PausationFacet.unpause.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(pausation),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setRestakeFacet() private {
        RestakeFacet restake = new RestakeFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](1);
        functionSelectors[0] = RestakeFacet.restake.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(restake),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setUnlockFacet() private {
        UnlockFacet unlock = new UnlockFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](1);
        functionSelectors[0] = UnlockFacet.unlock.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(unlock),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setWithdrawFacet() private {
        WithdrawFacet withdraw = new WithdrawFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](3);
        functionSelectors[0] = WithdrawFacet.withdraw.selector;
        functionSelectors[1] = WithdrawFacet.withdrawAll.selector;
        functionSelectors[2] = WithdrawFacet.withdrawUnlocked.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(withdraw),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }
}
