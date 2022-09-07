// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../../dependencies/openzeppelin/Ownable.sol";
import "./../../../../interfaces/Compound/ICErc20.sol";
import "./../../../../interfaces/Compound/IErc20.sol";
import "./../../../../interfaces/Compound/ICompoundImplementation.sol";
import "./../../../../interfaces/IERC20.sol";
import "./../ZPController.sol";
import "./../ZPAccountManager.sol";

contract CompoundPool is Ownable, ICompoundImplementation {
    ZPController zpController;
    
    // userAddress -> tokenAddress -> version -> tokenBalance
    mapping(address => mapping(address => mapping(uint256 => uint256))) public userTokenBalance;
    // userAddress -> tokenAddress -> withdrawnBalance
    mapping(address => mapping(address => uint256)) public userWithdrawnBalance;

    function updateZeroPremiumController(address _controllerAddress) external onlyOwner {
        zpController = ZPController(_controllerAddress);
    }

    function mintERC20Tokens(address _userAddress, address _tokenAddress, uint256 _amount) external override {
        IErc20 token = IErc20(_tokenAddress);
        token.allocateTo(_userAddress, _amount);
    }

    error TransactionFailedError();
    error LowSupplyAmountError();
    function supplyToken(address _tokenAddress, address _rewardTokenAddress, uint256 _amount) external override returns(uint256) {
        if (_amount < 1e10) {
            revert LowSupplyAmountError();
        }
        // IErc20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        // NOTE: Compound Fake ERC20 token doesn't support transferFrom functionality [Real one will support ]
        uint256 currVersion =  zpController.latestVersion();
        uint256 balanceBeforeSupply = ICErc20(_rewardTokenAddress).balanceOf(address(this));
        IErc20(_tokenAddress).approve(_rewardTokenAddress, _amount);
        uint mintResult = ICErc20(_rewardTokenAddress).mint(_amount);
        uint256 balanceAfterSupply = ICErc20(_rewardTokenAddress).balanceOf(address(this));
        userTokenBalance[_msgSender()][_rewardTokenAddress][currVersion] += (balanceAfterSupply - balanceBeforeSupply);
        return mintResult;
    }

    function withdrawToken(address _tokenAddress, address _rewardTokenAddress, uint256 _amount) external override returns (bool) {
        uint256 userBalance = calculateUserBalance(_msgSender(), _rewardTokenAddress);
        if (userBalance >= _amount) {
            ICErc20 rewardToken = ICErc20(_rewardTokenAddress);
            // rewardToken.approve(_rewardTokenAddress, _amount);
            // In Compound, approval is not required
            uint256 balanceBeforeRedeem = IErc20(_tokenAddress).balanceOf(address(this));
            rewardToken.redeem(_amount);
            uint256 balanceAfterRedeem = IErc20(_tokenAddress).balanceOf(address(this));
            uint256 amountToBePaid = (balanceAfterRedeem - balanceBeforeRedeem);
            // IErc20 transfer doesn't work for Compound
            userWithdrawnBalance[_msgSender()][_rewardTokenAddress] += _amount;
            return true;
        }
        return false;
    }

    

    function calculateUserBalance(address userAddress, address _rewardTokenAddress) public view override returns(uint256) {
        uint256 currentUserBalance;
        uint256 currVersion =  zpController.latestVersion();

        for (uint i = 0; i <= currVersion; i++) {
            uint256 userVersionBalance = userTokenBalance[userAddress][_rewardTokenAddress][i];
            if (userVersionBalance > 0) {
                currentUserBalance += ((userVersionBalance * zpController.versionLiquidationFactor(i)) / 100);
            }    
        }
        currentUserBalance -= (userWithdrawnBalance[userAddress][_rewardTokenAddress]);
        return currentUserBalance;
    }
}