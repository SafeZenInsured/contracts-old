// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";

contract SwapDAI is Ownable{

    IERC20 private DAI;
    IERC20Extended private sztDAI;

    constructor(address _DAIAddress, address _sztDAIAddress) {
        DAI = IERC20(_DAIAddress);
        sztDAI = IERC20Extended(_sztDAIAddress);
    }

    function swapDAI(uint256 _amount) external returns(bool) {
        DAI.transferFrom(_msgSender(), address(this), _amount);
        bool success = sztDAI.mint(_msgSender(), _amount);
        return success;
    }

    function swapsztDAI(uint256 _amount) external returns(bool) {
        sztDAI.transferFrom(_msgSender(), address(this), _amount);
        bool success = DAI.transfer(_msgSender(), _amount);
        return success;
    }
}