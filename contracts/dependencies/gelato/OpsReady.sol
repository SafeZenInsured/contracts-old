// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/SafeERC20.sol";
import "./../../../interfaces/IERC20.sol";

import { IOps } from "./../../../interfaces/IOps.sol";

abstract contract OpsReady {
    address public immutable ops;
    address payable public immutable treasury;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops, address payable _treasury) {
        ops = _ops;
        treasury = _treasury;
        gelato = IOps(_ops).gelato();
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}