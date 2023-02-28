// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/access/Ownable.sol";

contract ERC20Mock is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }
}
