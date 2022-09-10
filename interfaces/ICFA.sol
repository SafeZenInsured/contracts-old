// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


interface ICFA {

    function startFlow(uint256 _streamFlowRate, uint256 protocolID) external;

    function mintToken(uint256 _amount) external returns(bool);

    function findActiveFlows(uint256 protocolCount) external view returns(uint256[] memory);

    function calculateTotalFlowMade() external view returns(uint256);

    function closeTokenStream(uint256 protocolID) external;

    function transferFrom(address from, address to, uint256 amount) external returns(bool);

    function getUserExpectedRunOutTimeInfo(address _userAddress, uint256 _protocolID) external view returns(uint256);

}