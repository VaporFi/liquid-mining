// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage, UserData, Season } from "../libraries/AppStorage.sol";
import { IEmissionsManager } from "../interfaces/IEmissionsManager.sol";

error DiamondManagerFacet__Not_Owner();
error DiamondManagerFacet__Invalid_Address();
error DiamondManagerFacet__Invalid_Input();
error DiamondManagerFacet__Season_Not_Finished();
error DiamondManagerFacet_InvalidArgs_ChangeBoostPoints();
error DiamondManagerFacet__NotGelatoExecutor();
error DiamondManagerFacet__NotAuthorized();

contract DiamondManagerFacet {
    AppStorage s;
    uint256 public constant TOTAL_SHARES = 10_000;

    event BoostFeeWithdrawn(address indexed to, uint256 amount);
    event DepositTokenSet(address indexed token);
    event SeasonIdSet(uint256 indexed seasonId);
    event DepositFeeSet(uint256 fee);
    event StratosphereAddressSet(address indexed stratosphereAddress);
    event RewardsControllerAddressSet(address indexed rewardsControllerAddress);
    event SeasonEndTimestampSet(uint256 indexed season, uint256 endTimestamp);
    event DepositFeeReceiversSet(address[] receivers, uint256[] proportion);
    event BoostFeeReceiversSet(address[] receivers, uint256[] proportion);
    event ClaimFeeReceiversSet(address[] receivers, uint256[] proportion);
    event RestakeFeeReceiversSet(address[] receivers, uint256[] proportion);
    event VapeClaimedForSeason(uint256 indexed seasonId);
    event EmissionsManagerSet(address indexed emissionManager);
    event UnlockTimestampDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
    event UnlockFeeSet(uint256 fee);
    event UnlockFeeReceiversSet(address[] receivers, uint256[] proportion);
    event SeasonStarted(uint256 indexed seasonId, uint256 rewardTokenToDistribute);
    event SeasonEnded(uint256 indexed seasonId, uint256 rewardTokenDistributed);

    modifier onlyOwner() {
        if (msg.sender != LDiamond.contractOwner()) {
            revert DiamondManagerFacet__Not_Owner();
        }
        _;
    }

    modifier validAddress(address token) {
        if (token == address(0)) {
            revert DiamondManagerFacet__Invalid_Address();
        }
        _;
    }

    modifier onlyGelatoExecutor() {
        if (msg.sender != s.gelatoExecutor) {
            revert DiamondManagerFacet__NotGelatoExecutor();
        }
        _;
    }

    modifier onlyAuthorized() {
        if (!s.authorized[msg.sender]) {
            revert DiamondManagerFacet__NotAuthorized();
        }
        _;
    }

    function setDepositToken(address token) external validAddress(token) onlyOwner {
        s.depositToken = token;
        emit DepositTokenSet(token);
    }

    function setCurrentSeasonId(uint256 seasonId) external onlyOwner {
        s.currentSeasonId = seasonId;
        emit SeasonIdSet(seasonId);
    }

    function setStratosphereAddress(address stratosphereAddress) external validAddress(stratosphereAddress) onlyOwner {
        s.stratosphereAddress = stratosphereAddress;
        emit StratosphereAddressSet(stratosphereAddress);
    }

    function setSeasonEndTimestamp(uint256 seasonId, uint256 timestamp) external onlyOwner {
        s.seasons[seasonId].endTimestamp = timestamp;
        emit SeasonEndTimestampSet(seasonId, timestamp);
    }

    function setBoostFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner {
        if (receivers.length != proportion.length) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        uint256 totalShares = 0;
        for (uint256 i; i < proportion.length; i++) {
            totalShares += proportion[i];
        }
        if (totalShares != TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.boostFeeReceivers = receivers;
        s.boostFeeReceiversShares = proportion;
        emit BoostFeeReceiversSet(receivers, proportion);
    }

    function setUnlockFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner {
        if (receivers.length != proportion.length) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        uint256 totalShares = 0;
        for (uint256 i; i < proportion.length; i++) {
            totalShares += proportion[i];
        }
        if (totalShares != TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.unlockFeeReceivers = receivers;
        s.unlockFeeReceiversShares = proportion;
        emit UnlockFeeReceiversSet(receivers, proportion);
    }

    function setRewardToken(address token) external validAddress(token) onlyOwner {
        s.rewardToken = token;
    }

    function startNewSeason(uint256 _rewardTokenToDistribute) external onlyOwner {
        uint256 _currentSeason = s.currentSeasonId;
        if (_currentSeason != 0 && s.seasons[_currentSeason].endTimestamp >= block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        uint256 newSeasonId = _currentSeason + 1;
        s.currentSeasonId = newSeasonId;
        Season storage season = s.seasons[newSeasonId];

        season.id = newSeasonId;
        season.startTimestamp = block.timestamp;
        season.endTimestamp = block.timestamp + 25 days;
        season.rewardTokensToDistribute = _rewardTokenToDistribute;
        season.rewardTokenBalance = _rewardTokenToDistribute;

        emit SeasonStarted(newSeasonId, _rewardTokenToDistribute);
    }

    function startNewSeasonWithDuration(uint256 _rewardTokenToDistribute, uint8 _durationDays) external onlyOwner {
        uint256 _currentSeason = s.currentSeasonId;
        if (_currentSeason != 0 && s.seasons[_currentSeason].endTimestamp >= block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        s.currentSeasonId = _currentSeason + 1;
        Season storage season = s.seasons[s.currentSeasonId];
        season.id = s.currentSeasonId;
        season.startTimestamp = block.timestamp;
        season.endTimestamp = block.timestamp + (_durationDays * 1 days);
        season.rewardTokensToDistribute = _rewardTokenToDistribute;
        season.rewardTokenBalance = _rewardTokenToDistribute;

        emit SeasonStarted(s.currentSeasonId, _rewardTokenToDistribute);
    }

    function startNewSeasonWithEndTimestamp(
        uint256 _rewardTokenToDistribute,
        uint256 _endTimestamp
    ) external onlyOwner {
        uint256 _currentSeason = s.currentSeasonId;
        if (_currentSeason != 0 && s.seasons[_currentSeason].endTimestamp >= block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        s.currentSeasonId = _currentSeason + 1;
        Season storage season = s.seasons[s.currentSeasonId];
        season.id = s.currentSeasonId;
        season.startTimestamp = block.timestamp;
        season.endTimestamp = _endTimestamp;
        season.rewardTokensToDistribute = _rewardTokenToDistribute;
        season.rewardTokenBalance = _rewardTokenToDistribute;

        emit SeasonStarted(s.currentSeasonId, _rewardTokenToDistribute);
    }

    //this function is added to fix the points, it's temporary
    function changeBoostPoints(address[] memory addresses, uint256[] memory newBoostPoints) external onlyOwner {
        if (addresses.length != newBoostPoints.length) revert DiamondManagerFacet_InvalidArgs_ChangeBoostPoints();

        uint256 difference = 0;
        uint256 currentSeasonId = s.currentSeasonId;

        for (uint256 i; i < addresses.length; i++) {
            UserData storage _userData = s.usersData[currentSeasonId][addresses[i]];
            uint256 newBoostPoint = newBoostPoints[i];
            if (_userData.depositAmount == 0) revert DiamondManagerFacet_InvalidArgs_ChangeBoostPoints();
            uint256 currentBoostPoints = _userData.boostPoints;

            //current boost point is greater than or equal to newBoostPoint, I'm assuming we'll remove function later, and this function cannot be used to increase boost point
            difference += currentBoostPoints - newBoostPoint;

            _userData.boostPoints = newBoostPoint;
        }
        s.seasons[currentSeasonId].totalPoints -= difference;
    }

    function claimTokensForSeason() external onlyOwner {
        IEmissionsManager(s.emissionsManager).mintLiquidMining();
        emit VapeClaimedForSeason(s.currentSeasonId);
    }

    function setEmissionsManager(address _emissionManager) external onlyOwner {
        if (_emissionManager == address(0)) {
            revert DiamondManagerFacet__Invalid_Address();
        }
        s.emissionsManager = _emissionManager;
        emit EmissionsManagerSet(_emissionManager);
    }

    function setUnlockTimestampDiscountForStratosphereMember(
        uint256 tier,
        uint256 discountBasisPoints
    ) external onlyOwner {
        s.unlockTimestampDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit UnlockTimestampDiscountForStratosphereMemberSet(tier, discountBasisPoints);
    }

    function setUnlockFee(uint256 fee) external onlyOwner {
        if (fee > TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.unlockFee = fee;
        emit UnlockFeeSet(fee);
    }

    function setBoostFee(uint256 boostLevel, uint256 boostFee) external onlyOwner {
        if (boostFee > TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.boostLevelToFee[boostLevel] = boostFee;
    }

    function setBoostPercentTierLevel(uint256 tier, uint256 level, uint256 percent) external onlyOwner {
        s.boostPercentFromTierToLevel[tier][level] = percent;
    }

    function setGelatoExecutor(address executor) external onlyOwner {
        s.gelatoExecutor = executor;
    }

    function setSeasonClaimed() external onlyAuthorized {
        s.isSeasonClaimed[s.currentSeasonId] = true;
    }

    // Getters

    function getRewardTokenToDistribute(uint256 _seasonId) external view returns (uint256) {
        return s.seasons[_seasonId].rewardTokensToDistribute;
    }

    function getUserDepositAmount(address user, uint256 seasonId) external view returns (uint256, uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return (_userData.depositAmount, _userData.depositPoints);
    }

    function getUserClaimedRewards(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.amountClaimed;
    }

    function getRewardTokenBalancePool(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].rewardTokenBalance;
    }

    function getSeasonTotalPoints(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalPoints;
    }

    function getSeasonTotalClaimedRewards(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalClaimAmount;
    }

    function getUserTotalPoints(uint256 seasonId, address user) external view returns (uint256) {
        return s.usersData[seasonId][user].depositPoints + s.usersData[seasonId][user].boostPoints;
    }

    function getPendingWithdrawals(address feeReceiver, address token) external view returns (uint256) {
        return s.pendingWithdrawals[feeReceiver][token];
    }

    function getDepositAmountOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.depositAmount;
    }

    function getDepositPointsOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.depositPoints;
    }

    function getTotalDepositAmountOfSeason(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalDepositAmount;
    }

    function getTotalPointsOfSeason(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalPoints;
    }

    function getUserPoints(address user, uint256 seasonId) external view returns (uint256, uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return (_userData.depositPoints, _userData.boostPoints);
    }

    function getUserLastBoostClaimedAmount(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.lastBoostClaimAmount;
    }

    function getUnlockAmountOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.unlockAmount;
    }

    function getUnlockTimestampOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.unlockTimestamp;
    }

    function getCurrentSeasonId() external view returns (uint256) {
        return s.currentSeasonId;
    }

    function getSeasonEndTimestamp(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].endTimestamp;
    }

    function getWithdrawRestakeStatus(address user, uint256 seasonId) external view returns (bool) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.hasWithdrawnOrRestaked;
    }

    function getUserDataForSeason(address user, uint256 seasonId) external view returns (UserData memory) {
        return s.usersData[seasonId][user];
    }

    function getUserDataForCurrentSeason(address user) external view returns (UserData memory) {
        return s.usersData[s.currentSeasonId][user];
    }

    function getCurrentSeasonData() external view returns (Season memory) {
        return s.seasons[s.currentSeasonId];
    }

    function getSeasonData(uint256 seasonId) external view returns (Season memory) {
        return s.seasons[seasonId];
    }

    function getStratosphereAddress() external view returns (address) {
        return s.stratosphereAddress;
    }

    function getRewardTokensToDistribute(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].rewardTokensToDistribute;
    }

    function getCurrentSeasonUserDetails(
        address _account
    ) external view returns (uint256 depositAmount, uint256 poolShareBips, uint256 estimatedRewards) {
        uint256 _currentSeasonId = s.currentSeasonId;
        UserData memory _userData = s.usersData[_currentSeasonId][_account];
        Season memory _season = s.seasons[_currentSeasonId];
        uint256 _userTotalPoints = _userData.depositPoints + _userData.boostPoints;

        depositAmount = _userData.depositAmount;
        poolShareBips = (_userTotalPoints * 10000) / _season.totalPoints;
        estimatedRewards = (_season.rewardTokensToDistribute * poolShareBips) / 10000;
    }

    function getSeasonIsClaimed(uint256 seasonId) external view returns (bool) {
        return s.isSeasonClaimed[seasonId];
    }
}
