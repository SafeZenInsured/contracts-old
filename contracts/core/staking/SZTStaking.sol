// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/ReentrancyGuard.sol";
import "./../../../interfaces/ISZTStaking.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/IERC20.sol";


/// NOTE: Staking tokens would be used for activities like flash loans 
/// to generate rewards for the staked users
contract SZTStaking is Ownable, ISZTStaking, ReentrancyGuard {
    uint256 private minStakeValue = 1e18;
    uint256 public override totalTokensStaked;
    IERC20 private _tokenSZT;
    IBuySellSZT private buySellContract;
    
    constructor(address _buySellAddress, address _tokenAddressSZT) {
        buySellContract = IBuySellSZT(_buySellAddress);
        _tokenSZT = IERC20(_tokenAddressSZT);
    }

    struct WithdrawWaitPeriod{
        bool ifTimerStarted;
        uint256 SZTTokenCount;
        uint256 canWithdrawTime;
    }

    struct StakerInfo {
        uint256 amountStaked;
        uint256 rewardEarned;
    }

    mapping (address => WithdrawWaitPeriod) private checkWaitTime;

    mapping(address => StakerInfo) private stakers;

    function updateMinimumStakeAmount(uint256 value) external onlyOwner {
        minStakeValue = value;
        emit UpdatedMinStakingAmount(value);
    }

    uint256 public withdrawTimer = 1 minutes;
    /// NOTE: Changing minutes to day [minutes done for testing purpose]
    function setWithdrawTime(uint256 timeInMinutes) external onlyOwner {
        withdrawTimer = timeInMinutes * 1 minutes;
        emit UpdatedWithdrawTimer(timeInMinutes);
    }

    /// NOTE: approve SZT to BuySellContract before calling this function 
    error NotAMinimumStakeAmountError();
    function stakeSZT(uint256 value) public override nonReentrant returns(bool) {
        if (value < minStakeValue) {
            revert NotAMinimumStakeAmountError();
        }
        StakerInfo storage staker = stakers[_msgSender()];
        staker.amountStaked += value;
        totalTokensStaked += value;
        bool success = _tokenSZT.transferFrom(_msgSender(), address(this), value);
        if (!success) {
            revert TransactionFailedError();
        }
        emit StakedSZT(_msgSender(), value);
        return true;
    }
    
    // 48 hours waiting period
    function activateWithdrawalTimer(uint256 value) external override returns(bool) {
        if (
            (!(checkWaitTime[_msgSender()].ifTimerStarted)) || 
            (checkWaitTime[_msgSender()].SZTTokenCount < value)
        ) {
            WithdrawWaitPeriod storage waitingTimeCountdown = checkWaitTime[_msgSender()];
            waitingTimeCountdown.ifTimerStarted = true;
            waitingTimeCountdown.SZTTokenCount = value;
            waitingTimeCountdown.canWithdrawTime = withdrawTimer + block.timestamp;
            return true;
        }
        return false;
    }

    error TransactionFailedError();
    function withdrawSZT(uint256 value) external override nonReentrant returns(bool) {
        StakerInfo storage staker = stakers[_msgSender()];
        if (
            (staker.amountStaked < value) || 
            (block.timestamp < checkWaitTime[_msgSender()].canWithdrawTime) || 
            (value > checkWaitTime[_msgSender()].SZTTokenCount)
        ) {
            revert TransactionFailedError();
        }
        totalTokensStaked -= value;
        staker.amountStaked -= value;
        if (checkWaitTime[_msgSender()].SZTTokenCount == value) {
            checkWaitTime[_msgSender()].ifTimerStarted = false;
        }
        checkWaitTime[_msgSender()].SZTTokenCount -= value;
        bool success = _tokenSZT.transfer(_msgSender(), value);
        if (!success) {
            revert TransactionFailedError();
        }
        emit UnstakedSZT(_msgSender(), value);
        return true;
    }

    function getUserStakedSZTBalance() external view override returns(uint256) {
        return stakers[_msgSender()].amountStaked;
    }

    function getStakerRewardInfo() external view returns(uint256) {
        return stakers[_msgSender()].rewardEarned;
    }
}