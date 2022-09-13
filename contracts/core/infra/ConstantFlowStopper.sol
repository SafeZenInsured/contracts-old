// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/Pausable.sol";
import "./../../../interfaces/IOps.sol";
import "./../../../interfaces/ICFA.sol";
import "./../../dependencies/gelato/OpsReady.sol";


contract Resolver is OpsReady, Ownable, Pausable {
    using SafeERC20 for IERC20;

    ICFA public immutable _CFA;
    uint256 public maxGasPriceInGwei; 
    uint256 public counter;

    mapping(uint256 => bytes32) public taskID;

    constructor(address _ops, address _CFAAddress) OpsReady(_ops) {
        _CFA = ICFA(_CFAAddress);
        maxGasPriceInGwei = 200; 
    }

    modifier onlyCFA() {
        require(_msgSender() == address(_CFA));
        _;
    }

    function gelatoStopFlow(address _userAddress, uint256 _protocolID) external onlyOps whenNotPaused {
        require(tx.gasprice < maxGasPriceInGwei * 1 gwei, "Gas price too high");
        stopCFAFlow(_userAddress, _protocolID);
        (uint256 feeAmount, ) = IOps(ops).getFeeDetails();
        _payTxFee(feeAmount);
    }

    error TransactionFailedError();
    function stopCFAFlow(address _userAddress, uint256 _protocolID) internal {
        if (_CFA.getUserExpectedRunOutTimeInfo(_userAddress, _protocolID) > block.timestamp) {
            revert TransactionFailedError();
        }
        _CFA.closeTokenStream(_userAddress, _protocolID);
    }

    function setMaxGasPriceInGwei(uint256 _maxGasPriceInGwei) external onlyOwner {
        maxGasPriceInGwei = _maxGasPriceInGwei;
    }


    function createGelatoTask() external onlyCFA {
        counter ++;
        bytes4 _execSelector = bytes4(
            abi.encodeWithSignature("gelatoStopFlow()")
        );
        bytes memory resolverData = abi.encodeWithSignature("gelatoResolver()");
        taskID[counter] = IOps(ops).createTaskNoPrepayment(
            address(this), 
            _execSelector,
            address(this),
            resolverData,
            ETH
        );
    }

    /// @dev to cancel the gelato task
    function cancelGelatoTask(bytes32 _taskID) external onlyOwner {
        IOps(ops).cancelTask(_taskID);
    }


    function gelatoResolver()
        external
        pure
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = true;
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