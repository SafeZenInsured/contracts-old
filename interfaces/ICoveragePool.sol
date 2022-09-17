// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICoveragePool {

    function totalTokensStaked() external view returns(uint256);

    function underwrite(uint256 _value, uint256 _protocolID) external returns(bool);

    function activateWithdrawalTimer(uint256 _value, uint256 _protocolID) external returns(bool);

    function withdraw(uint256 _value, uint256 _protocolID) external returns(bool);

    function calculateUserBalance(uint256 _protocolID) external view returns(uint256);
}