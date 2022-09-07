// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/ERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../dependencies/openzeppelin/Ownable.sol";

contract sztDAI is ERC20, IERC20Extended {

    constructor(address _constantFlowCA) 
    ERC20("szt DAI Stream Token", "sztDAI", 18, _constantFlowCA) {
    }
    
    function mint(address to, uint256 amount) external onlyAccessToContractAddress returns(bool) {
        _mint(to, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external onlyAccessToContractAddress returns(bool) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        return true;
    }
}