// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/IERC20.sol";
import "./ZPController.sol";

contract ZPAccountManager is Ownable{
    ZPController zpController;

    function updateZeroPremiumController(address _controllerAddress) external onlyOwner {
        zpController = ZPController(_controllerAddress);
    }

    
}