pragma solidity 0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/AppStorage.sol";
import {UserData} from "../libraries/AppStorage.sol";

error DiamondManagerFacet__Not_Owner();
error DiamondManagerFacet__Invalid_Address();
error DiamondManagerFacet__Invalid_Input();

contract DiamondManagerFacet {
    AppStorage s;

    event BoostFeeWithdrawn(address indexed to, uint256 amount);
    event DepositTokenSet(address indexed token);
    event SeasonIdSet(uint256 indexed seasonId);
    event DepositDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
    event DepositFeeSet(uint256 fee);
    event StratosphereAddressSet(address indexed stratosphereAddress);
    event RewardsControllerAddressSet(address indexed rewardsControllerAddress);
    event SeasonEndTimestampSet(uint256 indexed season, uint256 endTimestamp);
    event DepositFeeReceiversSet(address[] receivers, uint256[] proportion);

    event UnlockTimestampDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
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

    function withdrawBoostFee(address to, uint256 amount) external onlyOwner {
        IERC20(s.boostFeeToken).transfer(to, amount);
        emit BoostFeeWithdrawn(to, amount);
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

    function setDepositFee(uint256 fee) external onlyOwner {
        s.depositFee = fee;
        emit DepositFeeSet(fee);
    }

    function setStratosphereAddress(address stratosphereAddress) external validAddress(stratosphereAddress) onlyOwner {
        s.stratoshpereAddress = stratosphereAddress;
        emit StratosphereAddressSet(stratosphereAddress);
    }

    function setRewardsControllerAddress(
        address rewardsControllerAddress
    ) external validAddress(rewardsControllerAddress) onlyOwner {
        s.rewardsControllerAddress = rewardsControllerAddress;
        emit RewardsControllerAddressSet(rewardsControllerAddress);
    }

    function setSeasonEndTimestamp(uint256 seasonId, uint256 timestamp) external onlyOwner {
        s.seasons[seasonId].endTimestamp = timestamp;
        emit SeasonEndTimestampSet(seasonId, timestamp);
    }

    function setDepositFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner {
        if (receivers.length != proportion.length) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.depositFeeReceivers = receivers;
        s.depositFeeReceiversShares = proportion;
        emit DepositFeeReceiversSet(receivers, proportion);
    }

    function getPendingWithdrawals(address depositFeeReceiver) external view returns (uint256) {
        return s.pendingWithdrawals[depositFeeReceiver];
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
        s.unlockDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit UnlockTimestampDiscountForStratosphereMemberSet(tier, discountBasisPoints);
    }

    function setUnlockFee(uint256 fee) external onlyOwner {
        s.unlockFee = fee;
        emit UnlockFeeSet(fee);
    }

    function setUnlockFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner {
        if (receivers.length != proportion.length) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.unlockFeeReceivers = receivers;
        s.unlockFeeReceiversShares = proportion;
        emit UnlockFeeReceiversSet(receivers, proportion);
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
}
