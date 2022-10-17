// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../../interfaces/IProtocolsRegistry.sol";
import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/ICoveragePool.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ProtocolsRegistry is IProtocolsRegistry, Ownable {
    uint256 public override protocolID = 0;
    uint256 public override version = 0;
    uint256 private _flowVersionID = 0;
    IBuySellSZT private buySellSZT;
    ICoveragePool private _coveragePool;

    struct ProtocolInfo { 
        string protocolName;
        address protocolAddress;
        uint256 startVersionBlock;
        uint256 protocolLiquidity;
        uint256 coverageOffered;
        uint256 streamFlowRate;
        uint256 currentRiskPoolCategory;
        uint256 currentRiskFactor;
        bool currentlyIsCommunityGoverned;
    }

    struct ProtocolVersionableInfo {
        uint256 riskFactor;
        uint256 riskPoolCategory;
        bool isUpdated;
        bool isCommunityGoverned;
    }

    enum Activity{coverageAdded, coverageRemoved, liquidityAdded, liquidityRemoved, claimAppealed}

    struct GlobalProtocolInfo {
        Activity activity;
        uint256 startTime;
        uint256 endTime;
        uint256 liquidation;
        uint256 platformFee;
        uint256 globalProtocolLiquidity;
        uint256 globalIncomingStreamFlowRate;
    }

    function calculateUnderwriterBalance(uint256 protocolID_) external view {
        uint256[] memory activeVersionID = _coveragePool.getUnderwriterActiveVersionID(protocolID_);
        uint256 startVersionID = activeVersionID[0];
        uint256 premiumEarnedFlowRate = 0;
        uint256 userPremiumEarned = 0;
        uint256 riskPoolCategory = 0;
        uint256 counter = 0;
        for (uint256 i = startVersionID; i <= version; i++) {
            if(activeVersionID[counter] == startVersionID) {
                
            }
        }

    } 

    /// Version => LiquidationInPercent
    mapping(uint256 => uint256) public versionLiquidation;

    /// ProtocolID => ProtocolInfo
    mapping (uint256 => ProtocolInfo) public ProtocolInfos;

    /// riskPoolCategory => version => global protocol info
    mapping(uint256 => mapping(uint256 => GlobalProtocolInfo)) public GlobalProtocolsInfo;

    // protocol ID => version => protocolVersionableInfo
    mapping(uint256 => mapping(uint256 => ProtocolVersionableInfo)) public protocolsVersionableInfo;

    function setBuySellSZT(address buySellSZTCA) external onlyOwner {
        buySellSZT = IBuySellSZT(buySellSZTCA);
    }

    function liquidatePositions(uint256 riskPoolCategory, uint256 liquidatedPercent) external onlyOwner {
        GlobalProtocolsInfo[riskPoolCategory][version].liquidation = liquidatedPercent;
        for (uint i = 0; i <= protocolID; i++) {
            if (ProtocolInfos[i].currentRiskPoolCategory == riskPoolCategory) {
                ProtocolInfos[i].protocolLiquidity = ((ProtocolInfos[i].protocolLiquidity * liquidatedPercent)/100);
            }
        }
        ++version;
    }

    function updateStreamFlowRate(uint256 protocolID_, uint256 newFlowRate) external onlyOwner {
        ProtocolInfos[protocolID_].streamFlowRate = newFlowRate;
    }

    function _updateVersionInformation(uint256 protocolID_) internal {
        uint256 riskPoolCategory = ProtocolInfos[protocolID_].currentRiskPoolCategory;
        GlobalProtocolInfo storage globalProtocolInfo = GlobalProtocolsInfo[riskPoolCategory][version];
        // globalProtocolInfo.

    }

    function claimAdded(uint256 protocolID_) external {
        uint256 riskPoolCategory = ProtocolInfos[protocolID_].currentRiskPoolCategory;
        GlobalProtocolsInfo[riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousIncomingFlowRate = GlobalProtocolsInfo[riskPoolCategory][version].globalIncomingStreamFlowRate;
        uint256 previousLiquiditySupplied = GlobalProtocolsInfo[riskPoolCategory][version].globalProtocolLiquidity;
        ++version;
        GlobalProtocolsInfo[riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[riskPoolCategory][version].globalIncomingStreamFlowRate = previousIncomingFlowRate;
        GlobalProtocolsInfo[riskPoolCategory][version].globalProtocolLiquidity = previousLiquiditySupplied;
    }

    function _updateFlowVersionID(uint256 riskPoolCategory) internal {
        uint256 flowVersionID = _flowVersionID;
        for (uint256 i = _flowVersionID; i <= version; i++) {
            if (
                (GlobalProtocolsInfo[riskPoolCategory][i].startTime <= block.timestamp) &&
                (GlobalProtocolsInfo[riskPoolCategory][i].activity == Activity.coverageAdded)
            )  {
                ++flowVersionID;
            }
        }
        _flowVersionID = flowVersionID;
    }

    function addCoverageOffered(
        uint256 protocolID_, 
        uint256 coverageAmount,
        uint256 incomingFlowRate
    ) external override {
        uint256 riskPoolCategory = ProtocolInfos[protocolID_].currentRiskPoolCategory;
        GlobalProtocolsInfo[riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousIncomingFlowRate = GlobalProtocolsInfo[riskPoolCategory][version].globalIncomingStreamFlowRate;
        ++version;
        GlobalProtocolsInfo[riskPoolCategory][version].activity = Activity.coverageAdded;
        ProtocolInfos[protocolID_].coverageOffered += coverageAmount;
        GlobalProtocolsInfo[riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[riskPoolCategory][version].globalIncomingStreamFlowRate = previousIncomingFlowRate + incomingFlowRate;
    }

    function removeCoverageOffered(
        uint256 protocolID_, 
        uint256 coverageAmount, 
        uint256 incomingFlowRate
    ) external override returns(bool) {
        uint256 riskPoolCategory = ProtocolInfos[protocolID_].currentRiskPoolCategory;
        GlobalProtocolsInfo[riskPoolCategory][version].endTime = block.timestamp > GlobalProtocolsInfo[riskPoolCategory][version].startTime ? block.timestamp: GlobalProtocolsInfo[riskPoolCategory][version].startTime;
        uint256 previousIncomingFlowRate = GlobalProtocolsInfo[riskPoolCategory][version].globalIncomingStreamFlowRate;
        ++version;
        ProtocolInfos[protocolID_].coverageOffered -= coverageAmount;
        GlobalProtocolsInfo[riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[riskPoolCategory][version].globalIncomingStreamFlowRate = previousIncomingFlowRate - incomingFlowRate;
        return true;
    }

    function addProtocolLiquidation(
        uint256 protocolID_, 
        uint256 liquiditySupplied
    ) external override returns(bool) {
        uint256 riskPoolCategory = ProtocolInfos[protocolID_].currentRiskPoolCategory;
        GlobalProtocolsInfo[riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousLiquiditySupplied = GlobalProtocolsInfo[riskPoolCategory][version].globalProtocolLiquidity;
        ++version;
        uint256 SZTTokenCounter = buySellSZT.getSZTTokenCount();
        (, uint256 amountCoveredInDAI) = buySellSZT.calculateSZTPrice((SZTTokenCounter - liquiditySupplied), SZTTokenCounter);
        ProtocolInfos[protocolID_].protocolLiquidity += amountCoveredInDAI;
        GlobalProtocolsInfo[riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[riskPoolCategory][version].globalProtocolLiquidity = previousLiquiditySupplied + amountCoveredInDAI;
        return true;
    }

    function removeProtocolLiquidation(
        uint256 protocolID_, 
        uint256 liquiditySupplied
    ) external override returns(bool) {
        uint256 riskPoolCategory = ProtocolInfos[protocolID_].currentRiskPoolCategory;
        GlobalProtocolsInfo[riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousLiquiditySupplied = GlobalProtocolsInfo[riskPoolCategory][version].globalProtocolLiquidity;
        ++version;
        uint256 SZTTokenCounter = buySellSZT.getSZTTokenCount();
        (, uint256 amountCoveredInDAI) = buySellSZT.calculateSZTPrice(SZTTokenCounter, (SZTTokenCounter +  liquiditySupplied));
        ProtocolInfos[protocolID_].protocolLiquidity -= amountCoveredInDAI;
        GlobalProtocolsInfo[riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[riskPoolCategory][version].globalProtocolLiquidity = previousLiquiditySupplied - amountCoveredInDAI;
        return true;
    }

    event RequestAddNewProtocol(string indexed protocolName, address indexed protocolAddress);
    function requestAddNewProtocol(string memory protocolName, address protocolAddress) external override {
        emit RequestAddNewProtocol(protocolName, protocolAddress);
    }

    function addProtocolInfo(
        string memory protocolName, 
        address protocolAddress,
        uint256 riskFactor,
        bool isCommunityGoverned,
        uint256 riskPoolCategory,
        uint256 streamFlowRate
        ) external onlyOwner {
        protocolID ++;
        ProtocolInfo storage protocolInfo = ProtocolInfos[protocolID];
        protocolInfo.protocolName = protocolName;
        protocolInfo.protocolAddress = protocolAddress;
        protocolInfo.startVersionBlock = version;
        protocolInfo.protocolLiquidity = 0;
        protocolInfo.coverageOffered = 0;
        protocolInfo.streamFlowRate = streamFlowRate;
        protocolInfo.currentRiskFactor =riskFactor;
        protocolInfo.currentRiskPoolCategory = riskPoolCategory;
        protocolInfo.currentlyIsCommunityGoverned = isCommunityGoverned;
        ProtocolVersionableInfo storage protocolVersionableInfo = protocolsVersionableInfo[protocolID][version];
        protocolVersionableInfo.isUpdated = true;
        protocolVersionableInfo.riskFactor = riskFactor;
        protocolVersionableInfo.isCommunityGoverned = isCommunityGoverned;
        protocolVersionableInfo.riskPoolCategory = riskPoolCategory; 
    }

    function viewProtocolInfo(uint256 protocolID_) external view returns(string memory, address, uint256, uint256, uint256) {
        ProtocolInfo storage protocolInfo = ProtocolInfos[protocolID_];
        return (protocolInfo.protocolName, 
                protocolInfo.protocolAddress, 
                protocolInfo.protocolLiquidity, 
                protocolInfo.coverageOffered, 
                protocolInfo.streamFlowRate
        );
    }

    function updateProtocolRiskPoolCategory(uint256 protocolID_, uint256 riskPoolCategory) external onlyOwner {
        uint256 beforeRiskPoolCategory = ProtocolInfos[protocolID_].currentRiskPoolCategory;
        version ++;
        protocolsVersionableInfo[protocolID][version].riskPoolCategory = riskPoolCategory;
        GlobalProtocolsInfo[riskPoolCategory][version].globalProtocolLiquidity += ProtocolInfos[protocolID_].protocolLiquidity;
        GlobalProtocolsInfo[beforeRiskPoolCategory][version].globalProtocolLiquidity -= ProtocolInfos[protocolID_].protocolLiquidity;
        protocolsVersionableInfo[protocolID][version].isUpdated = true;
        ProtocolInfos[protocolID_].currentRiskPoolCategory = riskPoolCategory;
    }

    function getStreamFlowRate(uint256 protocolID_) external view override returns(uint256) {
        return ProtocolInfos[protocolID_].streamFlowRate;
    }

    function ifProtocolUpdated(uint256 protocolID_, uint256 version_) external view override returns (bool) {
        return protocolsVersionableInfo[protocolID_][version_].isUpdated;
    }

    function getProtocolRiskCategory(uint256 protocolID_) external view override returns (uint256) {
        return ProtocolInfos[protocolID_].currentRiskPoolCategory;
    }

    function getProtocolVersionRiskCategory(uint256 protocolID_, uint256 version_) external override view returns(uint256) {
        return protocolsVersionableInfo[protocolID_][version_].riskPoolCategory;
    }

    function getEarnedPremiumFlowRate(uint256 riskPoolCategory, uint256 version_) external view override returns(uint256) {
        return GlobalProtocolsInfo[riskPoolCategory][version_].globalIncomingStreamFlowRate;
    }

    function getGlobalProtocolLiquidity(uint256 riskPoolCategory, uint256 version_) external view override returns (uint256) {
        return GlobalProtocolsInfo[riskPoolCategory][version_].globalProtocolLiquidity;
    }

    function getTimeInterval(uint256 riskPoolCategory, uint256 version_) external view override returns(uint256) {
        uint256 startTime = GlobalProtocolsInfo[riskPoolCategory][version_].startTime;
        uint256 endTime = GlobalProtocolsInfo[riskPoolCategory][version_].endTime > 0 ? GlobalProtocolsInfo[riskPoolCategory][version_].endTime : block.timestamp;
        return (endTime-startTime); 
    }

    function getLiquidationFactor(uint256 riskPoolCategory, uint256 version_) external view override returns(uint256) {
        return GlobalProtocolsInfo[riskPoolCategory][version_].liquidation;
    }

    function isRiskPoolLiquidated(uint256 version_, uint256 riskPoolCategory) external view override returns (bool) {
        return versionLiquidation[version_] == riskPoolCategory;
    }

    function calculateRiskPoolLiquidity(uint256 riskPoolCategory) external view override returns(uint256) {
        uint256 riskPoolLiquidity = 0;
        for (uint256 i = 0; i <= version; i++) {
            GlobalProtocolInfo memory globalProtocolInfo = GlobalProtocolsInfo[i][riskPoolCategory];
            if (globalProtocolInfo.globalProtocolLiquidity > 0) {
                riskPoolLiquidity += globalProtocolInfo.globalProtocolLiquidity; 
            }
            if (versionLiquidation[i] == riskPoolCategory) {
                riskPoolLiquidity = ((riskPoolLiquidity * globalProtocolInfo.liquidation)/100);
            }
        }
        return riskPoolLiquidity;
    }

    function ifEnoughLiquidity(uint256 insuredAmount, uint256 protocolID_) external view override returns(bool) {
        bool isTrue=  ProtocolInfos[protocolID_].protocolLiquidity >= (ProtocolInfos[protocolID_].coverageOffered + insuredAmount);
        return isTrue;
    }
}