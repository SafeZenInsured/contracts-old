// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/ERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";

contract GSZT is ERC20, IERC20Extended {

    constructor(address _buySZTCA) 
    ERC20("SafeZen Governance Token", "GSZT", 18, _buySZTCA) {
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