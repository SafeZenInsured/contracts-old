// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/ISZTStaking.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/IERC20.sol";


/// NOTE: Staking tokens would be used for activities like flash loans 
/// to generate rewards for the staked users
contract SZTStaking is Ownable, ISZTStaking {
    uint256 public minStakeValue;
    IBuySellSZT public buySellContract;
    IERC20 public SZTToken;
    IERC20 public GSZTToken;
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

    struct StakerInfo {
        uint256 amountStaked;
        uint256 rewardEarned;
    }

    mapping (address => withdrawWaitPeriod) private checkWaitTime;

    mapping(address => StakerInfo) private stakers;

    /// NOTE: approve SZT to BuySellContract before calling this function 
    error NotAMinimumStakeAmountError();
    function stakeSZT(uint256 _value) public override returns(bool) {
        if (_value < minStakeValue) {
            revert NotAMinimumStakeAmountError();
        }
        StakerInfo storage staker = stakers[_msgSender()];
        staker.amountStaked += _value;
        totalTokensStaked += _value;
        bool success = buySellContract.stakingTransferSZT(_msgSender(), address(this), _value);
        return success;
    }

    uint256 public withdrawTimer = 1 minutes;
    /// NOTE: Changing minutes to day [minutes done for testing purpose]
    function setWithdrawTime(uint256 _time) external onlyOwner {
        withdrawTimer = _time * 1 minutes;
    }
    
    // 48 hours waiting period
    function activateWithdrawalTimer(uint256 _value) external override returns(bool) {
        if (
            (!(checkWaitTime[_msgSender()].ifTimerStarted)) || 
            (checkWaitTime[_msgSender()].SZTTokenCount < _value)
        ) {
            withdrawWaitPeriod storage waitingTimeCountdown = checkWaitTime[_msgSender()];
            waitingTimeCountdown.ifTimerStarted = true;
            waitingTimeCountdown.SZTTokenCount = _value;
            waitingTimeCountdown.canWithdrawTime = withdrawTimer + block.timestamp;
            return true;
        }
        return false;
    }

    error TransactionFailedError();
    function withdrawSZT(uint256 _value) external override returns(bool) {
        StakerInfo storage staker = stakers[_msgSender()];
        if (
            (staker.amountStaked < _value) || 
            (block.timestamp < checkWaitTime[_msgSender()].canWithdrawTime) || 
            (_value > checkWaitTime[_msgSender()].SZTTokenCount)
        ) {
            revert TransactionFailedError();
        }
        SZTToken.approve(address(buySellContract), _value);
        bool success = buySellContract.stakingTransferSZT(address(this), _msgSender(), _value);
        staker.amountStaked -= _value;
        if (checkWaitTime[_msgSender()].SZTTokenCount == _value) {
            checkWaitTime[_msgSender()].ifTimerStarted = false;
        }
        checkWaitTime[_msgSender()].SZTTokenCount -= _value;
        totalTokensStaked -= _value;
        return success;
    }

    function buyAndStakeSZT(uint256 _value) external override returns(bool) {
        bool buySZTSuccess = buySellContract.buySZTToken(_value);
        if (buySZTSuccess) {
            bool stakeSZTSuccess = stakeSZT(_value);
            totalTokensStaked += _value;
            return stakeSZTSuccess;
        }
        return false;
    }

    function getUserBalance(address userAddress) external view override returns(uint256) {
        return stakers[userAddress].amountStaked;
    }
}