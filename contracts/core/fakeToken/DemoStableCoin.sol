//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/ERC20.sol";

contract FakeCoin is ERC20 {

    constructor(string memory _name, string memory _symbol, address _contractAddress)
        ERC20(_name, _symbol, 18, _contractAddress)
    {
        _mint(msg.sender, 2205002100000000000 * 1e18);
    }
}