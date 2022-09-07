// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// function startTokenStream(address userAccount, uint256 streamFlowRate) public {
//         uint256 userBalance = balanceOf(userAccount);
        
//         UserStreamInfo storage userStream = userStreamDetails[userAccount];
//         // if (userLastStreamTxnID[userAccount] == 0){            
//         //     userStream.lastUserStreamTransactionID = 0;
//         // } else{
//         //     userStream.lastUserStreamTransactionID = userLastStreamTxnID[userAccount];
//         // }
//         userStream.userStreamRate += streamFlowRate;
//         userStream.expectedStreamEndTime = (userBalance / userStream.userStreamRate);
//         // userStream.currentStreamTransactionID = userStream.lastUserStreamTransactionID + 1;
//         // uint256 txnID = userStream.lastUserStreamTransactionID;
//         // if (txnID > 0) {
//         //     for(uint i = 0; i <= txnID; i++ ) {
//         //         StreamTransaction storage streamInfoIn = userStreamTransactionInfo[i];
//         //         if (streamInfoIn.isRunning) {
//         //             streamInfoIn.expectedRunOutTime = userStream.expectedStreamEndTime;
//         //         }
//         //     }
//         // } 
        
//         // StreamTransaction storage streamInfo = userStreamTransactionInfo[userStream.currentStreamTransactionID];
//         // streamInfo.flowRate = streamFlowRate;
//         // streamInfo.flowStartTime = block.timestamp;
//         // streamInfo.expectedRunOutTime = userStream.expectedStreamEndTime;
//         // streamInfo.isRunning = true;
//         // streamInfo.lastUserStreamTransactionID = userLastStreamTxnID[userAccount];
//         // userLastStreamTxnID[userAccount] = userStream.currentStreamTransactionID;
//     }

// constructor(address payable _ops) OpsReady(_ops) {}

    // function setGelatoAddress(address payable _ops) public {

    // }

    // mapping (address => uint256) userLastStreamTxnID;

    // struct StreamTransaction {
    //     uint256 flowRate;
    //     uint256 flowStartTime;
    //     uint256 expectedRunOutTime;
    //     bool isRunning;
    //     // uint256 lastUserStreamTransactionID;
    // }
    // mapping(uint256 => StreamTransaction) userStreamTransactionInfo;

    // struct UserStreamInfo {
    //     // uint256 lastUserStreamTransactionID;
    //     uint256 userStreamRate;
    //     uint256 expectedStreamEndTime;
    //     // uint256 currentStreamTransactionID;
    // }
    // mapping (address => UserStreamInfo) userStreamDetails;

    // error NotEvenOneHourStreamAmount();
    // // protocolID like AAVE which a user want cover against
    // function startFlow(uint256 streamFlowRate, uint256 protocolID) public {
    //     uint256 userBalance = balanceOf(_msgSender());
    //     UserStreamInfo storage streamInfo = userStreamDetails[_msgSender()];
    //     streamInfo.userStreamRate += streamFlowRate;
    //     if (streamInfo.userStreamRate * 60 < userBalance) {
    //         revert NotEvenOneHourStreamAmount();
    //     }
    //     streamInfo.expectedStreamEndTime = (userBalance / streamInfo.userStreamRate);
    //     uint256[] memory activeID = findActiveFlows(20);
    //     for (uint256 i=0; i< activeID.length; i++){
    //         StreamTransaction memory activeStreamInfo = userStreamTransactionInfo[activeID[i]];
    //         activeStreamInfo.expectedRunOutTime = streamInfo.expectedStreamEndTime;
    //         // then revoke gelato earlier call and add new gelato call
    //     }
    //     StreamTransaction storage newStreamInfo = userStreamTransactionInfo[protocolID];
    //     newStreamInfo.flowRate = streamFlowRate;
    //     newStreamInfo.flowStartTime = block.timestamp;
    //     newStreamInfo.expectedRunOutTime = streamInfo.expectedStreamEndTime;
    //     newStreamInfo.isRunning = true;
    // }

    // uint256 _protocolCount;
    // function updateProtocolCount(uint value) public {
    //     _protocolCount = value;
    // }
    
    // function findActiveFlows(uint256 protocolCount) public view returns (uint256[] memory){
    //   uint256[] memory activeID = new uint256[](protocolCount);
    //   uint256 counter = 0;
    //   for (uint i = 0; i < protocolCount; i++) {
    //       StreamTransaction storage newStreamInfo = userStreamTransactionInfo[i];
    //       if (newStreamInfo.isRunning) {
    //         activeID[counter] = i;
    //         counter += 1;
    //       }
    //   }
    //   return activeID;
    // }

    // function calculateTotalFlowMade() public view returns(uint256) {
    //     uint256 balanceToBePaid;
    //     uint256[] memory activeID = findActiveFlows(20);
    //     for (uint256 i=0; i< activeID.length; i++){
    //         StreamTransaction storage activeStreamInfo = userStreamTransactionInfo[activeID[i]];
    //         uint256 duration = (block.timestamp - activeStreamInfo.flowStartTime);
    //         balanceToBePaid += (activeStreamInfo.flowRate * duration);
    //     }
    //     return balanceToBePaid;
    // }  

    // function closeTokenStream(uint256 transactionID) public {
    //     StreamTransaction storage streamInfo = userStreamTransactionInfo[transactionID];
    //     streamInfo.isRunning = false;
    //     uint256 duration = (block.timestamp - streamInfo.flowStartTime);
    //     uint256 amountToBePaid = (duration * streamInfo.flowRate);
    //     _burn(_msgSender(), amountToBePaid);
    //     UserStreamInfo storage userStream = userStreamDetails[_msgSender()];
    //     userStream.userStreamRate -= streamInfo.flowRate;
    // }



// pragma solidity ^0.8.0;

// import "./SZTERC20.sol";

//     /*
    
//     */

// contract TestGasFee {
//     address SZT;
//     SZTERC20 SZTToken;

//     function setSZTaddress(address _SZTToken) public {
//         SZT = _SZTToken;
//         SZTToken = SZTERC20(_SZTToken);
//     }

//     error TransactionFailed();
//     function callSZT(address to) public {
//         (bool success, ) = SZT.call(abi.encodeWithSignature("transfer(address,uint256)", to, 1e22));
//         if (!success){
//             revert TransactionFailed();
//         }
//     }

//     function callSZT2(address to) public {
//         (bool success, ) = SZT.call(abi.encodeWithSignature("transfer(address,uint256)", to, 1e70));
//         if (!success){
//             revert TransactionFailed();
//         }
//     }

//     function transferSZT(address to) public {
//         bool success = SZTToken.transfer(to, 1e22);
//         if (!success){
//             revert TransactionFailed();
//         }
//     }

//     function transferSZT2(address to) public {
//         SZTToken.transfer(to, 1e70);
//     }
// }