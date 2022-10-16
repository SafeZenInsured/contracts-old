// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./../../dependencies/openzeppelin/ERC20.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract SZT is ERC20 {
    address private _buySellContract;
    address private _stakingContract;
    address private _coveragePoolContract;

    constructor(address _buySZTCA) 
    ERC20("SafeZen Token", "SZT", 18, _buySZTCA) {
        _mint(_buySZTCA, 21000000000*1e18);
    }

    modifier onlyAccessToContractAddress() override {
        require(
            (_msgSender() == _stakingContract) || 
            (_msgSender() == _coveragePoolContract) || 
            (_msgSender() == _buySellContract)
        );
        _;
    }
}