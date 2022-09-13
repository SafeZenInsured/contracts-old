//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/DummyERC20.sol";

/// NOTE: developed for testnet purposes, to create and generate fake DAI tokens
contract FakeCoin is DummyERC20 {

    constructor(string memory _name, string memory _symbol)
        DummyERC20(_name, _symbol, 18)
    {
        _mint(msg.sender, 2205002100000000000 * 1e18);
    }
}