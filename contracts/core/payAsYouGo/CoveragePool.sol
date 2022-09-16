// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/ISZTStaking.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IProtocolsRegistry.sol";


contract CoveragePool is Ownable {
    uint256 public minCoveragePoolAmount;
    IBuySellSZT public buySellContract;
    IERC20 public SZTToken;
    uint256 public totalTokensStaked;
    IProtocolsRegistry public protocolsRegistry;

    constructor(address _buySellAddress, address _SZTTokenAddress) {
        buySellContract = IBuySellSZT(_buySellAddress);
        SZTToken = IERC20(_SZTTokenAddress);
    }

    function updateProtocolsRegistry(address _protocolRegAddress) external onlyOwner {
        protocolsRegistry = IProtocolsRegistry(_protocolRegAddress);
    }

    struct withdrawWaitPeriod{
        bool ifTimerStarted;
        uint256 SZTTokenCount;
        uint256 canWithdrawTime;
    }

    struct UserInfo {
        bool isActiveInvested;
        uint256 startVersionBlock;
        uint256 withdrawnBalance;
    }

    // user address => protocol id => withdrawal wait period
    mapping (address => mapping(uint256 => withdrawWaitPeriod)) private checkWaitTime;
    // user address => protocol id => version => underwriterinfo
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private underwriterBalance;

    mapping(address => mapping(uint256 => UserInfo)) private usersInfo;

    error NotAMinimumPoolAmountError();
    function underwrite(uint256 _value, uint256 _protocolID) public returns(bool) {
        if (_value < minCoveragePoolAmount) {
            revert NotAMinimumPoolAmountError();
        }
        uint256 currVersion = protocolsRegistry.version();
        protocolsRegistry.addProtocolLiquidation(_protocolID, _value); // first this, then underwriterBalance
        underwriterBalance[_msgSender()][_protocolID][currVersion] = _value;
        totalTokensStaked += _value;
        if (!usersInfo[_msgSender()][_protocolID].isActiveInvested) {
            usersInfo[_msgSender()][_protocolID].startVersionBlock = currVersion;
            usersInfo[_msgSender()][_protocolID].isActiveInvested = true;
        }
        bool success = buySellContract.transferSZT(_msgSender(), address(this), _value);
        return success;
    }

    /// NOTE: waiting time to be updated in days, temporary function
    uint256 waitingTime = 20;
    function updateWaitingPeriodTime(uint256 _timeInDays) external onlyOwner {
        waitingTime = _timeInDays * 20 seconds;
    }
    
    function activateWithdrawalTimer(uint256 _value, uint256 _protocolID) external returns(bool) {
        if (
            (!(checkWaitTime[_msgSender()][_protocolID].ifTimerStarted)) || 
            (checkWaitTime[_msgSender()][_protocolID].SZTTokenCount < _value)
        ) {
            withdrawWaitPeriod storage waitingTimeCountdown = checkWaitTime[_msgSender()][_protocolID];
            waitingTimeCountdown.ifTimerStarted = true;
            waitingTimeCountdown.SZTTokenCount = _value;
            waitingTimeCountdown.canWithdrawTime = waitingTime + block.timestamp;
            return true;
        }
        return false;
    }

    error TransactionFailedError();
    function withdraw(uint256 _value, uint256 _protocolID) external returns(bool) {
        uint256 userBalance = calculateUserBalance(_protocolID);
        if (
            (userBalance < _value) || 
            (block.timestamp < checkWaitTime[_msgSender()][_protocolID].canWithdrawTime) || 
            (_value > checkWaitTime[_msgSender()][_protocolID].SZTTokenCount)
        ) {
            revert TransactionFailedError();
        }
        SZTToken.approve(_msgSender(), _value);
        bool success = buySellContract.transferSZT(address(this), _msgSender(), _value);
        usersInfo[_msgSender()][_protocolID].withdrawnBalance += _value;
        checkWaitTime[_msgSender()][_protocolID].SZTTokenCount -= _value;
        if (checkWaitTime[_msgSender()][_protocolID].SZTTokenCount == _value) {
            checkWaitTime[_msgSender()][_protocolID].ifTimerStarted = false;
        }
        totalTokensStaked -= _value;
        return success;
    }

    function buyAndStakeSZT(uint256 _value, uint256 _protocolID) external returns(bool) {
        bool buySZTSuccess = buySellContract.buySZTToken(_value);
        if (buySZTSuccess) {
            bool stakeSZTSuccess = underwrite(_value, _protocolID);
            totalTokensStaked += _value;
            return stakeSZTSuccess;
        }
        return false;
    }

    // public for testing otherwise internal call
    function calculateUserBalance(uint256 _protocolID) public view returns(uint256) {
        uint256 userBalance;
        uint256 userStartVersion = usersInfo[_msgSender()][_protocolID].startVersionBlock;
        uint256 currVersion =  protocolsRegistry.version();
        uint256 riskPoolCategory;
        for (uint i = userStartVersion; i <= currVersion; i++) {
            uint256 userVersionBalance = underwriterBalance[_msgSender()][_protocolID][i];
            if (protocolsRegistry.ifProtocolUpdated(_protocolID, i)) {
                riskPoolCategory = protocolsRegistry.getProtocolRiskCategory(_protocolID, i);
            }
            if (userVersionBalance > 0) {
                userBalance += userVersionBalance;
            } 
            if (protocolsRegistry.isRiskPoolLiquidated(i, riskPoolCategory)) {
                userBalance = ((userBalance * protocolsRegistry.getLiquidationFactor(riskPoolCategory, i)) / 100);
            } 
              
        }
        userBalance -= usersInfo[_msgSender()][_protocolID].withdrawnBalance;
        return userBalance;
    }
}