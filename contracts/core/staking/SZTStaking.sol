// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Context.sol";
import "./../buySell/BuySellSZT.sol";
import "./../token/SZTERC20.sol";

contract SZTStaking is Context{
    uint256 minStakeValue;
    BuySellSZT buySellContract;
    SZT SZTToken;

    constructor(address _buySellAddress, address _SZTTokenAddress) {
        buySellContract = BuySellSZT(_buySellAddress);
        SZTToken = SZT(_SZTTokenAddress);
    }

    struct StakerInfo {
        uint256 amountStaked;
        uint256 rewardEarned;
    }

    mapping(address => StakerInfo) public stakers;

    function stakeSZT(uint256 _value) public returns(bool) {
        StakerInfo storage staker = stakers[_msgSender()];
        staker.amountStaked += _value;
        bool success = buySellContract.transferSZT(_msgSender(), address(this), _value);
        return success;
    }

    function withdrawSZT(uint256 _value) public returns(bool) {
        StakerInfo storage staker = stakers[_msgSender()];
        if (staker.amountStaked >= _value) {
            SZTToken.approve(_msgSender(), _value);
            bool success = buySellContract.transferSZT(address(this), _msgSender(), _value);
            staker.amountStaked -= _value;
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

    function unstakeAndRequestSellSZT(uint256 _value) external returns(bool) {
        bool unstakeSZTSuccess = withdrawSZT(_value);
        if (unstakeSZTSuccess) {
            bool sellSZTSuccess = buySellContract.sellSZTToken(_value);
            return sellSZTSuccess;
        }
        return false;
    }

}