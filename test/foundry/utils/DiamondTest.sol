// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "clouds/interfaces/IDiamondCut.sol";

import "src/LiquidMiningDiamond.sol";
import "src/facets/DiamondCutFacet.sol";
import "src/facets/DiamondLoupeFacet.sol";
import "src/facets/OwnershipFacet.sol";
import "src/facets/AuthorizationFacet.sol";
import "src/facets/BoostFacet.sol";
import "src/facets/ClaimFacet.sol";
import "src/facets/DepositFacet.sol";
import "src/facets/DiamondManagerFacet.sol";
import "src/facets/PausationFacet.sol";
import "src/facets/UnlockFacet.sol";
import "src/facets/WithdrawFacet.sol";
import "src/facets/FeeCollectorFacet.sol";
import "src/facets/MiningPassFacet.sol";
import "src/upgradeInitializers/DiamondInit.sol";
import { ERC20Mock } from "test/foundry/mocks/ERC20Mock.sol";
import { StratosphereMock } from "test/foundry/mocks/StratosphereMock.sol";

contract DiamondTest is Test {
    IDiamondCut.FacetCut[] internal cut;
    DiamondInit.Args internal initArgs;
    ERC20Mock internal depositToken;
    ERC20Mock internal rewardToken;
    ERC20Mock internal feeToken;
    StratosphereMock internal stratosphereMock;

    function createDiamond() internal returns (LiquidMiningDiamond) {
        depositToken = new ERC20Mock("VaporNodes", "VPND", 18);
        rewardToken = new ERC20Mock("VAPE Token", "VAPE", 18);
        feeToken = new ERC20Mock("USDC", "USDC", 6);
        stratosphereMock = new StratosphereMock();

        DiamondCutFacet diamondCut = new DiamondCutFacet();
        LiquidMiningDiamond diamond = new LiquidMiningDiamond(makeAddr("diamondOwner"), address(diamondCut));
        DiamondInit diamondInit = new DiamondInit();

        setDiamondLoupeFacet();
        setOwnershipFacet();
        setAuthorizationFacet();
        setBoostFacet();
        setClaimFacet();
        setDepositFacet();
        setDiamondManagerFacet();
        setPausationFacet();
        setUnlockFacet();
        setWithdrawFacet();
        setFeeCollectorFacet();
        setMiningPassFacet();

        initArgs.unlockFee = 1000;
        initArgs.depositToken = address(depositToken);
        initArgs.feeToken = address(feeToken);
        initArgs.rewardToken = address(rewardToken);
        initArgs.stratosphere = address(stratosphereMock);
        bytes memory data = abi.encodeWithSelector(DiamondInit.init.selector, initArgs);
        DiamondCutFacet(address(diamond)).diamondCut(cut, address(diamondInit), data);

        delete cut;
        return diamond;
    }

    function startSeason() external pure {
        revert("not implemented");
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

    function setFeeCollectorFacet() private {
        FeeCollectorFacet feeCollector = new FeeCollectorFacet();
        bytes4[] memory functionSelectors = new bytes4[](2);
        functionSelectors[0] = FeeCollectorFacet.collectBoostFees.selector;
        functionSelectors[1] = FeeCollectorFacet.collectUnlockFees.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(feeCollector),
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
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = ClaimFacet.automatedClaim.selector;
        functionSelectors[1] = ClaimFacet.automatedClaimBatch.selector;
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
        functionSelectors = new bytes4[](29);
        functionSelectors[0] = diamondManager.setDepositToken.selector;
        functionSelectors[1] = diamondManager.setCurrentSeasonId.selector;
        functionSelectors[2] = diamondManager.setStratosphereAddress.selector;
        functionSelectors[3] = diamondManager.setSeasonEndTimestamp.selector;
        functionSelectors[4] = diamondManager.getPendingWithdrawals.selector;
        functionSelectors[5] = diamondManager.getDepositAmountOfUser.selector;
        functionSelectors[6] = diamondManager.getDepositPointsOfUser.selector;
        functionSelectors[7] = diamondManager.getTotalDepositAmountOfSeason.selector;
        functionSelectors[8] = diamondManager.getTotalPointsOfSeason.selector;
        functionSelectors[9] = diamondManager.getCurrentSeasonId.selector;
        functionSelectors[10] = diamondManager.getSeasonEndTimestamp.selector;
        functionSelectors[11] = diamondManager.getWithdrawRestakeStatus.selector;
        functionSelectors[12] = diamondManager.startNewSeason.selector;
        functionSelectors[13] = diamondManager.getUserDepositAmount.selector;
        functionSelectors[14] = diamondManager.setRewardToken.selector;
        functionSelectors[15] = diamondManager.getUserClaimedRewards.selector;
        functionSelectors[16] = diamondManager.getSeasonTotalPoints.selector;
        functionSelectors[17] = diamondManager.getSeasonTotalClaimedRewards.selector;
        functionSelectors[18] = diamondManager.getUserTotalPoints.selector;
        functionSelectors[19] = diamondManager.setBoostFee.selector;
        functionSelectors[20] = diamondManager.setBoostPercentTierLevel.selector;
        functionSelectors[21] = diamondManager.getUserPoints.selector;
        functionSelectors[22] = diamondManager.getUnlockAmountOfUser.selector;
        functionSelectors[23] = diamondManager.getUnlockTimestampOfUser.selector;
        functionSelectors[24] = diamondManager.getStratosphereAddress.selector;
        functionSelectors[25] = diamondManager.setUnlockTimestampDiscountForStratosphereMember.selector;
        functionSelectors[26] = diamondManager.setBoostFeeReceivers.selector;
        functionSelectors[27] = diamondManager.setUnlockFeeReceivers.selector;
        functionSelectors[28] = diamondManager.getUserLastBoostClaimedAmount.selector;

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
        functionSelectors = new bytes4[](1);
        functionSelectors[0] = WithdrawFacet.withdrawUnlocked.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(withdraw),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }

    function setMiningPassFacet() private {
        MiningPassFacet miningPass = new MiningPassFacet();
        bytes4[] memory functionSelectors;
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = MiningPassFacet.purchase.selector;
        functionSelectors[1] = MiningPassFacet.miningPassOf.selector;
        cut.push(
            IDiamondCut.FacetCut({
                facetAddress: address(miningPass),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            })
        );
    }
}
