// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";

error DiamondManagerFacet__Not_Owner();
error DiamondManagerFacet__Invalid_Address();
error DiamondManagerFacet__Invalid_Input();
error DiamondManagerFacet__Season_Not_Finished();

contract DiamondManagerFacet {
    AppStorage s;
    uint256 public constant TOTAL_SHARES = 10_000;

    event BoostFeeWithdrawn(address indexed to, uint256 amount);
    event DepositTokenSet(address indexed token);
    event SeasonIdSet(uint256 indexed seasonId);
    event DepositDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
    event DepositFeeSet(uint256 fee);
    event StratosphereAddressSet(address indexed stratosphereAddress);
    event RewardsControllerAddressSet(address indexed rewardsControllerAddress);
    event SeasonEndTimestampSet(uint256 indexed season, uint256 endTimestamp);
    event DepositFeeReceiversSet(address[] receivers, uint256[] proportion);
    event BoostFeeReceiversSet(address[] receivers, uint256[] proportion);
    event ClaimFeeReceiversSet(address[] receivers, uint256[] proportion);
    event RestakeFeeReceiversSet(address[] receivers, uint256[] proportion);

    event RestakeFeeSet(uint256 fee);
    event RestakeDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);

    event UnlockTimestampDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
    event UnlockFeeDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
    event UnlockFeeSet(uint256 fee);
    event UnlockFeeReceiversSet(address[] receivers, uint256[] proportion);

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

    function setDepositToken(address token) external validAddress(token) onlyOwner {
        s.depositToken = token;
        emit DepositTokenSet(token);
    }

    function setCurrentSeasonId(uint256 seasonId) external onlyOwner {
        s.currentSeasonId = seasonId;
        emit SeasonIdSet(seasonId);
    }

    function setDepositDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints) external onlyOwner {
        s.depositDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit DepositDiscountForStratosphereMemberSet(tier, discountBasisPoints);
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

    function setRestakeDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints) external onlyOwner {
        s.restakeDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit RestakeDiscountForStratosphereMemberSet(tier, discountBasisPoints);
    }

    function setRestakeFee(uint256 fee) external onlyOwner {
        if (fee > TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.restakeFee = fee;
        emit RestakeFeeSet(fee);
    }

    function setRewardToken(address token) external validAddress(token) onlyOwner {
        s.rewardToken = token;
    }

    function startNewSeason(uint256 _rewardTokenToDistribute) external onlyOwner {
        uint256 _currentSeason = s.currentSeasonId;
        if (_currentSeason != 0 && s.seasons[_currentSeason].endTimestamp < block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        uint256 newSeasonId = _currentSeason + 1;
        s.currentSeasonId = newSeasonId;
        Season storage season = s.seasons[newSeasonId];
        if (newSeasonId != 1 && season.endTimestamp <= block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        season.id = newSeasonId;
        season.startTimestamp = block.timestamp;
        season.endTimestamp = block.timestamp + 25 days;
        season.rewardTokensToDistribute = _rewardTokenToDistribute;
        season.rewardTokenBalance = _rewardTokenToDistribute;
    }

    function startNewSeasonWithDuration(uint256 _rewardTokenToDistribute, uint8 _durationDays) external onlyOwner {
        uint256 _currentSeason = s.currentSeasonId;
        if (_currentSeason != 0 && s.seasons[_currentSeason].endTimestamp < block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        s.currentSeasonId = _currentSeason + 1;
        Season storage season = s.seasons[s.currentSeasonId];
        season.id = s.currentSeasonId;
        season.startTimestamp = block.timestamp;
        season.endTimestamp = block.timestamp + (_durationDays * 1 days);
        season.rewardTokensToDistribute = _rewardTokenToDistribute;
        season.rewardTokenBalance = _rewardTokenToDistribute;
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

    function setUnlockTimestampDiscountForStratosphereMember(
        uint256 tier,
        uint256 discountBasisPoints
    ) external onlyOwner {
        s.unlockTimestampDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit UnlockTimestampDiscountForStratosphereMemberSet(tier, discountBasisPoints);
    }

    function setUnlockFeeDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints) external onlyOwner {
        s.unlockFeeDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit UnlockFeeDiscountForStratosphereMemberSet(tier, discountBasisPoints);
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
}
