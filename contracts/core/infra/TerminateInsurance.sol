// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/Pausable.sol";
import "./../../../interfaces/IOps.sol";
import "./../../../interfaces/ICFA.sol";
import "./../../dependencies/gelato/OpsReady.sol";


contract TerminateInsurance is OpsReady, Ownable, Pausable {
    using SafeERC20 for IERC20;

    ICFA public _CFA;
    uint256 public counter;

    mapping(address => mapping(uint256 => bytes32)) public taskID;

    constructor(address _ops) OpsReady(_ops) {
    }

    function setCFAAddress(address _CFAAddress) external onlyOwner {
        _CFA = ICFA(_CFAAddress);
    }

    modifier onlyCFA() {
        require(_msgSender() == address(_CFA));
        _;
    }

    function gelatoSpecificProtocolStopFlow(address _userAddress, uint256 _protocolID) external onlyOps whenNotPaused payable {
        stopSpecificProtocolCFAFlow(_userAddress, _protocolID);
        (uint256 feeAmount, ) = IOps(ops).getFeeDetails();
        _payTxFee(feeAmount);
    }

    error TransactionFailedError();
    function stopSpecificProtocolCFAFlow(address _userAddress, uint256 _protocolID) internal {
        if (
            (_CFA.getUserInsuranceValidTillInfo(_userAddress, _protocolID) > block.timestamp) ||
            (!_CFA.getUserInsuranceStatus(_userAddress, _protocolID))
        ) {
            revert TransactionFailedError();
        }
        _CFA.closeTokenStream(_userAddress, _protocolID);
    }

    function createGelatoProtocolSpecificTask(address _userAddress, uint256 _protocolID) external payable onlyCFA {
        // bytes4 _execSelector = bytes4(
        //     abi.encodeWithSignature("gelatoSpecificProtocolStopFlow(address, uint256)", _userAddress, _protocolID)
        // );
        bytes memory resolverData = abi.encodeWithSignature("gelatoResolver(address, uint256)", _userAddress, _protocolID);
        taskID[_userAddress][_protocolID] = IOps(ops).createTaskNoPrepayment(
            address(this), 
            // _execSelector,
            this.gelatoSpecificProtocolStopFlow.selector,
            address(this),
            resolverData,
            ETH
        );
    }

    /// @dev to cancel the gelato task
    function cancelProtocolSpecificGelatoTask(address _userAddress, uint256 _protocolID) external onlyCFA {
        bytes32 _taskID = taskID[_userAddress][_protocolID];
        IOps(ops).cancelTask(_taskID);
    }

    function gelatoResolver(address _userAddress, uint256 _protocolID)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (_CFA.getUserInsuranceValidTillInfo(_userAddress, _protocolID) <= block.timestamp) &&
            (_CFA.getUserInsuranceStatus(_userAddress, _protocolID));
        execPayload = abi.encodeWithSignature("gelatoDistribute()");
    }

    //Recovery
    function recoverToken(address token, bool native) external onlyOwner {
        if (native) {
            (bool success, ) = owner().call{value: address(this).balance}("");
            require(success, "Native transfer failed");
        } else {
            uint256 tokenBal = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(owner(), tokenBal);
        }
    }

    receive() external payable {}
}