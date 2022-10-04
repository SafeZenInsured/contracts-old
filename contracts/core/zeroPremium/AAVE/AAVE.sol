// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./../../../../interfaces/AAVE/IAAVE.sol"; // aave contracts to supply and borrow
import "./../../../../interfaces/AAVE/IAAVEERC20.sol"; 
import "./../../../../interfaces/AAVE/IAAVEImplementation.sol"; 
import "./../../../dependencies/openzeppelin/Ownable.sol"; // accessable by admin
import "./../ZPController.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance

// TODO: ADDING EVENTS
contract AAVE is Ownable, IAAVEImplementation {
    IAAVE LendAAVE;  // AAVE v3 Supply and Withdraw Interface
    ZPController zpController;  // Zero Premium Controller Interface
    uint256 protocolID;  // Unique Protocol ID

    /// @dev: Struct storing the user info
    /// @param isActiveInvested: checks if the user has already deposited funds in AAVE via us
    /// @param startVersionBlock: keeps a record with which version user started using our protocol
    /// @param withdrawnBalance: keeps a record of the amount the user has withdrawn
    struct UserInfo {
        bool isActiveInvested;
        uint256 startVersionBlock;
        uint256 withdrawnBalance;
    }

    /// Maps --> User Address => Reward Token Address => Version => UserTransactionInfo
    mapping(address => mapping(address => mapping(uint256 => uint256))) private userTransactionInfo;
    /// Maps --> User Address => Reward Token Address => UserInfo struct
    mapping(address => mapping(address => UserInfo)) private usersInfo;

    /// @dev initializing contract with AAVE v3 lending pool address and Zero Premium controller address
    /// @param _lendingAddress: AAVE v3 lending address
    /// @param _controllerAddress: Zero Premium Controller address
    constructor(
        address _lendingAddress, 
        address _controllerAddress
    ) {
        LendAAVE = IAAVE(_lendingAddress);
        zpController = ZPController(_controllerAddress);
    }

    /// @dev Initialize this function first before running any other function
    /// @dev Registers the AAVE protocol in the Zero Premium Controller protocol list
    /// @param _protocolName: name of the protocol: AAVE
    /// @param _deployedAddress: address of the AAVE lending pool
    /// @param _isCommunityGoverned: checks if the protocol is community governed or not
    /// @param _riskFactor: registers the risk score of AAVE; 0 being lowest, and 100 being highest
    /// @param _riskPoolCategory: registers the risk pool category; 1 - low, 2-medium, and 3- high risk
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

    /// @dev minting function for testnet purposes
    /// @param tokenAddress: token address of the supplied token to AAVE v3 pool
    /// @param amount: amount of the tokens to be minted
    function mintERC20Tokens(address tokenAddress, uint256 amount) public override {
        IAAVEERC20(tokenAddress).mint(msg.sender, amount);
    }

    error LowSupplyAmountError();
    /// @dev supply function to supply token to the AAVE v3 Pool
    /// @param _tokenAddress: token address of the supplied token, e.g. DAI
    /// @param _rewardTokenAddress: token address of the received token, e.g. aDAI
    /// @param _amount: amount of the tokens supplied
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

    /// @dev to withdraw the tokens from the AAVE v3 lending pool
    /// @param _tokenAddress: token address of the supplied token, e.g. DAI
    /// @param _rewardTokenAddress: token address of the received token, e.g. aDAI
    /// @param _amount: amount of the tokens to be withdrawn
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
    
    /// @dev calculates the user balance
    /// @param _rewardTokenAddress: token address of the token received, e.g. aDAI
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