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
    uint256 protocolID;

    struct UserInfo {
        bool isActiveInvested;
        uint256 startVersionBlock;
        uint256 withdrawnBalance;
    }

    /// User Address => Reward Token Address => Version => UserTransactionInfo
    mapping(address => mapping(address => mapping(uint256 => uint256))) private userTransactionInfo;
    mapping(address => mapping(address => UserInfo)) private usersInfo;

    constructor(
        address _lendingAddress, 
        address _controllerAddress
    ) {
        LendAAVE = IAAVE(_lendingAddress);
        zpController = ZPController(_controllerAddress);
    }

    /// Initialize this function first before running any other function
    function addAAVEProtocolInfo(
        string memory _protocolName,
        address _deployedAddress,
        bool _isCommunityGoverned,
        uint256 _riskFactor,
        uint256 _riskPoolCategory
    ) external onlyOwner {
        protocolID = zpController.protocolID();
        zpController.addCoveredProtocol(_protocolName, _deployedAddress, _isCommunityGoverned, _riskFactor, _riskPoolCategory);
    } 

    /// for testnet purposes
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
        if (!usersInfo[_msgSender()][_rewardTokenAddress].isActiveInvested) {
            usersInfo[_msgSender()][_rewardTokenAddress].startVersionBlock = currVersion;
            usersInfo[_msgSender()][_rewardTokenAddress].isActiveInvested = true;
        }
        
    }

    function withdrawToken(address _tokenAddress, address _rewardTokenAddress, uint256 _amount) external override {
        uint256 userBalance = calculateUserBalance(_rewardTokenAddress);
        if (userBalance >= _amount) {
            IAAVEERC20(_rewardTokenAddress).approve(address(LendAAVE), _amount);
            LendAAVE.withdraw(_tokenAddress, _amount, address(this));
            IAAVEERC20(_tokenAddress).transfer(_msgSender(), _amount);
            usersInfo[_msgSender()][_rewardTokenAddress].withdrawnBalance += _amount;
            if (_amount == userBalance) {
                usersInfo[_msgSender()][_rewardTokenAddress].isActiveInvested = false;
            }
        }        
    }
    
    // public for testing otherwise internal call
    function calculateUserBalance(address _rewardTokenAddress) public view override returns(uint256) {
        uint256 userBalance;
        uint256 userStartVersion = usersInfo[_msgSender()][_rewardTokenAddress].startVersionBlock;
        uint256 currVersion =  zpController.latestVersion();
        uint256 riskPoolCategory;
        for (uint i = userStartVersion; i <= currVersion; i++) {
            uint256 userVersionBalance = userTransactionInfo[_msgSender()][_rewardTokenAddress][i];
            if (zpController.ifProtocolUpdated(protocolID, i)) {
                riskPoolCategory = zpController.getProtocolRiskCategory(protocolID, i);
            }
            if (userVersionBalance > 0) {
                userBalance += userVersionBalance;
            } 
            if (zpController.isRiskPoolLiquidated(i, riskPoolCategory)) {
                userBalance = ((userBalance * zpController.getLiquidationFactor(i)) / 100);
            } 
              
        }
        userBalance -= usersInfo[_msgSender()][_rewardTokenAddress].withdrawnBalance;
        return userBalance;
    }

}