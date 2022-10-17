// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface ICoveragePool {

    event UpdatedProtocolRegistryAddress(address indexed contractAddress);

    event UpdatedWaitingPeriod(uint256 indexed timeInDays);

    event UnderwritePool(address indexed userAddress, uint256 protocolID, uint256 indexed value);

    event PoolWithdrawn(address indexed userAddress, uint256 protocolID, uint256 indexed value);

    function totalTokensStaked() external view returns(uint256);

    function underwrite(uint256 value, uint256 protocolID) external returns(bool);

    function activateWithdrawalTimer(uint256 value, uint256 protocolID) external returns(bool);

    function withdraw(uint256 value, uint256 protocolID) external returns(bool);

    function calculateUserBalance(uint256 protocolID) external view returns(uint256);

    function getUnderwriteSZTBalance() external view returns(uint256);

    function getUnderwriterActiveVersionID(uint256 protocolID) external view returns(uint256[] memory);
}