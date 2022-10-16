// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/Pausable.sol";
import "./../../../interfaces/IOps.sol";
import "./../../../interfaces/ICFA.sol";
import "./../../dependencies/gelato/OpsReady.sol";


contract TerminateInsurance is OpsReady, Ownable, Pausable {
    using SafeERC20 for IERC20;

    ICFA private _contractCFA;

    mapping(address => mapping(uint256 => bytes32)) private _taskID;

    constructor(address _ops) OpsReady(_ops) {
    }

    modifier onlyCFA() {
        require(_msgSender() == address(_contractCFA));
        _;
    }

    error TransactionFailedError();
    error StopCFAFlowCallFailedError();
    error CFATokenStreamTransactionFailed();

    receive() external payable {}

    function recoverToken(address token, bool native) external onlyOwner {
        if (native) {
            (bool success, ) = owner().call{value: address(this).balance}("");
            require(success, "Native transfer failed");
        } else {
            uint256 tokenBal = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(owner(), tokenBal);
        }
    }

    function setCFAAddress(address constantFlowContractAddress) external onlyOwner {
        _contractCFA = ICFA(constantFlowContractAddress);
    }

    function createGelatoProtocolSpecificTask(
        address userAddress, 
        uint256 protocolID
    ) external payable onlyCFA {
        // bytes4 _execSelector = bytes4(
        //     abi.encodeWithSignature("gelatoSpecificProtocolStopFlow(address, uint256)", _userAddress, _protocolID)
        // );
        bytes memory resolverData = abi.encodeWithSignature("gelatoResolver(address, uint256)", userAddress, protocolID);
        _taskID[userAddress][protocolID] = IOps(ops).createTaskNoPrepayment(
            address(this), 
            // _execSelector,
            this.gelatoSpecificProtocolStopFlow.selector,
            address(this),
            resolverData,
            ETH
        );
    }

    /// @dev to cancel the gelato task
    function cancelProtocolSpecificGelatoTask(address userAddress, uint256 protocolID) external onlyCFA {
        bytes32 taskID = _taskID[userAddress][protocolID];
        IOps(ops).cancelTask(taskID);
    }

    function gelatoSpecificProtocolStopFlow(
        address userAddress, 
        uint256 protocolID
    ) external onlyOps whenNotPaused payable returns(bool) {
        bool success = stopSpecificProtocolCFAFlow(userAddress, protocolID);
        if (!success) {
            revert StopCFAFlowCallFailedError();
        }
        (uint256 feeAmount, ) = IOps(ops).getFeeDetails();
        _payTxFee(feeAmount);
        return true;
    }

    function stopSpecificProtocolCFAFlow(
        address userAddress, 
        uint256 protocolID
    ) internal returns(bool) {
        if (
            (_contractCFA.getUserInsuranceValidTillInfo(userAddress, protocolID) > block.timestamp) ||
            (!_contractCFA.getUserInsuranceStatus(userAddress, protocolID))
        ) {
            revert TransactionFailedError();
        }
        bool success = _contractCFA.closeTokenStream(userAddress, protocolID);
        if (!success) {
            revert CFATokenStreamTransactionFailed();
        }
        return true;
    }

    function gelatoResolver(
        address userAddress, 
        uint256 protocolID
    ) external view returns (bool, bytes memory) {
        bool canExec = (_contractCFA.getUserInsuranceValidTillInfo(userAddress, protocolID) <= block.timestamp) &&
            (_contractCFA.getUserInsuranceStatus(userAddress, protocolID));
        bytes memory execPayload = abi.encodeWithSignature("gelatoDistribute()");
        return (canExec, execPayload);
    }
}