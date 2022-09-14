// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Context.sol";
import "./../buySell/BuySellSZT.sol";
import "./../token/SZTERC20.sol";

/// NOTE: Staking tokens would be used for activities like flash loans 
/// to generate rewards for the staked users
contract SZTStaking is Context{
    uint256 minStakeValue;
    BuySellSZT buySellContract;
    SZT SZTToken;

    constructor(address _buySellAddress, address _SZTTokenAddress) {
        buySellContract = BuySellSZT(_buySellAddress);
        SZTToken = SZT(_SZTTokenAddress);
    }

    struct withdrawWaitPeriod{
        bool ifTimerStarted;
        uint256 SZTTokenCount;
        uint256 canWithdrawTime;
    }

    struct StakerInfo {
        uint256 amountStaked;
        uint256 rewardEarned;
    }

    mapping (address => withdrawWaitPeriod) private checkWaitTime;

    mapping(address => StakerInfo) private stakers;

    error NotAMinimumStakeAmountError();
    function stakeSZT(uint256 _value) public returns(bool) {
        if (_value < minStakeValue) {
            revert NotAMinimumStakeAmountError();
        }
        StakerInfo storage staker = stakers[_msgSender()];
        staker.amountStaked += _value;
        bool success = buySellContract.transferSZT(_msgSender(), address(this), _value);
        return success;
    }

    
    // 48 hours waiting period
    function activateWithdrawalTimer(uint256 _value) external returns(bool) {
        if (
            (!(checkWaitTime[_msgSender()].ifTimerStarted)) || 
            (checkWaitTime[_msgSender()].SZTTokenCount < _value)
        ) {
            withdrawWaitPeriod storage waitingTimeCountdown = checkWaitTime[_msgSender()];
            waitingTimeCountdown.ifTimerStarted = true;
            waitingTimeCountdown.SZTTokenCount = _value;
            waitingTimeCountdown.canWithdrawTime = 2 days + block.timestamp;
            return true;
        }
        return false;
    }

    function withdrawSZT(uint256 _value) public returns(bool) {
        StakerInfo storage staker = stakers[_msgSender()];
        if (
            (staker.amountStaked >= _value) &&
            (block.timestamp >= checkWaitTime[_msgSender()].canWithdrawTime) &&
            (_value <= checkWaitTime[_msgSender()].SZTTokenCount)
        ) {
            SZTToken.approve(_msgSender(), _value);
            bool success = buySellContract.transferSZT(address(this), _msgSender(), _value);
            staker.amountStaked -= _value;
            checkWaitTime[_msgSender()].SZTTokenCount -= _value;
            if (checkWaitTime[_msgSender()].SZTTokenCount == _value) {
                checkWaitTime[_msgSender()].ifTimerStarted = false;
            }
            return success;
        }
        return false;
    }

    function buyAndStakeSZT(uint256 _value) external returns(bool) {
        bool buySZTSuccess = buySellContract.buySZTToken(_value);
        if (buySZTSuccess) {
            bool stakeSZTSuccess = stakeSZT(_value);
            return stakeSZTSuccess;
        }
        return false;
    }
}