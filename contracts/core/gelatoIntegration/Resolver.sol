// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/IOps.sol";
import "./../../../interfaces/ICFA.sol";
import "./../../dependencies/gelato/OpsReady.sol";


contract Resolver is Ownable{
    ICFA public immutable _CFA;
// 
    // constructor(address payable _ops, address _CFAAddress) OpsReady(_ops) {
    //     _CFA = ICFA(_CFAAddress);
    // }

    constructor(address _CFAAddress) {
        _CFA = ICFA(_CFAAddress);
    }

    // function startTask() external {
    //     IOps.createTask(
    //         address(_CFA), 
    //         _CFA.closeTokenStream.selector,
    //         address(this),
    //         abi.encodeWithSelector(this.checker.selector)
    //     );
    // }

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