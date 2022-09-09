// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/IOps.sol";

interface ICFA {

    function getUserExpectedRunOutTimeInfo(address _userAddress, uint256 _protocolID) external view returns(uint256);

    function closeTokenStream(uint256 protocolID) external;
}

contract Resolver is Ownable{
    ICFA public immutable _CFA;

    constructor(address _CFAAddress) {
        _CFA = ICFA(_CFAAddress);
    }

    error TransactionFailedError();
    function checker(address _userAddress, uint256 _protocolID) external view returns(bool canExec, bytes memory execPayload) {
        if (_CFA.getUserExpectedRunOutTimeInfo(_userAddress, _protocolID) > block.timestamp) {
            revert TransactionFailedError();
        }
        execPayload = abi.encodeWithSelector(ICFA.closeTokenStream.selector, _protocolID);
        canExec = true;

        return (canExec, execPayload);
    }
}