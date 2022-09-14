// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/ISZTStaking.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/IERC20.sol";


contract CoveragePool is Ownable {
    uint256 public minCoveragePoolAmount;
    IBuySellSZT public buySellContract;
    IERC20 public SZTToken;
    uint256 public totalTokensStaked;

    constructor(address _buySellAddress, address _SZTTokenAddress) {
        buySellContract = IBuySellSZT(_buySellAddress);
        SZTToken = IERC20(_SZTTokenAddress);
    }

    struct withdrawWaitPeriod{
        bool ifTimerStarted;
        uint256 SZTTokenCount;
        uint256 canWithdrawTime;
    }

    struct UnderwriterInfo {
        uint256 coverageAmount;
        uint256 startTime;
    }

    // protocol id => withdrawal wait period
    mapping (address => mapping(uint256 => withdrawWaitPeriod)) private checkWaitTime;

    mapping(address => mapping(uint256 => UnderwriterInfo)) private underwriters;

    error NotAMinimumPoolAmountError();
    function underwrite(uint256 _value, uint256 _protocolID) public returns(bool) {
        if (_value < minCoveragePoolAmount) {
            revert NotAMinimumPoolAmountError();
        }
        UnderwriterInfo storage underwriter = underwriters[_msgSender()][_protocolID];
        underwriter.coverageAmount += _value;
        totalTokensStaked += _value;
        bool success = buySellContract.transferSZT(_msgSender(), address(this), _value);
        return success;
    }

    /// NOTE: waiting time to be updated in days
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
        UnderwriterInfo storage underwriter = underwriters[_msgSender()][_protocolID];
        if (
            (underwriter.coverageAmount < _value) || 
            (block.timestamp < checkWaitTime[_msgSender()][_protocolID].canWithdrawTime) || 
            (_value > checkWaitTime[_msgSender()][_protocolID].SZTTokenCount)
        ) {
            revert TransactionFailedError();
        }
        SZTToken.approve(_msgSender(), _value);
        bool success = buySellContract.transferSZT(address(this), _msgSender(), _value);
        underwriter.coverageAmount -= _value;
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
}