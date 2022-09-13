// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../../interfaces/ICFA.sol";
import "./ProtocolsRegistry.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ConstantFlowAgreement is Ownable, ICFA{
    ProtocolRegistry private protocolInfo;
    IERC20 private DAI;
    IERC20Extended private sztDAI;

    constructor(address _DAIAddress, address _sztDAIAddress) {
        DAI = IERC20(_DAIAddress);
        sztDAI = IERC20Extended(_sztDAIAddress);
    }

    /// @dev collects user information for each protocol ID
    /// @param flowRate: amount to be charged per second
    /// @param flowStartTime: insurance activation time for each protocol ID
    /// @param isRunning: checks whether user is having active insurance or not
    struct StreamTransaction {
        uint256 flowRate;
        uint256 flowStartTime;
        uint256 expectedRunOutTime;
        bool isRunning;
    }
    
    // userAddress -> protocolID -> StreamTransactionInfo
    mapping(address => mapping(uint256 => StreamTransaction)) private StreamTransactions;

    struct UserStreamInfo {
        uint256 userStreamRate;
        uint256 expectedStreamEndTime;
    }
    mapping (address => UserStreamInfo) private userStreamDetails;

    uint256 minimumStreamPeriod = 60; // one hour
    uint256 maxInsuredDays = 90 days; // max. insurance days

    
    
    error ProtocolNotActiveError();
    error NotEvenOneHourStreamAmount();
    /// @param _protocolID: like AAVE which a user want cover against
    function startFlow(uint256 _streamFlowRate, uint256 _protocolID) external override {
        if (
            (!protocolInfo.getIsProtocolActive(_protocolID))) {
            revert ProtocolNotActiveError();
        } 
        uint256 userBalance = sztDAI.balanceOf(_msgSender());
        UserStreamInfo storage streamInfo = userStreamDetails[_msgSender()];
        streamInfo.userStreamRate += _streamFlowRate;
        // user balance should be enough to run the insurance for atleast an hour
        if ((streamInfo.userStreamRate * minimumStreamPeriod) > userBalance) {
            revert NotEvenOneHourStreamAmount();
        }
        // adding 60 minutes buffer if the user do subscribe for less than 90 days
        streamInfo.expectedStreamEndTime = (userBalance / streamInfo.userStreamRate) > maxInsuredDays ? maxInsuredDays : ((userBalance / streamInfo.userStreamRate) - 60);
        
        uint256[] memory activeID = findActiveFlows(_msgSender(), protocolInfo.protocolCount());
        for (uint256 i=0; i < activeID.length; i++) {
            StreamTransaction memory activeStreamInfo = StreamTransactions[_msgSender()][activeID[i]];
            activeStreamInfo.expectedRunOutTime = streamInfo.expectedStreamEndTime;
            // then revoke gelato earlier call and add new gelato call
        }
        StreamTransaction storage newStreamInfo = StreamTransactions[_msgSender()][_protocolID];
        newStreamInfo.flowRate = _streamFlowRate;
        newStreamInfo.flowStartTime = block.timestamp;
        newStreamInfo.expectedRunOutTime = streamInfo.expectedStreamEndTime;
        newStreamInfo.isRunning = true;
    }

    error TransactionFailed();
    error NoStreamRunningError();
    function closeTokenStream(address _userAddress, uint256 protocolID) public override {
        StreamTransaction storage streamInfo = StreamTransactions[_userAddress][protocolID];
        if (streamInfo.isRunning) {
            streamInfo.isRunning = false;
            uint256 duration = (block.timestamp - streamInfo.flowStartTime);
            uint256 amountToBePaid = (duration * streamInfo.flowRate);
            bool success = sztDAI.burnFrom(_userAddress, amountToBePaid);
            UserStreamInfo storage userStream = userStreamDetails[_userAddress];
            userStream.userStreamRate -= streamInfo.flowRate;
            if (!success){
                revert TransactionFailed();
            }
        }
        else {
            revert NoStreamRunningError();
        }
    }

    // TODO: end previous gelato calls and add new gelato call for this    
    function updateEndTime(address from) internal {
        uint256[] memory activeID = findActiveFlows(from, protocolInfo.protocolCount());
        uint256 expectedRunOutTime = (sztDAI.balanceOf(from) / userStreamDetails[from].userStreamRate);
        for (uint256 i=0; i< activeID.length; i++){
            StreamTransactions[from][activeID[i]].expectedRunOutTime = expectedRunOutTime; 
            // TODO: end previous gelato calls and add new gelato call for this    
        }
    }

    error LowUserBalance();
    function transferFrom(address from, address to, uint256 amount) public override returns(bool) {
        uint256 amountToBePaid = calculateTotalFlowMade(from);
        uint256 userBalance = sztDAI.balanceOf(from); 
        if ((amountToBePaid + amount) > userBalance) {
            bool success = sztDAI.transferFrom(from, to, amount);
            updateEndTime(from);
            return success;
        }
        return false;
    }

    function updateMaxInsuredDays(uint256 _days) external onlyOwner {
        maxInsuredDays = _days * 1 days;
    }

    /// VIEW FUNCTIONS

    function findActiveFlows(address _userAddress, uint256 protocolCount) public view override returns(uint256[] memory) {
        uint256 activeProtocolCount;
        for (uint i = 0; i < protocolCount; i++) {
          StreamTransaction memory newStreamInfo = StreamTransactions[_userAddress][i];
              if (newStreamInfo.isRunning) {
                activeProtocolCount++;
            }
        }
        
        uint256[] memory activeID = new uint256[](activeProtocolCount);
        uint256 counter = 0;
        for (uint i = 0; i < protocolCount; i++) {
          StreamTransaction storage newStreamInfo = StreamTransactions[_userAddress][i];
              if (newStreamInfo.isRunning) {
                activeID[counter] = i;
                counter += 1;
            }
        }
      return activeID;
    }

    function calculateTotalFlowMade(address _userAddress) public view override returns(uint256) {
        uint256 balanceToBePaid;
        uint256[] memory activeID = findActiveFlows(_userAddress, protocolInfo.protocolCount());
        for (uint256 i=0; i< activeID.length; i++){
            StreamTransaction storage activeStreamInfo = StreamTransactions[_userAddress][activeID[i]];
            uint256 duration = (block.timestamp - activeStreamInfo.flowStartTime);
            balanceToBePaid += (activeStreamInfo.flowRate * duration);
        }
        return balanceToBePaid;
    } 

    function getUserExpectedRunOutTimeInfo(address _userAddress, uint256 _protocolID) external view override returns(uint256) {
        return StreamTransactions[_userAddress][_protocolID].expectedRunOutTime;
    }
}