// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/SafeERC20.sol";
import "./../../../interfaces/IERC20.sol";

import { IOps } from "./../../../interfaces/IOps.sol";

abstract contract OpsReady {
    address public immutable ops;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    function _payTxFee(uint256 _amount) internal {
        (bool success, ) = gelato.call{value: _amount}("");
        require(success, "_transfer: ETH transfer failed");
    }
}