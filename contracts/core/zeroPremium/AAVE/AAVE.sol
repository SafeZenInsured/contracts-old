// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../../../interfaces/AAVE/IAAVE.sol"; // aave contracts to supply and borrow
import "./../../../../interfaces/AAVE/IAAVEERC20.sol"; 
import "./../../../../interfaces/AAVE/IAAVEImplementation.sol"; 
import "./../../../dependencies/openzeppelin/Ownable.sol"; // accessable by admin
import "./../ZPController.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract AAVE is Ownable, IAAVEImplementation {
    IAAVE LendAAVE;
    ZPController zpController;
    
    mapping(address => mapping(address => mapping(uint256 => uint256))) private userTransactionInfo;
    mapping(address => mapping(address => uint256)) private userWithdrawnBalance;

    constructor(address _lendingAddress) {
        LendAAVE = IAAVE(_lendingAddress);
    }

    function updateZeroPremiumController(address _controllerAddress) external onlyOwner {
        zpController = ZPController(_controllerAddress);
    }

    function mintERC20Tokens(address tokenAddress, uint256 amount) public override {
        IAAVEERC20(tokenAddress).mint(msg.sender, amount);
    }

    // supply function under the hood calls transferFrom function,
    // so token to be supplied should be approved.
    error LowSupplyAmountError();
    function supplyToken(address _tokenAddress, address _rewardTokenAddress, uint256 _amount) external override {
        if (_amount < 1e10) {
            revert LowSupplyAmountError();
        }
        IAAVEERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        uint256 currVersion =  zpController.latestVersion();
        uint256 balanceBeforeSupply = IAAVEERC20(_rewardTokenAddress).balanceOf(address(this));
        IAAVEERC20(_tokenAddress).approve(address(LendAAVE), _amount);
        LendAAVE.supply(_tokenAddress, _amount, address(this), 0);
        uint256 balanceAfterSupply = IAAVEERC20(_rewardTokenAddress).balanceOf(address(this));
        userTransactionInfo[_msgSender()][_rewardTokenAddress][currVersion] += (balanceAfterSupply - balanceBeforeSupply);
    }

    function withdrawToken(address _tokenAddress, address _rewardTokenAddress, uint256 _amount) external override {
        uint256 userBalance = calculateUserBalance(_rewardTokenAddress);
        if (userBalance >= _amount) {
            IAAVEERC20(_rewardTokenAddress).approve(address(LendAAVE), _amount);
            LendAAVE.withdraw(_tokenAddress, _amount, address(this));
            IAAVEERC20(_tokenAddress).transfer(_msgSender(), _amount);
            userWithdrawnBalance[_msgSender()][_rewardTokenAddress] += _amount;
        }        
    }
    
    // public for testing otherwise internal call
    function calculateUserBalance(address _rewardTokenAddress) public view override returns(uint256) {
        uint256 userBalance;
        uint256 currVersion =  zpController.latestVersion();

        for (uint i = 0; i <= currVersion; i++) {
            uint256 userVersionBalance = userTransactionInfo[_msgSender()][_rewardTokenAddress][i];
            if (userVersionBalance > 0) {
                userBalance += ((userVersionBalance * zpController.versionLiquidationFactor(i)) / 100);
            }    
        }
        userBalance -= userWithdrawnBalance[_msgSender()][_rewardTokenAddress];
        return userBalance;
    }

}