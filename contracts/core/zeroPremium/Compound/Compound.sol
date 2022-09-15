// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../../dependencies/openzeppelin/Ownable.sol";
import "./../../../../interfaces/Compound/ICErc20.sol";
import "./../../../../interfaces/Compound/IErc20.sol";
import "./../../../../interfaces/Compound/ICompoundImplementation.sol";
import "./../../../../interfaces/IERC20.sol";
import "./../ZPController.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract CompoundPool is Ownable, ICompoundImplementation {
    ZPController zpController;
    uint256 protocolID;
    
    struct UserInfo {
        bool isActiveInvested;
        uint256 startVersionBlock;
        uint256 withdrawnBalance;
    }

    /// User Address => Reward Token Address => Version => UserTransactionInfo
    mapping(address => mapping(address => mapping(uint256 => uint256))) private userTokenBalance;
    mapping(address => mapping(address => UserInfo)) private usersInfo;

    constructor(address _controllerAddress) {
        zpController = ZPController(_controllerAddress);
    }

    function mintERC20Tokens(address _userAddress, address _tokenAddress, uint256 _amount) external override {
        IErc20 token = IErc20(_tokenAddress);
        token.allocateTo(_userAddress, _amount);
    }

    /// Initialize this function first before running any other function
    function addCompoundProtocolInfo(
        string memory _protocolName,
        address _deployedAddress,
        bool _isCommunityGoverned,
        uint256 _riskFactor,
        uint256 _riskPoolCategory
    ) external onlyOwner {
        protocolID = zpController.protocolID();
        zpController.addCoveredProtocol(_protocolName, _deployedAddress, _isCommunityGoverned, _riskFactor, _riskPoolCategory);
    }

    error TransactionFailedError();
    error LowSupplyAmountError();
    function supplyToken(address _tokenAddress, address _rewardTokenAddress, uint256 _amount) external override returns(uint256) {
        if (_amount < 1e10) {
            revert LowSupplyAmountError();
        }
        IErc20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        /// NOTE: Compound Fake ERC20 token doesn't support transferFrom functionality [Real one will support ]
        uint256 currVersion =  zpController.latestVersion();
        uint256 balanceBeforeSupply = ICErc20(_rewardTokenAddress).balanceOf(address(this));
        IErc20(_tokenAddress).approve(_rewardTokenAddress, _amount);
        uint mintResult = ICErc20(_rewardTokenAddress).mint(_amount);
        uint256 balanceAfterSupply = ICErc20(_rewardTokenAddress).balanceOf(address(this));
        userTokenBalance[_msgSender()][_rewardTokenAddress][currVersion] += (balanceAfterSupply - balanceBeforeSupply);
        if (!usersInfo[_msgSender()][_rewardTokenAddress].isActiveInvested) {
            usersInfo[_msgSender()][_rewardTokenAddress].startVersionBlock = currVersion;
            usersInfo[_msgSender()][_rewardTokenAddress].isActiveInvested = true;
        }
        return mintResult;
    }

    function withdrawToken(address _tokenAddress, address _rewardTokenAddress, uint256 _amount) external override returns (bool) {
        uint256 userBalance = calculateUserBalance(_rewardTokenAddress);
        if (userBalance >= _amount) {
            ICErc20 rewardToken = ICErc20(_rewardTokenAddress);
            // rewardToken.approve(_rewardTokenAddress, _amount);
            // In Compound, approval is not required
            uint256 balanceBeforeRedeem = IErc20(_tokenAddress).balanceOf(address(this));
            rewardToken.redeem(_amount);
            uint256 balanceAfterRedeem = IErc20(_tokenAddress).balanceOf(address(this));
            uint256 amountToBePaid = (balanceAfterRedeem - balanceBeforeRedeem);
            // IErc20(_tokenAddress).transferFrom(address(this), _msgSender(), amountToBePaid);
            // IErc20 transfer doesn't work for Compound
            usersInfo[_msgSender()][_rewardTokenAddress].withdrawnBalance += _amount;
            if (_amount == userBalance) {
                usersInfo[_msgSender()][_rewardTokenAddress].isActiveInvested = false;
            }
            return true;
        }
        return false;
    }

    

    function calculateUserBalance(address _rewardTokenAddress) public view override returns(uint256) {
        uint256 userBalance;
        uint256 userStartVersion = usersInfo[_msgSender()][_rewardTokenAddress].startVersionBlock;
        uint256 currVersion =  zpController.latestVersion();
        uint256 riskPoolCategory;
        for (uint i = userStartVersion; i <= currVersion; i++) {
            uint256 userVersionBalance = userTokenBalance[_msgSender()][_rewardTokenAddress][i];
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