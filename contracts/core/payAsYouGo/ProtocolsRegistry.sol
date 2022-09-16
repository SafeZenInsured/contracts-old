// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../../interfaces/IProtocolsRegistry.sol";
import "./../../dependencies/openzeppelin/Ownable.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ProtocolRegistry is IProtocolsRegistry, Ownable {
    uint256 public protocolID = 0;
    uint256 public version = 0;

    struct ProtocolInfo { 
        string protocolName;
        address protocolAddress;
        uint256 startVersionBlock;
        uint256 protocolLiquidity;
        uint256 coverageOffered;
        uint256 streamFlowRate;
    }

    mapping (uint256 => ProtocolInfo) public ProtocolInfos;

    struct ProtocolVersionableInfo {
        bool isUpdated;
        uint256 riskFactor;
        bool isCommunityGoverned;
        uint256 riskPoolCategory;
        
    }
    // protocol ID => version => protocolVersionableInfo
    mapping(uint256 => mapping(uint256 => ProtocolVersionableInfo)) public protocolsVersionableInfo;

    struct GlobalProtocolInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 liquidation;
        uint256 platformFee;
        uint256 globalProtocolLiquidity;
        uint256 globalIncomingStreamFlowRate;
    }

    /// riskPoolCategory => version => global protocol info
    mapping(uint256 => mapping(uint256 => GlobalProtocolInfo)) public GlobalProtocolsInfo;

    mapping(uint256 => uint256) public versionLiquidation;

    function getTimeInterval() external view returns(uint256) {
        
    }

    function liquidatePositions(uint256 _riskPoolCategory, uint256 _liquidatedPercent) external onlyOwner {
        GlobalProtocolsInfo[_riskPoolCategory][version].liquidation = _liquidatedPercent;
        for (uint i = 0; i <= protocolID; i++) {
            if (protocolsVersionableInfo[i][version].riskPoolCategory == _riskPoolCategory) {
                ProtocolInfos[i].protocolLiquidity = ((ProtocolInfos[i].protocolLiquidity * _liquidatedPercent)/100);
            }
        }
        version ++;
    }

    function getLiquidationFactor(uint256 _riskPoolCategory, uint256 _version) external view returns(uint256) {
        return GlobalProtocolsInfo[_riskPoolCategory][_version].liquidation;
    }

    function isRiskPoolLiquidated(uint256 _version, uint256 _riskPoolCategory) external view returns (bool) {
        return versionLiquidation[_version] == _riskPoolCategory;
    }

    function calculateRiskPoolLiquidity(uint256 _riskPoolCategory) external view override returns(uint256) {
        uint256 riskPoolLiquidity = 0;
        for (uint256 i = 0; i <= version; i++) {
            GlobalProtocolInfo memory globalProtocolInfo = GlobalProtocolsInfo[i][_riskPoolCategory];
            if (globalProtocolInfo.globalProtocolLiquidity > 0) {
                riskPoolLiquidity += globalProtocolInfo.globalProtocolLiquidity; 
            }
            if (versionLiquidation[i] == _riskPoolCategory) {
                riskPoolLiquidity = ((riskPoolLiquidity * globalProtocolInfo.liquidation)/100);
            }
        }
        return riskPoolLiquidity;
    }

    function ifEnoughLiquidity(uint256 _insuredAmount, uint256 _protocolID) external view override returns(bool) {
        bool isTrue=  ProtocolInfos[_protocolID].protocolLiquidity >= (ProtocolInfos[_protocolID].coverageOffered + _insuredAmount);
        return isTrue;
    }

    function updateStreamFlowRate(uint256 _protocolID, uint256 _newFlowRate) external onlyOwner {
        ProtocolInfos[_protocolID].streamFlowRate = _newFlowRate;
    }

    function getStreamFlowRate(uint256 _protocolID) external view override returns(uint256) {
        return ProtocolInfos[_protocolID].streamFlowRate;
    }

    function addCoverageOffered(
        uint256 _protocolID, 
        uint256 _coverageAmount,
        uint256 _incomingFlowRate
    ) external override {
        uint256 _riskPoolCategory = protocolsVersionableInfo[_protocolID][version].riskPoolCategory;
        GlobalProtocolsInfo[_riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousIncomingFlowRate = GlobalProtocolsInfo[_riskPoolCategory][version].globalIncomingStreamFlowRate;
        version ++;
        ProtocolInfos[_protocolID].coverageOffered += _coverageAmount;
        GlobalProtocolsInfo[_riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[_riskPoolCategory][version].globalIncomingStreamFlowRate = previousIncomingFlowRate + _incomingFlowRate;
    }

    function removeCoverageOffered(
        uint256 _protocolID, 
        uint256 _coverageAmount, 
        uint256 _incomingFlowRate
    ) external {
        uint256 _riskPoolCategory = protocolsVersionableInfo[_protocolID][version].riskPoolCategory;
        GlobalProtocolsInfo[_riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousIncomingFlowRate = GlobalProtocolsInfo[_riskPoolCategory][version].globalIncomingStreamFlowRate;
        version ++;
        ProtocolInfos[_protocolID].coverageOffered -= _coverageAmount;
        GlobalProtocolsInfo[_riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[_riskPoolCategory][version].globalIncomingStreamFlowRate = previousIncomingFlowRate - _incomingFlowRate;
    }

    function addProtocolLiquidation(
        uint256 _protocolID, 
        uint256 _liquiditySupplied
    ) external {
        uint256 _riskPoolCategory = protocolsVersionableInfo[_protocolID][version].riskPoolCategory;
        GlobalProtocolsInfo[_riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousLiquiditySupplied = GlobalProtocolsInfo[_riskPoolCategory][version].globalProtocolLiquidity;
        version ++;
        ProtocolInfos[_protocolID].protocolLiquidity += _liquiditySupplied;
        GlobalProtocolsInfo[_riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[_riskPoolCategory][version].globalProtocolLiquidity = previousLiquiditySupplied + _liquiditySupplied;
    }

    function removeProtocolLiquidation(
        uint256 _protocolID, 
        uint256 _liquiditySupplied
    ) external {
        uint256 _riskPoolCategory = protocolsVersionableInfo[_protocolID][version].riskPoolCategory;
        GlobalProtocolsInfo[_riskPoolCategory][version].endTime = block.timestamp;
        uint256 previousLiquiditySupplied = GlobalProtocolsInfo[_riskPoolCategory][version].globalProtocolLiquidity;
        version ++;
        ProtocolInfos[_protocolID].protocolLiquidity -= _liquiditySupplied;
        GlobalProtocolsInfo[_riskPoolCategory][version].startTime = block.timestamp;
        GlobalProtocolsInfo[_riskPoolCategory][version].globalProtocolLiquidity = previousLiquiditySupplied - _liquiditySupplied;
    }

    event RequestAddNewProtocol(string indexed _protocolName, address indexed _protocolAddress);
    function requestAddNewProtocol(string memory _protocolName, address _protocolAddress) external {
        emit RequestAddNewProtocol(_protocolName, _protocolAddress);
    }

    function addProtocolInfo(
        string memory _protocolName, 
        address _protocolAddress,
        uint256 _riskFactor,
        bool _isCommunityGoverned,
        uint256 _riskPoolCategory,
        uint256 _streamFlowRate
        ) external onlyOwner {
        protocolID ++;
        ProtocolInfo storage protocolInfo = ProtocolInfos[protocolID];
        protocolInfo.protocolName = _protocolName;
        protocolInfo.protocolAddress = _protocolAddress;
        protocolInfo.startVersionBlock = version;
        protocolInfo.protocolLiquidity = 0;
        protocolInfo.coverageOffered = 0;
        protocolInfo.streamFlowRate = _streamFlowRate;
        ProtocolVersionableInfo storage protocolVersionableInfo = protocolsVersionableInfo[protocolID][version];
        protocolVersionableInfo.isUpdated = true;
        protocolVersionableInfo.riskFactor = _riskFactor;
        protocolVersionableInfo.isCommunityGoverned = _isCommunityGoverned;
        protocolVersionableInfo.riskPoolCategory = _riskPoolCategory; 
    }

    function updateProtocolRiskPoolCategory(uint256 _protocolID, uint256 _riskPoolCategory) external onlyOwner {
        uint256 beforeRiskPoolCategory = protocolsVersionableInfo[protocolID][version].riskPoolCategory;
        version ++;
        protocolsVersionableInfo[protocolID][version].riskPoolCategory = _riskPoolCategory;
        GlobalProtocolsInfo[_riskPoolCategory][version].globalProtocolLiquidity += ProtocolInfos[_protocolID].protocolLiquidity;
        GlobalProtocolsInfo[beforeRiskPoolCategory][version].globalProtocolLiquidity -= ProtocolInfos[_protocolID].protocolLiquidity;
        protocolsVersionableInfo[protocolID][version].isUpdated = true;
    }

    function ifProtocolUpdated(uint256 _protocolID, uint256 _version) external view returns (bool) {
        return protocolsVersionableInfo[_protocolID][_version].isUpdated;
    }

    function getProtocolRiskCategory(uint256 _protocolID, uint256 _version) external view returns (uint256) {
        return protocolsVersionableInfo[_protocolID][_version].riskPoolCategory;
    }
}