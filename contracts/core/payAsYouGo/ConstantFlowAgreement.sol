// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/Pausable.sol";
import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../../interfaces/ICFA.sol";
import "./../../../interfaces/IProtocolsRegistry.sol";
import "./../infra/TerminateInsurance.sol";
import "./../../../interfaces/IProtocolsRegistry.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ConstantFlowAgreement is Ownable, ICFA, Pausable {
    IProtocolsRegistry private protocolRegistry;
    IERC20 private DAI;
    IERC20Extended private sztDAI;
    TerminateInsurance private terminateInsurance;

    function setDAIAddress(address _DAIaddress) external onlyOwner {
        DAI = IERC20(_DAIaddress);
    }

    function setsztDAIAddress(address _sztDAIAddress) external onlyOwner {
        sztDAI = IERC20Extended(_sztDAIAddress);
    }

    function updateTerminateInsuranceAddress(address payable _contractAddress) external onlyOwner {
        terminateInsurance = TerminateInsurance(_contractAddress);
    }

    function updateProtocolRegistryAddress(address _protocolRegistryAddress) external onlyOwner {
        protocolRegistry = IProtocolsRegistry(_protocolRegistryAddress);
    }

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
    
    // userAddress -> protocolID -> UserInsuranceInfo
    mapping(address => mapping(uint256 => UserInsuranceInfo)) private usersInsuranceInfo;

    function getUserInsuranceInfo(
        address _userAddress, 
        uint256 _protocolID
        ) external view returns(uint256, uint256, uint256, uint256, uint256, bool, bool) {
        UserInsuranceInfo memory userInsuranceInfo = usersInsuranceInfo[_userAddress][_protocolID];
        return (
            userInsuranceInfo.insuredAmount, 
            userInsuranceInfo.insuranceFlowRate,
            userInsuranceInfo.registrationTime,
            userInsuranceInfo.startTime,
            userInsuranceInfo.validTill,
            userInsuranceInfo.isValid,
            userInsuranceInfo.gelatoCallMade);
    }

    struct UserGlobalInsuranceInfo {
        uint256 insuranceStreamRate;
        uint256 validTill;
    }
    /// NOTE: made public for testing purposes
    mapping (address => UserGlobalInsuranceInfo) public usersGlobalInsuranceInfo;

    function getGlobalUserInsuranceInfo(address _userAddress) external view returns (uint256, uint256) {
        UserGlobalInsuranceInfo memory userGlobalInsuranceInfo = usersGlobalInsuranceInfo[_userAddress];
        return (userGlobalInsuranceInfo.insuranceStreamRate, userGlobalInsuranceInfo.validTill);
    }

    uint256 minimumInsurancePeriod = 30; // [in minutes] // 120 minutes to be default
    uint256 maxInsuredDays = 1 days; // max. insurance period [in days] // 90 days to be default
    uint256 startWaitingTime = 2 minutes; // insurance active after given waiting period // 8 hours to be default
    
    error ProtocolNotActiveError();
    error NotEvenMinimumInsurancePeriodAmount();
    error ActiveInsuranceExistError();
    error InsuranceCoverNotAvailableError();
    /// @param _insuredAmount: insured amount
    /// @param _protocolID: like AAVE which a user want cover against
    function activateInsurance(uint256 _insuredAmount, uint256 _protocolID) public override {
        if (_insuredAmount < 1e18) {
            revert InsuranceCoverNotAvailableError();
        }
        if (
            (!protocolRegistry.ifEnoughLiquidity(_insuredAmount, _protocolID))    
        ) {
            revert ProtocolNotActiveError();
        }
        if (usersInsuranceInfo[_msgSender()][_protocolID].isValid) {
            revert ActiveInsuranceExistError();
        }
        uint256[] memory activeID = findActiveFlows(_msgSender(), protocolRegistry.protocolID());
        uint256 userEstimatedBalance = sztDAI.balanceOf(_msgSender()) - calculateTotalFlowMade(_msgSender(), activeID);
        uint256 flowRate = ((protocolRegistry.getStreamFlowRate(_protocolID) * _insuredAmount) / 1e18);
        UserGlobalInsuranceInfo storage userGlobalInsuranceInfo = usersGlobalInsuranceInfo[_msgSender()];
        userGlobalInsuranceInfo.insuranceStreamRate += flowRate;
        // user balance should be enough to run the insurance for atleast minimum insurance time duration
        if ((userGlobalInsuranceInfo.insuranceStreamRate * minimumInsurancePeriod) >= userEstimatedBalance) {
            revert NotEvenMinimumInsurancePeriodAmount();
        }
        uint256 validTill = ((userEstimatedBalance / userGlobalInsuranceInfo.insuranceStreamRate) * 1 minutes);
        userGlobalInsuranceInfo.validTill = validTill > maxInsuredDays ? (maxInsuredDays + block.timestamp) : (validTill + block.timestamp);
        for (uint256 i=0; i < activeID.length; i++) {
            uint256 earlierValidTillTime = usersInsuranceInfo[_msgSender()][activeID[i]].validTill;
            usersInsuranceInfo[_msgSender()][activeID[i]].validTill = userGlobalInsuranceInfo.validTill  < earlierValidTillTime ? userGlobalInsuranceInfo.validTill : earlierValidTillTime;
        }
        
        UserInsuranceInfo storage userInsuranceInfo = usersInsuranceInfo[_msgSender()][_protocolID];
        userInsuranceInfo.insuredAmount = _insuredAmount;
        userInsuranceInfo.insuranceFlowRate = flowRate;
        userInsuranceInfo.registrationTime = block.timestamp;
        userInsuranceInfo.startTime = block.timestamp + startWaitingTime;
        userInsuranceInfo.validTill = userGlobalInsuranceInfo.validTill;
        userInsuranceInfo.isValid = true;
        protocolRegistry.addCoverageOffered(_protocolID, _insuredAmount, flowRate);
        if (!userInsuranceInfo.gelatoCallMade) {
            // terminateInsurance.createGelatoProtocolSpecificTask(_msgSender(), _protocolID);
            userInsuranceInfo.gelatoCallMade = true;
        }
    }

    error InactiveInsuranceError();
    function addInsuranceAmount(uint256 _insuredAmount, uint256 _protocolID) external override {
        if (!usersInsuranceInfo[_msgSender()][_protocolID].isValid) {
            revert InactiveInsuranceError();
        }
        uint256 newInsuredAmount = usersInsuranceInfo[_msgSender()][_protocolID].insuredAmount + _insuredAmount;
        closeTokenStream(_msgSender(), _protocolID);
        activateInsurance(newInsuredAmount, _protocolID);
    }

    function minusInsuranceAmount(uint256 _insuredAmount, uint256 _protocolID) external override {
        if (!usersInsuranceInfo[_msgSender()][_protocolID].isValid) {
            revert InactiveInsuranceError();
        }
        uint256 newInsuredAmount = usersInsuranceInfo[_msgSender()][_protocolID].insuredAmount - _insuredAmount;
        closeTokenStream(_msgSender(), _protocolID);
        activateInsurance(newInsuredAmount, _protocolID);
    }

    function closeAllStream(address _userAddress) public override returns(bool) {
        uint256[] memory activeID = findActiveFlows(_msgSender(), protocolRegistry.protocolID());
        uint256 expectedAmountToBePaid = calculateTotalFlowMade(_userAddress, activeID);
        for (uint256 i=0; i < activeID.length; i++) {
            usersInsuranceInfo[_msgSender()][activeID[i]].isValid = false;
            uint256 flowRate = usersInsuranceInfo[_msgSender()][activeID[i]].insuranceFlowRate;
            uint256 insuredAmount = usersInsuranceInfo[_msgSender()][activeID[i]].insuredAmount;
            protocolRegistry.removeCoverageOffered(activeID[i], insuredAmount, flowRate);
        }
        usersGlobalInsuranceInfo[_msgSender()].insuranceStreamRate = 0;
        uint256 userBalance = sztDAI.balanceOf(_userAddress); 
        uint256 amountToBeBurned = expectedAmountToBePaid > userBalance ? userBalance : expectedAmountToBePaid;
        bool success = sztDAI.burnFrom(_userAddress, amountToBeBurned);
        return success;
    }

    /// NOTE: few if and else to consider for globalinsuranceinfo like endtime and start time 
    error TransactionFailed();
    error NoStreamRunningError();
    function closeTokenStream(address _userAddress, uint256 protocolID) public override returns(bool) {
        UserInsuranceInfo storage userInsuranceInfo = usersInsuranceInfo[_userAddress][protocolID];
        if (userInsuranceInfo.isValid) {
            userInsuranceInfo.isValid = false;
            uint256 userBalance = sztDAI.balanceOf(_userAddress);
            uint256 duration = (block.timestamp > userInsuranceInfo.startTime) ? (block.timestamp - userInsuranceInfo.startTime) : 0;
            uint256 expectedAmountToBePaid = (duration * userInsuranceInfo.insuranceFlowRate);
            if (expectedAmountToBePaid == 0) {
                return true;
            } 
            uint256 amountToBeBurned = (expectedAmountToBePaid > userBalance) ? userBalance : expectedAmountToBePaid;
            usersGlobalInsuranceInfo[_userAddress].insuranceStreamRate -= userInsuranceInfo.insuranceFlowRate;
            uint256 flowRate = userInsuranceInfo.insuranceFlowRate;
            uint256 insuredAmount = userInsuranceInfo.insuredAmount;
            protocolRegistry.removeCoverageOffered(protocolID, insuredAmount, flowRate);
            bool success = sztDAI.burnFrom(_userAddress, amountToBeBurned);
            return success;
        }
        return false;
    }

    error LowUserBalance();
    function transferFrom(address from, address to, uint256 _amount) public override returns(bool) {
        uint256[] memory activeID = findActiveFlows(_msgSender(), protocolRegistry.protocolID());
        uint256 expectedAmountToBePaid = totalAmountExpectedToBePaid(from, activeID);
        uint256 userBalance = sztDAI.balanceOf(from); 
        if ((expectedAmountToBePaid + _amount) > userBalance) {
            bool success = sztDAI.transferFrom(from, to, _amount);
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
          UserInsuranceInfo memory userInsuranceInfo = usersInsuranceInfo[_userAddress][i];
              if (userInsuranceInfo.isValid) {
                activeProtocolCount++;
            }
        }
        
        uint256[] memory activeID = new uint256[](activeProtocolCount);
        uint256 counter = 0;
        for (uint i = 0; i < protocolCount; i++) {
          UserInsuranceInfo storage userInsuranceInfo = usersInsuranceInfo[_userAddress][i];
              if (userInsuranceInfo.isValid) {
                activeID[counter] = i;
                counter += 1;
            }
        }
      return activeID;
    }

    /// internal call for transferFrom [not for external or public calls]
    function totalAmountExpectedToBePaid(address _userAddress, uint256[] memory _activeID) internal view returns(uint256) {
        uint256 balanceToBePaid;
        for (uint256 i=0; i< _activeID.length; i++){
            UserInsuranceInfo storage userActiveInsuranceInfo = usersInsuranceInfo[_userAddress][_activeID[i]];
            uint256 duration = (userActiveInsuranceInfo.validTill - userActiveInsuranceInfo.startTime);
            balanceToBePaid += (userActiveInsuranceInfo.insuranceFlowRate * duration);
        }
        return balanceToBePaid;
    }

    function calculateTotalFlowMade(address _userAddress, uint256[] memory _activeID) internal view returns(uint256) {
        uint256 balanceToBePaid;
        for (uint256 i=0; i< _activeID.length; i++){
            UserInsuranceInfo storage userActiveInsuranceInfo = usersInsuranceInfo[_userAddress][_activeID[i]];
            uint256 duration = block.timestamp > userActiveInsuranceInfo.startTime ? block.timestamp - userActiveInsuranceInfo.startTime : 0;
            balanceToBePaid += (userActiveInsuranceInfo.insuranceFlowRate * duration);
        }
        return balanceToBePaid;
    }

    function calculateTotalFlowMade(address _userAddress) public view override returns(uint256) {
        uint256 balanceToBePaid;
        uint256[] memory _activeID = findActiveFlows(_userAddress, protocolRegistry.protocolID());
        for (uint256 i=0; i< _activeID.length; i++){
            UserInsuranceInfo storage userActiveInsuranceInfo = usersInsuranceInfo[_userAddress][_activeID[i]];
            uint256 duration = (userActiveInsuranceInfo.validTill - userActiveInsuranceInfo.startTime);
            balanceToBePaid += (userActiveInsuranceInfo.insuranceFlowRate * duration);
        }
        return balanceToBePaid;
    } 

    function getUserInsuranceValidTillInfo(address _userAddress, uint256 _protocolID) external view override returns(uint256) {
        return usersInsuranceInfo[_userAddress][_protocolID].validTill;
    }

    function getUserInsuranceStatus(address _userAddress, uint256 _protocolID) external view override returns(bool) {
        return usersInsuranceInfo[_userAddress][_protocolID].isValid;
    }
}