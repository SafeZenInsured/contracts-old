// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./../../dependencies/openzeppelin/ERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../dependencies/openzeppelin/Ownable.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract sztDAI is ERC20, IERC20Extended, Ownable {
    address public CFAContract;
    address public swapDAIContract;

    constructor(address _constantFlowCA) 
    ERC20("szt DAI Stream Token", "sztDAI", 18, _constantFlowCA) {
    }

    modifier onlyAccessToContractAddress() override {
        require((_msgSender() == swapDAIContract) || (_msgSender() == CFAContract));
        _;
    }

    function setSwapDAIAddress(address _swapDAIAddress) external onlyOwner {
        swapDAIContract = _swapDAIAddress;
    }
    
    function mint(address to, uint256 amount) external onlyAccessToContractAddress override returns(bool) {
        _mint(to, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external override returns(bool) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        return true;
    }
}