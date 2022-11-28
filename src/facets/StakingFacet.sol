// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/src/interfaces/IERC20.sol";

error Staking__ExceededMaximumRewardTokens();
error Staking__InvalidAddressZero();
error Staking__InvalidDepositFee();
error Staking__InvalidRewardToken();
error Staking__TokenAlreadyExists();
error Staking__TokenDoesNotExist();
error Staking__WithdrawAmountExceedsBalance();

/// @title Staking
/// @author mektigboy
/// @notice Stake VPND to receive rewards
/// @dev Utilizes ...
contract StakingFacet {
    //////////////
    /// EVENTS ///
    //////////////

    event ClaimReward(
        address indexed user,
        address indexed rewardToken,
        uint256 amount
    );

    event Deposit(address indexed user, uint256 amount, uint256 fee);

    event DepositFeeChanged(uint256 newFee, uint256 oldFee);

    event EmergencyWithdraw(address indexed user, uint256 amount);

    event RewardTokenAdded(address token);

    event RewardTokenRemoved(address token);

    event Withdraw(address indexed user, uint256 amount);

    ///////////////
    /// STORAGE ///
    ///////////////

    struct UserInformation {
        uint256 amount;
        mapping(IERC20 => uint256) rewardDebt;
    }

    IERC20[] public s_rewardTokens;
    IERC20 public s_vpnd;

    address public s_feeCollector;

    uint256 public s_vpndBalance;
    uint256 public s_depositFeePercent;

    mapping(address => UserInformation) private s_userInformation;
    mapping(IERC20 => bool) public s_isRewardToken;
    mapping(IERC20 => uint256) public s_lastRewardBalance;
    mapping(IERC20 => uint256) public s_accRewardPerShare;

    uint256 constant DEPOSIT_FEE_PERCENT_PRECISION = 1e18;
    uint256 constant ACC_REWARD_PER_SHARE_PRECISION = 1e24;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Initialize a new staking contract
    /// @param _rewardToken Address of the reward token
    /// @param _vpnd Address of the VPND token
    /// @param _feeCollector Address of Fee Collector
    /// @param _depositFeePercent Deposit fee percent
    function initialize(
        IERC20 _rewardToken,
        IERC20 _vpnd,
        address _feeCollector,
        uint256 _depositFeePercent
    ) external initializer {
        __Ownable_init();

        if (address(_rewardToken) == address(0))
            revert Staking__InvalidAddressZero();
        if (address(_vpnd) == address(0)) revert Staking__InvalidAddressZero();
        if (_feeCollector == address(0)) revert Staking__InvalidAddressZero();
        if (_depositFeePercent > 5e17) revert Staking__InvalidDepositFee();

        s_isRewardToken[_rewardToken] = true;
        s_rewardTokens.push(_rewardToken);
        s_vpnd = _vpnd;
        s_feeCollector = _feeCollector;
        s_depositFeePercent = _depositFeePercent;
    }

    /// @notice Deposit into staking
    /// @param _amount Amount to be deposited
    function deposit(uint256 _amount) external {
        UserInformation storage user = s_userInformation[_msgSender()];

        uint256 fee = (_amount * s_depositFeePercent) /
            DEPOSIT_FEE_PERCENT_PRECISION;
        uint256 amountMinusFee = _amount - fee;

        uint256 oldAmount = user.amount;
        uint256 newAmount = user.amount + amountMinusFee;

        user.amount = newAmount;

        uint256 length = s_rewardTokens.length;

        for (uint256 i; i < length; ) {
            /// @notice Realistically impossible overflow/underflow
            unchecked {
                ++i;
            }

            IERC20 token = s_rewardTokens[i];

            updateReward(token);

            uint256 oldRewardsDebt = user.rewardDebt[token];

            user.rewardDebt[token] =
                (newAmount * s_accRewardPerShare[token]) /
                ACC_REWARD_PER_SHARE_PRECISION;

            if (oldAmount != 0) {
                uint256 pending = ((oldAmount * s_accRewardPerShare[token]) /
                    ACC_REWARD_PER_SHARE_PRECISION) - oldRewardsDebt;

                if (pending != 0) {
                    _safeTokenTransfer(token, _msgSender(), pending);

                    emit ClaimReward(_msgSender(), address(token), pending);
                }
            }
        }

        s_vpndBalance = s_vpndBalance + amountMinusFee;

        s_vpnd.safeTransferFrom(_msgSender(), s_feeCollector, fee);
        s_vpnd.safeTransferFrom(_msgSender(), address(this), amountMinusFee);

        emit Deposit(_msgSender(), amountMinusFee, fee);
    }

    /// @notice Get user information
    /// @param _user Address of the user
    /// @param _rewardToken Address of the reward token
    /// @return Amount of VPND deposited by the user
    /// @return Rewards debt for the chosen token
    function userInformation(
        address _user,
        IERC20 _rewardToken
    ) external view returns (uint256, uint256) {
        UserInformation storage user = s_userInformation[_user];

        return (user.amount, user.rewardDebt[_rewardToken]);
    }

    /// @notice Get pending reward
    /// @param _user Address of the user
    /// @param _token Address of the token
    /// @return Pending rewards of the user
    function pendingReward(
        address _user,
        IERC20 _token
    ) external view returns (uint256) {
        if (!s_isRewardToken[_token]) revert Staking__InvalidRewardToken();

        UserInformation storage user = s_userInformation[_user];

        uint256 totalVPND = s_vpndBalance;
        uint256 accRewardTokenPerShare = s_accRewardPerShare[_token];

        uint256 currentRewardBalance = _token.balanceOf(address(this));
        uint256 rewardBalance = _token == s_vpnd
            ? currentRewardBalance - totalVPND
            : currentRewardBalance;

        if (rewardBalance != s_lastRewardBalance[_token] && totalVPND != 0) {
            uint256 accruedReward = rewardBalance - s_lastRewardBalance[_token];

            accRewardTokenPerShare =
                ((accRewardTokenPerShare + accruedReward) *
                    ACC_REWARD_PER_SHARE_PRECISION) /
                totalVPND;
        }

        return
            ((user.amount * accRewardTokenPerShare) /
                ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt[_token];
    }

    /// @notice Withdraw VPND and harvest the rewards
    /// @param _amount The amount of VPND to withdraw
    function withdraw(uint256 _amount) external {
        UserInformation storage user = s_userInformation[_msgSender()];

        uint256 oldAmount = user.amount;

        if (_amount > oldAmount) revert Staking__WithdrawAmountExceedsBalance();

        uint256 newAmount = user.amount - _amount;

        user.amount = newAmount;

        uint256 length = s_rewardTokens.length;

        if (oldAmount != 0) {
            for (uint256 i; i < length; ) {
                /// @notice Realistically impossible overflow/underflow
                unchecked {
                    ++i;
                }

                IERC20 _token = s_rewardTokens[i];

                updateReward(_token);

                uint256 pending = ((oldAmount * s_accRewardPerShare[_token]) /
                    ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt[_token];

                user.rewardDebt[_token] =
                    (newAmount * s_accRewardPerShare[_token]) /
                    ACC_REWARD_PER_SHARE_PRECISION;

                if (pending != 0) {
                    _safeTokenTransfer(_token, _msgSender(), pending);

                    emit ClaimReward(_msgSender(), address(_token), pending);
                }
            }
        }

        s_vpndBalance = s_vpndBalance - _amount;

        s_vpnd.safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _amount);
    }

    /// @notice Withdraw without caring about rewards
    /// @notice EMERGENCY ONLY!
    function emergencyWithdrawal() external {
        UserInformation storage user = s_userInformation[_msgSender()];

        uint256 amount = user.amount;

        user.amount = 0;

        uint256 length = s_rewardTokens.length;

        for (uint256 i; i < length; ) {
            /// @notice Realistically impossible overflow/underflow
            unchecked {
                ++i;
            }

            IERC20 token = s_rewardTokens[i];

            user.rewardDebt[token] = 0;
        }

        s_vpndBalance = s_vpndBalance - amount;
        s_vpnd.safeTransfer(_msgSender(), amount);

        emit EmergencyWithdraw(_msgSender(), amount);
    }

    /// @notice Update reward variables
    /// @param _token Address of the reward token
    /// @dev Needs to be called before any deposit or withdrawal
    function updateReward(IERC20 _token) public {
        if (!s_isRewardToken[_token]) revert Staking__InvalidRewardToken();

        uint256 totalVPND = s_vpndBalance;
        uint256 currentRewardsBalance = _token.balanceOf(address(this));
        uint256 rewardBalance = _token == s_vpnd
            ? currentRewardsBalance - totalVPND
            : currentRewardsBalance;

        if (rewardBalance == s_lastRewardBalance[_token]) return;
        if (totalVPND == 0) return;

        uint256 accruedReward = rewardBalance - s_lastRewardBalance[_token];

        s_accRewardPerShare[_token] =
            ((s_accRewardPerShare[_token] + accruedReward) *
                ACC_REWARD_PER_SHARE_PRECISION) /
            totalVPND;
        s_lastRewardBalance[_token] = rewardBalance;
    }

    /// @notice Transfer tokens in a safe manner
    /// @param _token Address of the token to transfer
    /// @param _to Recipient
    /// @param _amount Amount to send
    function _safeTokenTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 currentRewardBalance = _token.balanceOf(address(this));
        uint256 rewardBalance = _token == s_vpnd
            ? currentRewardBalance - s_vpndBalance
            : currentRewardBalance;

        if (_amount > rewardBalance) {
            s_lastRewardBalance[_token] =
                s_lastRewardBalance[_token] -
                rewardBalance;

            _token.safeTransfer(_to, rewardBalance);
        } else {
            s_lastRewardBalance[_token] = s_lastRewardBalance[_token] - _amount;

            _token.safeTransfer(_to, _amount);
        }
    }

    /////////////
    /// OWNER ///
    /////////////

    /// @notice Add a new reward token
    /// @param _rewardToken New reward token to be added
    function addRewardToken(IERC20 _rewardToken) external onlyOwner {
        if (s_isRewardToken[_rewardToken]) revert Staking__TokenAlreadyExists();
        if (address(_rewardToken) == address(0))
            revert Staking__InvalidAddressZero();
        if (s_rewardTokens.length > 25)
            revert Staking__ExceededMaximumRewardTokens();

        s_rewardTokens.push(_rewardToken);
        s_isRewardToken[_rewardToken] = true;

        updateReward(_rewardToken);

        emit RewardTokenAdded(address(_rewardToken));
    }

    /// @notice Remove a reward token
    /// @param _rewardToken Address of the reward token
    function removeRewardToken(IERC20 _rewardToken) external onlyOwner {
        if (!s_isRewardToken[_rewardToken]) revert Staking__TokenDoesNotExist();

        updateReward(_rewardToken);

        s_isRewardToken[_rewardToken] = false;

        uint256 length = s_rewardTokens.length;

        for (uint256 i; i < length; ) {
            /// @notice Realistically impossible overflow/underflow
            unchecked {
                ++i;
            }

            if (s_rewardTokens[i] == _rewardToken) {
                s_rewardTokens[i] = s_rewardTokens[length - 1];
                s_rewardTokens.pop();
                break;
            }
        }

        emit RewardTokenRemoved(address(_rewardToken));
    }

    /// @notice Update the deposit fee percent
    /// @param _depositFeePercent New deposit fee percent
    function updateDepositFeePercent(
        uint256 _depositFeePercent
    ) external onlyOwner {
        if (_depositFeePercent > 5e17) revert Staking__InvalidDepositFee();

        uint256 oldFee = s_depositFeePercent;

        s_depositFeePercent = _depositFeePercent;

        emit DepositFeeChanged(_depositFeePercent, oldFee);
    }
}
