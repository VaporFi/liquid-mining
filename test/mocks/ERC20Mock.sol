// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/access/Ownable.sol";

contract ERC20Mock is ERC20, Ownable {
    uint8 internal _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
