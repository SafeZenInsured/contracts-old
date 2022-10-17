// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface ISZTStaking {

    event UpdatedWithdrawTimer(uint256 indexed timeInMinutes);

    event UpdatedMinStakingAmount(uint256 indexed value);

    event StakedSZT(address indexed userAddress, uint256 value);

    event UnstakedSZT(address indexed userAddress, uint256 value);

    function stakeSZT(uint256 _value) external returns(bool);

    function activateWithdrawalTimer(uint256 _value) external returns(bool);

    function withdrawSZT(uint256 _value) external returns(bool);

    function totalTokensStaked() external view returns(uint256);

    function getUserStakedSZTBalance() external view returns(uint256);

}