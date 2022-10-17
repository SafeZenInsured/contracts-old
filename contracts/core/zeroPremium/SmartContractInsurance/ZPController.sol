// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../../dependencies/openzeppelin/Ownable.sol";
import "./../../../../interfaces/ISmartContractZPController.sol";

contract SmartContractZPController is Ownable, ISmartContractZPController {
    uint256 public override protocolID;
    uint256 public override latestVersion; // version changes whenever there is asset liquidation, i.e. insurance gets activated
    
    struct VersionInfo {
        uint256 liquidation;
        uint256 riskPoolCategory; // liquidation based on risk-pool category
    }

    struct ProtocolInfo {
        string protocolName;
        address deployedAddress;
        uint256 startVersionBlock;
    }

    struct ProtocolRiskInfo {
        bool isUpdated;
        bool isCommunityGoverned;
        uint256 riskFactor;
        uint256 riskPoolCategory; // low = 1, medium = 2, or high = 3, notCovered = 4
    }

    mapping (uint256 => ProtocolInfo) public protocolsInfo;

    // protocolID => VersionNumber => ProtocolInfo
    mapping(uint256 => mapping(uint256 => ProtocolRiskInfo)) public protocolsRiskInfo;

    mapping(uint256 => VersionInfo) public versionLiquidationFactor; // for each insurance coverage event, keeping a track of liquidation percent

    event NewProtocolAdded(uint256 indexed protocolID_, string indexed protocolName);

    constructor() {
        VersionInfo storage versionInfo = versionLiquidationFactor[0];
        versionInfo.liquidation = 100;
    }

    function updateRiskFactor(uint256 protocolID_, uint256 riskFactor) external onlyOwner {
        ProtocolRiskInfo storage protocolRiskInfo = protocolsRiskInfo[protocolID_][latestVersion];
        protocolRiskInfo.riskFactor = riskFactor;
    }

    function liquidateRiskPool(uint256 riskPoolCategory, uint256 liquidationFactor) external onlyOwner {
        versionLiquidationFactor[latestVersion].liquidation = liquidationFactor;
        versionLiquidationFactor[latestVersion].riskPoolCategory = riskPoolCategory;
        _addNewVersion();
    }

    function updateProtocolInfo(address deployedAddress, uint256 protocolID_) external onlyOwner {
        protocolsInfo[protocolID_].deployedAddress = deployedAddress;
    }

    /// first adding a new version to ensure that risk category is applied from the time this function gets called
    function updateRiskPoolCategory(uint256 protocolID_, uint256 riskPoolCategory) external onlyOwner {
        _addNewVersion();
        ProtocolRiskInfo storage protocolRiskInfo = protocolsRiskInfo[protocolID_][latestVersion];
        protocolRiskInfo.isUpdated = true;
        protocolRiskInfo.riskPoolCategory = riskPoolCategory;
    }

    function addCoveredProtocol(
        string memory protocolName,
        address deployedAddress,
        bool isCommunityGoverned,
        uint256 riskFactor,
        uint256 riskPoolCategory
    ) external onlyOwner {
        ProtocolInfo storage protocolInfo = protocolsInfo[protocolID];
        protocolInfo.protocolName = protocolName;
        protocolInfo.deployedAddress = deployedAddress;
        protocolInfo.startVersionBlock = latestVersion;
        ProtocolRiskInfo storage protocolRiskInfo = protocolsRiskInfo[protocolID][latestVersion];
        protocolRiskInfo.isUpdated = true;
        protocolRiskInfo.isCommunityGoverned = isCommunityGoverned;
        protocolRiskInfo.riskFactor = riskFactor;
        protocolRiskInfo.riskPoolCategory = riskPoolCategory;
        ++protocolID;
        emit NewProtocolAdded(protocolID, protocolName);
    }

    function _addNewVersion() internal {
        latestVersion += 1;
        versionLiquidationFactor[latestVersion].liquidation = 100;
    }

    function getProtocolRiskCategory(uint256 protocolID_, uint256 version) external view returns (uint256) {
        return protocolsRiskInfo[protocolID_][version].riskPoolCategory;
    }

    function ifProtocolUpdated(uint256 protocolID_, uint256 version) external view returns (bool) {
        return protocolsRiskInfo[protocolID_][version].isUpdated;
    }

    function getProtocolStartVersionInfo(uint256 protocolID_) external view returns(uint256) {
        return protocolsInfo[protocolID_].startVersionBlock;
    }

    function isRiskPoolLiquidated(uint256 version, uint256 riskPoolCategory) external view returns (bool) {
        bool isTrue = (versionLiquidationFactor[version].riskPoolCategory == riskPoolCategory);
        return isTrue;
    }

    function getLiquidationFactor(uint256 version) external view returns(uint256) {
        return versionLiquidationFactor[version].liquidation;
    }
}