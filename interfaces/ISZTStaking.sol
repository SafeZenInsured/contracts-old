// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISZTStaking {

    function stakeSZT(uint256 _value) external returns(bool);

    function activateWithdrawalTimer(uint256 _value) external returns(bool);

    function withdrawSZT(uint256 _value) external returns(bool);

    function buyAndStakeSZT(uint256 _value) external returns(bool);

    function totalTokensStaked() external view returns(uint256);

    function getUserBalance(address userAddress) external view returns(uint256);

}