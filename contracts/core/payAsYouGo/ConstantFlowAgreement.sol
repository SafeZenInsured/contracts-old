// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Context.sol";
import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ConstantFlowAgreement is Context{
    uint256 public _protocolCount;
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
    mapping(address => mapping(uint256 => StreamTransaction)) public userStreamTransactionInfo;

    struct UserStreamInfo {
        uint256 userStreamRate;
        uint256 expectedStreamEndTime;
    }
    mapping (address => UserStreamInfo) public userStreamDetails;

    uint256 minimumStreamPeriod = 60; // one hour
    uint256 maxInsuredDays = 90 days;

    function getUserExpectedRunOutTimeInfo(address _userAddress, uint256 _protocolID) external view returns(uint256) {
        return userStreamTransactionInfo[_userAddress][_protocolID].expectedRunOutTime;
    }

    // protocolID like AAVE which a user want cover against
    error WrongProtocolIDEntered();
    error NotEvenOneHourStreamAmount();
    function startFlow(uint256 _streamFlowRate, uint256 protocolID) external {
        if (protocolID > _protocolCount) {
            revert WrongProtocolIDEntered();
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
        uint256[] memory activeID = findActiveFlows(_protocolCount);
        for (uint256 i=0; i < activeID.length; i++){
            StreamTransaction memory activeStreamInfo = userStreamTransactionInfo[_msgSender()][activeID[i]];
            activeStreamInfo.expectedRunOutTime = streamInfo.expectedStreamEndTime;
            // then revoke gelato earlier call and add new gelato call
        }
        StreamTransaction storage newStreamInfo = userStreamTransactionInfo[_msgSender()][protocolID];
        newStreamInfo.flowRate = _streamFlowRate;
        newStreamInfo.flowStartTime = block.timestamp;
        newStreamInfo.expectedRunOutTime = streamInfo.expectedStreamEndTime;
        newStreamInfo.isRunning = true;
    }

    function mintToken(uint256 _amount) external returns(bool) {
        DAI.transferFrom(_msgSender(), address(this), _amount);
        bool success = sztDAI.mint(_msgSender(), _amount);
        return success;
    }

    function updateProtocolCount(uint value) public {
        _protocolCount = value;
    }

    function findActiveFlows(uint256 protocolCount) public view returns(uint256[] memory){
        uint256 activeProtocolCount;
        for (uint i = 0; i < protocolCount; i++) {
          StreamTransaction memory newStreamInfo = userStreamTransactionInfo[_msgSender()][i];
              if (newStreamInfo.isRunning) {
                activeProtocolCount++;
            }
        }
        
        uint256[] memory activeID = new uint256[](activeProtocolCount);
        uint256 counter = 0;
        for (uint i = 0; i < protocolCount; i++) {
          StreamTransaction storage newStreamInfo = userStreamTransactionInfo[_msgSender()][i];
              if (newStreamInfo.isRunning) {
                activeID[counter] = i;
                counter += 1;
            }
        }
      return activeID;
    }

    function calculateTotalFlowMade() public view returns(uint256) {
        uint256 balanceToBePaid;
        uint256[] memory activeID = findActiveFlows(_protocolCount);
        for (uint256 i=0; i< activeID.length; i++){
            StreamTransaction storage activeStreamInfo = userStreamTransactionInfo[_msgSender()][activeID[i]];
            uint256 duration = (block.timestamp - activeStreamInfo.flowStartTime);
            balanceToBePaid += (activeStreamInfo.flowRate * duration);
        }
        return balanceToBePaid;
    } 

    error TransactionFailed();
    error NoStreamRunningError();
    function closeTokenStream(uint256 protocolID) public {
        StreamTransaction storage streamInfo = userStreamTransactionInfo[_msgSender()][protocolID];
        if (streamInfo.isRunning) {
            streamInfo.isRunning = false;
            uint256 duration = (block.timestamp - streamInfo.flowStartTime);
            uint256 amountToBePaid = (duration * streamInfo.flowRate);
            bool success = sztDAI.burnFrom(_msgSender(), amountToBePaid);
            UserStreamInfo storage userStream = userStreamDetails[_msgSender()];
            userStream.userStreamRate -= streamInfo.flowRate;
            if (!success){
                revert TransactionFailed();
            }
        }
        else {
            revert NoStreamRunningError();
        }
    }

    function updateEndTime(address from) internal {
        uint256[] memory activeID = findActiveFlows(_protocolCount);
        uint256 expectedRunOutTime = (sztDAI.balanceOf(from) / userStreamDetails[from].userStreamRate);
        for (uint256 i=0; i< activeID.length; i++){
            userStreamTransactionInfo[from][activeID[i]].expectedRunOutTime = expectedRunOutTime; 
            
        }
    }

    error LowUserBalance();
    function transferTokenSZT(address from, address to, uint256 amount) public returns(bool) {
        uint256 amountToBePaid = calculateTotalFlowMade();
        uint256 userBalance = sztDAI.balanceOf(from); 
        if ((amountToBePaid + amount) > userBalance) {
            bool success = sztDAI.transferFrom(from, to, amount);
            updateEndTime(from);
            return success;
        }
        return false;
    }

}