pragma solidity 0.8.17;

import "clouds/diamond/LDiamond.sol";

import "../libraries/AppStorage.sol";

error DiamondManagerFacet__Not_Owner();
error DiamondManagerFacet__Invalid_Address();
error DiamondManagerFacet__Invalid_Input();

contract DiamondManagerFacet {
    AppStorage s;

    event DepositTokenSet(address indexed token);
    event SeasonIdSet(uint256 indexed seasonId);
    event DepositDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
    event DepositFeeSet(uint256 fee);
    event StratosphereAddressSet(address indexed stratosphereAddress);
    event RewardsControllerAddressSet(address indexed rewardsControllerAddress);
    event SeasonEndTimestampSet(uint256 indexed season, uint256 endTimestamp);
    event DepositFeeReceiversSet(address[] receivers, uint256[] proportion);
    event RestakeFeeSet(uint256 fee);
    event RestakeDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);

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
        s.feeReceivers = receivers;
        s.feeReceiversShares = proportion;
        emit DepositFeeReceiversSet(receivers, proportion);
    }


    function setRestakeDiscountForStratosphereMember(uint256 tier, uint256 discountBasisPoints) external onlyOwner {
        s.restakeDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit RestakeDiscountForStratosphereMemberSet(tier, discountBasisPoints);
    }

    function setRestakeFee(uint256 fee) external onlyOwner {
        s.restakeFee = fee;
        emit RestakeFeeSet(fee);
    }


    function getPendingWithdrawals(address feeReceiver) external view returns (uint256) {
        return s.pendingWithdrawals[feeReceiver];
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
}

