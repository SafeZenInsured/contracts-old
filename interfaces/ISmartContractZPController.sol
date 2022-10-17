// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface ISmartContractZPController {

    function protocolID() external view returns(uint256);

    function latestVersion() external view returns(uint256);
}