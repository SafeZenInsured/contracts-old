// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../../../../interfaces/AAVE/IAAVE.sol"; // aave contracts to supply and borrow
import "./../../../../../interfaces/AAVE/IAAVEERC20.sol"; 
import "./../../../../../interfaces/AAVE/IAAVEImplementation.sol"; 
import "./../../../../dependencies/openzeppelin/Ownable.sol"; // accessable by admin
import "./../ZPController.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance

// TODO: ADDING EVENTS
contract AAVE is Ownable, IAAVEImplementation {
    IAAVE private _lendingAAVE;  // AAVE v3 Supply and Withdraw Interface
    SmartContractZPController private _zpController;  // Zero Premium Controller Interface
    uint256 private _protocolID;  // Unique Protocol ID

    /// @dev: Struct storing the user info
    /// @param isActiveInvested: checks if the user has already deposited funds in AAVE via us
    /// @param startVersionBlock: keeps a record with which version user started using our protocol
    /// @param withdrawnBalance: keeps a record of the amount the user has withdrawn
    struct UserInfo {
        bool isActiveInvested;
        uint256 startVersionBlock;
        uint256 withdrawnBalance;
    }

    /// Maps --> User Address => Reward Token Address => UserInfo struct
    mapping(address => mapping(address => UserInfo)) private usersInfo;
    /// Maps --> User Address => Reward Token Address => Version => UserTransactionInfo
    mapping(address => mapping(address => mapping(uint256 => uint256))) private userTransactionInfo;

    /// @dev initializing contract with AAVE v3 lending pool address and Zero Premium controller address
    /// @param _lendingAddress: AAVE v3 lending address
    /// @param _controllerAddress: Zero Premium Controller address
    constructor(
        address _lendingAddress, 
        address _controllerAddress
    ) {
        _lendingAAVE = IAAVE(_lendingAddress);
        _zpController = SmartContractZPController(_controllerAddress);
    }

    /// @dev Initialize this function first before running any other function
    /// @dev Registers the AAVE protocol in the Zero Premium Controller protocol list
    /// @param protocolName: name of the protocol: AAVE
    /// @param deployedAddress: address of the AAVE lending pool
    /// @param isCommunityGoverned: checks if the protocol is community governed or not
    /// @param riskFactor: registers the risk score of AAVE; 0 being lowest, and 100 being highest
    /// @param riskPoolCategory: registers the risk pool category; 1 - low, 2-medium, and 3- high risk
    function addAAVEProtocolInfo(
        string memory protocolName,
        address deployedAddress,
        bool isCommunityGoverned,
        uint256 riskFactor,
        uint256 riskPoolCategory
    ) external onlyOwner {
        _protocolID = _zpController.protocolID();
        _zpController.addCoveredProtocol(protocolName, deployedAddress, isCommunityGoverned, riskFactor, riskPoolCategory);
    } 

    /// @dev minting function for testnet purposes
    /// @param tokenAddress: token address of the supplied token to AAVE v3 pool
    /// @param amount: amount of the tokens to be minted
    function mintERC20Tokens(address tokenAddress, uint256 amount) public override {
        IAAVEERC20(tokenAddress).mint(msg.sender, amount);
    }

    error LowSupplyAmountError();
    /// @dev supply function to supply token to the AAVE v3 Pool
    /// @param tokenAddress: token address of the supplied token, e.g. DAI
    /// @param rewardTokenAddress: token address of the received token, e.g. aDAI
    /// @param amount: amount of the tokens supplied
    function supplyToken(address tokenAddress, address rewardTokenAddress, uint256 amount) external override {
        if (amount < 1e10) {
            revert LowSupplyAmountError();
        }
        IAAVEERC20(tokenAddress).transferFrom(_msgSender(), address(this), amount);
        uint256 currVersion =  _zpController.latestVersion();
        uint256 balanceBeforeSupply = IAAVEERC20(rewardTokenAddress).balanceOf(address(this));
        IAAVEERC20(tokenAddress).approve(address(_lendingAAVE), amount);
        _lendingAAVE.supply(tokenAddress, amount, address(this), 0);
        uint256 balanceAfterSupply = IAAVEERC20(rewardTokenAddress).balanceOf(address(this));
        userTransactionInfo[_msgSender()][rewardTokenAddress][currVersion] += (balanceAfterSupply - balanceBeforeSupply);
        if (!usersInfo[_msgSender()][rewardTokenAddress].isActiveInvested) {
            usersInfo[_msgSender()][rewardTokenAddress].startVersionBlock = currVersion;
            usersInfo[_msgSender()][rewardTokenAddress].isActiveInvested = true;
        }
    }

    /// @dev to withdraw the tokens from the AAVE v3 lending pool
    /// @param tokenAddress: token address of the supplied token, e.g. DAI
    /// @param rewardTokenAddress: token address of the received token, e.g. aDAI
    /// @param amount: amount of the tokens to be withdrawn
    function withdrawToken(address tokenAddress, address rewardTokenAddress, uint256 amount) external override {
        uint256 userBalance = calculateUserBalance(rewardTokenAddress);
        if (userBalance >= amount) {
            IAAVEERC20(rewardTokenAddress).approve(address(_lendingAAVE), amount);
            _lendingAAVE.withdraw(tokenAddress, amount, address(this));
            IAAVEERC20(tokenAddress).transfer(_msgSender(), amount);
            usersInfo[_msgSender()][rewardTokenAddress].withdrawnBalance += amount;
            if (amount == userBalance) {
                usersInfo[_msgSender()][rewardTokenAddress].isActiveInvested = false;
            }
        }        
    }
    
    /// @dev calculates the user balance
    /// @param rewardTokenAddress: token address of the token received, e.g. aDAI
    function calculateUserBalance(address rewardTokenAddress) public view override returns(uint256) {
        uint256 userBalance;
        uint256 userStartVersion = usersInfo[_msgSender()][rewardTokenAddress].startVersionBlock;
        uint256 currVersion =  _zpController.latestVersion();
        uint256 riskPoolCategory;
        for (uint i = userStartVersion; i <= currVersion; i++) {
            uint256 userVersionBalance = userTransactionInfo[_msgSender()][rewardTokenAddress][i];
            if (_zpController.ifProtocolUpdated(_protocolID, i)) {
                riskPoolCategory = _zpController.getProtocolRiskCategory(_protocolID, i);
            }
            if (userVersionBalance > 0) {
                userBalance += userVersionBalance;
            } 
            if (_zpController.isRiskPoolLiquidated(i, riskPoolCategory)) {
                userBalance = ((userBalance * _zpController.getLiquidationFactor(i)) / 100);
            } 
              
        }
        userBalance -= usersInfo[_msgSender()][rewardTokenAddress].withdrawnBalance;
        return userBalance;
    }
}