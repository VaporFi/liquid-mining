// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct AppStorage {
    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////
    mapping(address => bool) authorized;

    /////////////////
    /// PAUSATION ///
    /////////////////
    bool paused;

    //////////////
    /// SEASON ///
    //////////////
    uint256 currentSeasonId;
    // season's reward token balance to distribute
    mapping(uint256 => uint256) seasonRewardTokenBalances;

    ///////////////
    /// DEPOSIT ///
    ///////////////
    uint256 depositFee;
    address depositToken;
    address[] depositFeeReceivers;
    address[] depositFeeReceiversShares;
    // nested mapping: seasonId => userAddress => amount
    mapping(uint256 => mapping(address => uint256)) depositAmounts;
    // total amount deposited for each season: seasonId => amount
    mapping(uint256 => uint256) totalDepositAmounts;

    ////////////////
    /// WITHDRAW ///
    ////////////////
    // TODO: Add withdraw state variables

    /////////////
    /// CLAIM ///
    /////////////
    uint256 claimFee;
    address rewardToken;
    // nested mapping: seasonId => userAddress => amount
    mapping(uint256 => mapping(address => uint256)) claimAmounts;
    // total amount claimed for each season: seasonId => amount
    mapping(uint256 => uint256) totalClaimAmounts;
}
