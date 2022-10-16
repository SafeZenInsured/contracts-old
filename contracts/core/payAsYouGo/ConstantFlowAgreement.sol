// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/Pausable.sol";
import "./../../dependencies/openzeppelin/ReentrancyGuard.sol";
import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../../interfaces/ICFA.sol";
import "./../../../interfaces/IProtocolsRegistry.sol";
import "./../infra/TerminateInsurance.sol";
import "./../../../interfaces/IProtocolsRegistry.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ConstantFlowAgreement is Ownable, ICFA, Pausable, ReentrancyGuard {
    uint256 maxInsuredDays = 1 days; // max. insurance period [in days] // 90 days to be default
    uint256 startWaitingTime = 2 minutes; // insurance active after given waiting period // 4-8 hours to be default
    uint256 minimumInsurancePeriod = 1 minutes; // [in minutes] // 120 minutes to be default
    IERC20 private _tokenDAI;
    IERC20Extended private _sztDAI;
    IProtocolsRegistry private _protocolRegistry;
    TerminateInsurance private _terminateInsurance;

    /// @dev collects user information for each protocol ID
    /// @param insuranceFlowRate: amount to be charged per second [protocol flow rate * amount insured]
    /// @param registrationTime: insurance registration time for each protocol ID
    /// @param startTime: insurance activation time for each protocol ID
    /// @param validTill: insurance validation till date
    /// @param isValid: checks whether user is having active insurance or not
    struct UserInsuranceInfo {
        uint256 insuredAmount;
        uint256 insuranceFlowRate;
        uint256 registrationTime;
        uint256 startTime;
        uint256 validTill;
        bool isValid;
        bool gelatoCallMade;
    }

    struct UserGlobalInsuranceInfo {
        uint256 insuranceStreamRate;
        uint256 validTill;
    }

    // userAddress -> protocolID -> UserInsuranceInfo
    mapping(address => mapping(uint256 => UserInsuranceInfo)) private usersInsuranceInfo;

    /// NOTE: made public for testing purposes
    mapping (address => UserGlobalInsuranceInfo) public usersGlobalInsuranceInfo;

    error ProtocolNotActiveError();
    error NotEvenMinimumInsurancePeriodAmount();
    error ActiveInsuranceExistError();
    error InsuranceCoverNotAvailableError();

    function setDAIAddress(address tokenDAIaddress) external onlyOwner {
        _tokenDAI = IERC20(tokenDAIaddress);
    }

    function setsztDAIAddress(address sztDAIAddress) external onlyOwner {
        _sztDAI = IERC20Extended(sztDAIAddress);
    }

    function setTerminateInsuranceAddress(address payable contractAddress) external onlyOwner {
        _terminateInsurance = TerminateInsurance(contractAddress);
    }

    function setProtocolRegistryAddress(address protocolRegistryAddress) external onlyOwner {
        _protocolRegistry = IProtocolsRegistry(protocolRegistryAddress);
    }

    function updateMinimumInsurancePeriod(uint256 timeInMinutes) external onlyOwner {
        minimumInsurancePeriod = timeInMinutes * 1 minutes;
    }

    function updateStartWaitingTime(uint256 timeInMinutes) external onlyOwner {
        startWaitingTime = timeInMinutes * 1 minutes;
    }

    /// @param insuredAmount: insured amount
    /// @param protocolID: like AAVE which a user want cover against
    function activateInsurance(uint256 insuredAmount, uint256 protocolID) public override nonReentrant {
        if (insuredAmount < 1e18) {
            revert InsuranceCoverNotAvailableError();
        }
        if (
            (!_protocolRegistry.ifEnoughLiquidity(insuredAmount, protocolID))    
        ) {
            revert ProtocolNotActiveError();
        }
        if (usersInsuranceInfo[_msgSender()][protocolID].isValid) {
            revert ActiveInsuranceExistError();
        }
        uint256[] memory activeID = findActiveFlows(_msgSender(), _protocolRegistry.protocolID());
        uint256 userEstimatedBalance = _sztDAI.balanceOf(_msgSender()) - calculateTotalFlowMade(_msgSender(), activeID);
        /// NOTE: StreamFlowRate will be in seconds from now
        uint256 flowRate = (_protocolRegistry.getStreamFlowRate(protocolID) * insuredAmount) / 1e18; /// in seconds
        UserGlobalInsuranceInfo storage userGlobalInsuranceInfo = usersGlobalInsuranceInfo[_msgSender()];
        userGlobalInsuranceInfo.insuranceStreamRate += flowRate;
        // user balance should be enough to run the insurance for atleast minimum insurance time duration
        if ((userGlobalInsuranceInfo.insuranceStreamRate * minimumInsurancePeriod) > userEstimatedBalance) {
            revert NotEvenMinimumInsurancePeriodAmount();
        }
        uint256 validTill = (userEstimatedBalance / userGlobalInsuranceInfo.insuranceStreamRate);
        userGlobalInsuranceInfo.validTill = validTill > maxInsuredDays ? (maxInsuredDays + block.timestamp) : (validTill + block.timestamp);
        for (uint256 i=0; i < activeID.length; i++) {
            uint256 earlierValidTillTime = usersInsuranceInfo[_msgSender()][activeID[i]].validTill;
            usersInsuranceInfo[_msgSender()][activeID[i]].validTill = userGlobalInsuranceInfo.validTill  < earlierValidTillTime ? userGlobalInsuranceInfo.validTill : earlierValidTillTime;
        }
        
        UserInsuranceInfo storage userInsuranceInfo = usersInsuranceInfo[_msgSender()][protocolID];
        userInsuranceInfo.insuredAmount = insuredAmount;
        userInsuranceInfo.insuranceFlowRate = flowRate;
        userInsuranceInfo.registrationTime = block.timestamp;
        userInsuranceInfo.startTime = block.timestamp + startWaitingTime;
        userInsuranceInfo.validTill = userGlobalInsuranceInfo.validTill;
        userInsuranceInfo.isValid = true;
        if (!userInsuranceInfo.gelatoCallMade) {
            userInsuranceInfo.gelatoCallMade = true;
            _terminateInsurance.createGelatoProtocolSpecificTask(_msgSender(), protocolID);
        }
        _protocolRegistry.addCoverageOffered(protocolID, insuredAmount, flowRate);
        
    }

    error InactiveInsuranceError();
    function addInsuranceAmount(uint256 insuredAmount, uint256 protocolID) external override {
        if (!usersInsuranceInfo[_msgSender()][protocolID].isValid) {
            revert InactiveInsuranceError();
        }
        uint256 newInsuredAmount = usersInsuranceInfo[_msgSender()][protocolID].insuredAmount + insuredAmount;
        closeTokenStream(_msgSender(), protocolID);
        activateInsurance(newInsuredAmount, protocolID);
    }

    function minusInsuranceAmount(uint256 insuredAmount, uint256 protocolID) external override {
        if (!usersInsuranceInfo[_msgSender()][protocolID].isValid) {
            revert InactiveInsuranceError();
        }
        uint256 newInsuredAmount = usersInsuranceInfo[_msgSender()][protocolID].insuredAmount - insuredAmount;
        closeTokenStream(_msgSender(), protocolID);
        activateInsurance(newInsuredAmount, protocolID);
    }

    function closeAllStream(address userAddress) public override returns(bool) {
        uint256[] memory activeID = findActiveFlows(_msgSender(), _protocolRegistry.protocolID());
        uint256 expectedAmountToBePaid = calculateTotalFlowMade(userAddress, activeID);
        for (uint256 i=0; i < activeID.length; i++) {
            usersInsuranceInfo[_msgSender()][activeID[i]].isValid = false;
            uint256 flowRate = usersInsuranceInfo[_msgSender()][activeID[i]].insuranceFlowRate;
            uint256 insuredAmount = usersInsuranceInfo[_msgSender()][activeID[i]].insuredAmount;
            _protocolRegistry.removeCoverageOffered(activeID[i], insuredAmount, flowRate);
        }
        usersGlobalInsuranceInfo[_msgSender()].insuranceStreamRate = 0;
        uint256 userBalance = _sztDAI.balanceOf(userAddress); 
        uint256 amountToBeBurned = expectedAmountToBePaid > userBalance ? userBalance : expectedAmountToBePaid;
        bool success = _sztDAI.burnFrom(userAddress, amountToBeBurned);
        return success;
    }

    /// NOTE: few if and else to consider for globalinsuranceinfo like endtime and start time 
    error TransactionFailed();
    error NoStreamRunningError();
    function closeTokenStream(address userAddress, uint256 protocolID) public override nonReentrant returns(bool) {
        UserInsuranceInfo storage userInsuranceInfo = usersInsuranceInfo[userAddress][protocolID];
        if (userInsuranceInfo.isValid) {
            userInsuranceInfo.isValid = false;
            uint256 userBalance = _sztDAI.balanceOf(userAddress);
            uint256 duration = (block.timestamp > userInsuranceInfo.startTime) ? (block.timestamp - userInsuranceInfo.startTime) : 0;
            uint256 expectedAmountToBePaid = (duration * userInsuranceInfo.insuranceFlowRate);
            if (expectedAmountToBePaid == 0) {
                return true;
            } 
            uint256 amountToBeBurned = (expectedAmountToBePaid > userBalance) ? userBalance : expectedAmountToBePaid;
            usersGlobalInsuranceInfo[userAddress].insuranceStreamRate -= userInsuranceInfo.insuranceFlowRate;
            uint256 flowRate = userInsuranceInfo.insuranceFlowRate;
            uint256 insuredAmount = userInsuranceInfo.insuredAmount;
            bool success = _protocolRegistry.removeCoverageOffered(protocolID, insuredAmount, flowRate);
            bool burnSuccess = _sztDAI.burnFrom(userAddress, amountToBeBurned);
            if (success && burnSuccess) {
                return true;
            }
            return false;
        }
        return false;
    }

    error LowUserBalance();
    function transfer(address to, uint256 amount) public override returns(bool) {
        uint256[] memory activeID = findActiveFlows(_msgSender(), _protocolRegistry.protocolID());
        uint256 expectedAmountToBePaid = totalAmountExpectedToBePaid(_msgSender(), activeID);
        uint256 userBalance = _sztDAI.balanceOf(_msgSender()); 
        if ((expectedAmountToBePaid + amount) > userBalance) {
            bool success = _sztDAI.transferFrom(_msgSender(), to, amount);
            return success;
        }
        return false;
    }

    function updateMaxInsuredDays(uint256 timeInDays) external onlyOwner {
        maxInsuredDays = timeInDays * 1 days;
    }

    /// VIEW FUNCTIONS

    function findActiveFlows(address userAddress, uint256 protocolCount) public view override returns(uint256[] memory) {
        uint256 activeProtocolCount = 0;
        for (uint i = 0; i < protocolCount; i++) {
          UserInsuranceInfo memory userInsuranceInfo = usersInsuranceInfo[userAddress][i];
              if (userInsuranceInfo.isValid) {
                activeProtocolCount++;
            }
        }
        
        uint256[] memory activeID = new uint256[](activeProtocolCount);
        uint256 counter = 0;
        for (uint i = 0; i < protocolCount; i++) {
          UserInsuranceInfo storage userInsuranceInfo = usersInsuranceInfo[userAddress][i];
              if (userInsuranceInfo.isValid) {
                activeID[counter] = i;
                counter += 1;
            }
        }
      return activeID;
    }

    /// internal call for transferFrom [not for external or public calls]
    function totalAmountExpectedToBePaid(address userAddress, uint256[] memory activeID) internal view returns(uint256) {
        uint256 balanceToBePaid;
        for (uint256 i=0; i< activeID.length; i++){
            UserInsuranceInfo storage userActiveInsuranceInfo = usersInsuranceInfo[userAddress][activeID[i]];
            uint256 duration = (userActiveInsuranceInfo.validTill - userActiveInsuranceInfo.startTime);
            balanceToBePaid += (userActiveInsuranceInfo.insuranceFlowRate * duration);
        }
        return balanceToBePaid;
    }

    function calculateTotalFlowMade(address userAddress, uint256[] memory activeID) internal view returns(uint256) {
        uint256 balanceToBePaid;
        for (uint256 i=0; i< activeID.length; i++){
            UserInsuranceInfo storage userActiveInsuranceInfo = usersInsuranceInfo[userAddress][activeID[i]];
            uint256 duration = block.timestamp > userActiveInsuranceInfo.startTime ? block.timestamp - userActiveInsuranceInfo.startTime : 0;
            balanceToBePaid += (userActiveInsuranceInfo.insuranceFlowRate * duration);
        }
        return balanceToBePaid;
    }

    function calculateTotalFlowMade(address userAddress) public view override returns(uint256) {
        uint256 balanceToBePaid;
        uint256[] memory activeID = findActiveFlows(userAddress, _protocolRegistry.protocolID());
        for (uint256 i=0; i< activeID.length; i++){
            UserInsuranceInfo storage userActiveInsuranceInfo = usersInsuranceInfo[userAddress][activeID[i]];
            uint256 duration = (userActiveInsuranceInfo.validTill - userActiveInsuranceInfo.startTime);
            balanceToBePaid += (userActiveInsuranceInfo.insuranceFlowRate * duration);
        }
        return balanceToBePaid;
    } 

    function getUserInsuranceValidTillInfo(address userAddress, uint256 protocolID) external view override returns(uint256) {
        return usersInsuranceInfo[userAddress][protocolID].validTill;
    }

    function getUserInsuranceStatus(address userAddress, uint256 protocolID) external view override returns(bool) {
        return usersInsuranceInfo[userAddress][protocolID].isValid;
    }

    function getUserInsuranceInfo(
        address userAddress, 
        uint256 protocolID
        ) external view returns(uint256, uint256, uint256, uint256, uint256, bool, bool) {
        UserInsuranceInfo memory userInsuranceInfo = usersInsuranceInfo[userAddress][protocolID];
        return (
            userInsuranceInfo.insuredAmount, 
            userInsuranceInfo.insuranceFlowRate,
            userInsuranceInfo.registrationTime,
            userInsuranceInfo.startTime,
            userInsuranceInfo.validTill,
            userInsuranceInfo.isValid,
            userInsuranceInfo.gelatoCallMade);
    }

    function getGlobalUserInsuranceInfo(address _userAddress) external view returns (uint256, uint256) {
        UserGlobalInsuranceInfo memory userGlobalInsuranceInfo = usersGlobalInsuranceInfo[_userAddress];
        return (userGlobalInsuranceInfo.insuranceStreamRate, userGlobalInsuranceInfo.validTill);
    }
}