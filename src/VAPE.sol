// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";

error VAPE__MaxSupplyReached();
error VAPE__OnlyStakingContract();

contract VAPE is ERC20 {
    ///////////////
    /// STORAGE ///
    ///////////////

    uint256 public constant MAX_SUPPLY = 21000000 * 1e18;

    address public immutable s_staking;

    /////////////////
    /// MODIFIERS ///
    /////////////////

    /// @notice Revert if max supply is reached
    modifier maxSupply() {
        if (totalSupply > MAX_SUPPLY) revert VAPE__MaxSupplyReached();
        _;
    }

    /// @notice Only staking contract can call this function
    modifier onlyStaking() {
        if (msg.sender != s_staking) revert VAPE__OnlyStakingContract();
        _;
    }

    /////////////
    /// LOGIC ///
    /////////////

    constructor(address _staking) ERC20("VaporStaking", "VAPE", 18) {
        s_staking = _staking;
    }

    function mint(address _to, uint256 _amount) external onlyStaking {
        _mint(_to, _amount);
    }
}
