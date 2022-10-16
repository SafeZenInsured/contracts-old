// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/ReentrancyGuard.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/ICoveragePool.sol";
import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IProtocolsRegistry.sol";


contract CoveragePool is Ownable, ICoveragePool, ReentrancyGuard {
    uint256 public override totalTokensStaked;
    uint256 private _minCoveragePoolAmount = 1e19;
    IERC20 private _tokenSZT;
    IBuySellSZT private _buySellContract;
    IProtocolsRegistry private _protocolsRegistry;

    constructor(address _buySellAddress, address _SZTTokenAddress) {
        _buySellContract = IBuySellSZT(_buySellAddress);
        _tokenSZT = IERC20(_SZTTokenAddress);
    }

    struct WithdrawWaitPeriod{
        bool ifTimerStarted;
        uint256 SZTTokenCount;
        uint256 canWithdrawTime;
    }

    struct UserInfo {
        bool isActiveInvested;
        uint256 startVersionBlock;
    }

    struct BalanceInfo {
        uint256 depositedAmount;
        uint256 withdrawnAmount;
    }

    /// record the amount of SZT tokens user has overall invested for underwriting
    mapping (address => uint256) private userSZTPoolBalance;

    /// record the user info, i.e. if the user has invested in a particular protocol
    mapping(address => mapping(uint256 => UserInfo)) private usersInfo;

    // user address => protocol id => withdrawal wait period
    mapping (address => mapping(uint256 => WithdrawWaitPeriod)) private checkWaitTime;
    // user address => protocol id => version => underwriterinfo
    mapping(address => mapping(uint256 => mapping(uint256 => BalanceInfo))) private underwritersBalance;

    error TransactionFailedError();
    error NotAMinimumPoolAmountError();

    function updateMinCoveragePoolAmount(uint256 valueInSZT) external onlyOwner {
        _minCoveragePoolAmount = valueInSZT;
    }

    function updateProtocolsRegistry(address protocolRegAddress) external onlyOwner {
        _protocolsRegistry = IProtocolsRegistry(protocolRegAddress);
        emit UpdatedProtocolRegistryAddress(protocolRegAddress);
    }

    /// NOTE: waiting time to be updated in days, for demo in seconds
    uint256 waitingTime = 20;
    function updateWaitingPeriodTime(uint256 timeInDays) external onlyOwner {
        waitingTime = timeInDays * 20 seconds;
        emit UpdatedWaitingPeriod(timeInDays);
    }

    /// NOTE: With transferSZT, you'll need to approve SZT and GSZT tokens
    function underwrite(uint256 value, uint256 protocolID) public override nonReentrant returns(bool) {
        if (value < _minCoveragePoolAmount) {
            revert NotAMinimumPoolAmountError();
        }
        uint256 currVersion = _protocolsRegistry.version() + 1;
        underwritersBalance[_msgSender()][protocolID][currVersion].depositedAmount = value;
        totalTokensStaked += value;
        if (!usersInfo[_msgSender()][protocolID].isActiveInvested) {
            usersInfo[_msgSender()][protocolID].startVersionBlock = currVersion;
            usersInfo[_msgSender()][protocolID].isActiveInvested = true;
        }
        userSZTPoolBalance[_msgSender()] += value;
        bool success = _tokenSZT.transferFrom(_msgSender(), address(this), value);
        bool addSuccess = _protocolsRegistry.addProtocolLiquidation(protocolID, value); 
        if (success && addSuccess) {
            emit UnderwritePool(_msgSender(), protocolID, value);
            return true;
        }
        
        return false;
    }
    
    function activateWithdrawalTimer(uint256 value, uint256 protocolID) external override returns(bool) {
        if (
            (!(checkWaitTime[_msgSender()][protocolID].ifTimerStarted)) || 
            (checkWaitTime[_msgSender()][protocolID].SZTTokenCount < value)
        ) {
            WithdrawWaitPeriod storage waitingTimeCountdown = checkWaitTime[_msgSender()][protocolID];
            waitingTimeCountdown.ifTimerStarted = true;
            waitingTimeCountdown.SZTTokenCount = value;
            waitingTimeCountdown.canWithdrawTime = waitingTime + block.timestamp;
            return true;
        }
        return false;
    }
    
    function withdraw(uint256 value, uint256 protocolID) external override nonReentrant returns(bool) {
        uint256 userBalance = calculateUserBalance(protocolID);
        if (
            (userBalance < value) || 
            (block.timestamp < checkWaitTime[_msgSender()][protocolID].canWithdrawTime) || 
            (value > checkWaitTime[_msgSender()][protocolID].SZTTokenCount)
        ) {
            revert TransactionFailedError();
        }
        uint256 currVersion = _protocolsRegistry.version();
        underwritersBalance[_msgSender()][protocolID][currVersion].withdrawnAmount += value;
        checkWaitTime[_msgSender()][protocolID].SZTTokenCount -= value;
        if (checkWaitTime[_msgSender()][protocolID].SZTTokenCount == value) {
            checkWaitTime[_msgSender()][protocolID].ifTimerStarted = false;
        }
        totalTokensStaked -= value;
        userSZTPoolBalance[_msgSender()] -= value;
        bool removeSuccess = _protocolsRegistry.removeProtocolLiquidation(protocolID, value);
        bool success = _tokenSZT.transfer(_msgSender(), value);
        if (removeSuccess && success) {
            emit PoolWithdrawn(_msgSender(), protocolID, value);
            return true;
        }
        return success;
    }

    function buyAndStakeSZT(uint256 value, uint256 protocolID) external returns(bool) {
        bool buySZTSuccess = _buySellContract.buySZTToken(value);
        if (buySZTSuccess) {
            totalTokensStaked += value;
            bool stakeSZTSuccess = underwrite(value, protocolID);
            return stakeSZTSuccess;
        }
        return buySZTSuccess;
    }

    function calculateUserBalance(uint256 protocolID) public view override returns(uint256) {
        uint256 userBalance = 0;
        uint256 userStartVersion = usersInfo[_msgSender()][protocolID].startVersionBlock;
        uint256 currVersion =  _protocolsRegistry.version();
        uint256 premiumEarnedFlowRate = 0;
        uint256 userPremiumEarned = 0;
        uint256 riskPoolCategory = 0;
        for (uint i = userStartVersion; i <= currVersion; i++) {
            uint256 userVersionDepositedBalance = underwritersBalance[_msgSender()][protocolID][i].depositedAmount;
            uint256 userVersionWithdrawnBalance = underwritersBalance[_msgSender()][protocolID][i].withdrawnAmount;
            if (_protocolsRegistry.ifProtocolUpdated(protocolID, i)) {
                riskPoolCategory = _protocolsRegistry.getProtocolVersionRiskCategory(protocolID, i);
            }
            if (_protocolsRegistry.getEarnedPremiumFlowRate(riskPoolCategory, i) != premiumEarnedFlowRate) {
                premiumEarnedFlowRate = _protocolsRegistry.getEarnedPremiumFlowRate(riskPoolCategory, i);
            }
            if (userVersionDepositedBalance > 0) {
                userBalance += userVersionDepositedBalance;
            } 
            if (userVersionWithdrawnBalance > 0) {
                userBalance -= userVersionWithdrawnBalance;
            } 
            if (_protocolsRegistry.isRiskPoolLiquidated(i, riskPoolCategory)) {
                userBalance = (userBalance * _protocolsRegistry.getLiquidationFactor(riskPoolCategory, i)) / 100;
            } 
            userPremiumEarned = (userBalance * premiumEarnedFlowRate)/_protocolsRegistry.getGlobalProtocolLiquidity(riskPoolCategory, i);
              
        }
        userBalance += userPremiumEarned;
        return userBalance;
    }

    function getUnderwriteSZTBalance() external view override returns(uint256) {
        return userSZTPoolBalance[_msgSender()];
    }
}