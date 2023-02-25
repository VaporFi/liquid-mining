// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";

/// @title MockERC20
/// @author mektigboy
/// @notice Mocks an ERC20 contract
/// @dev For testing
contract MockERC20 is ERC20 {
    /////////////
    /// LOGIC ///
    /////////////

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) ERC20(_name, _symbol, _decimals) {
        _mint(msg.sender, _initialSupply);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}