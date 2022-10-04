// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./../../dependencies/openzeppelin/Ownable.sol";

contract ZPController is Ownable {
    uint256 public protocolID;
    uint256 public latestVersion; // version changes whenever there is asset liquidation, i.e. insurance gets activated
    
    struct VersionInfo {
        uint256 liquidation;
        uint256 riskPoolCategory; // liquidation based on risk-pool category
    }

    mapping(uint256 => VersionInfo) public versionLiquidationFactor; // for each insurance coverage event, keeping a track of liquidation percent

    function isRiskPoolLiquidated(uint256 _version, uint256 _riskPoolCategory) external view returns (bool) {
        bool isTrue = (versionLiquidationFactor[_version].riskPoolCategory == _riskPoolCategory);
        return isTrue;
    }

    function getLiquidationFactor(uint256 _version) external view returns(uint256) {
        return versionLiquidationFactor[_version].liquidation;
    }

    constructor() {
        VersionInfo storage versionInfo = versionLiquidationFactor[0];
        versionInfo.liquidation = 100;
    }

    struct ProtocolInfo {
        string protocolName;
        address deployedAddress;
        uint256 startVersionBlock;
    }

    mapping (uint256 => ProtocolInfo) public protocolsInfo;

    event NewProtocolAdded(uint256 indexed _protocolID, string indexed _protocolName);
    function addCoveredProtocol(
        string memory _protocolName,
        address _deployedAddress,
        bool _isCommunityGoverned,
        uint256 _riskFactor,
        uint256 _riskPoolCategory
        ) external onlyOwner {
        ProtocolInfo storage protocolInfo = protocolsInfo[protocolID];
        protocolInfo.protocolName = _protocolName;
        protocolInfo.deployedAddress = _deployedAddress;
        protocolInfo.startVersionBlock = latestVersion;
        emit NewProtocolAdded(protocolID, _protocolName);
        ProtocolRiskInfo storage protocolRiskInfo = protocolsRiskInfo[protocolID][latestVersion];
        protocolRiskInfo.isUpdated = true;
        protocolRiskInfo.isCommunityGoverned = _isCommunityGoverned;
        protocolRiskInfo.riskFactor = _riskFactor;
        protocolRiskInfo.riskPoolCategory = _riskPoolCategory;
        protocolID ++;
    }

    function updateProtocolInfo(address _deployedAddress, uint256 _protocolID) external onlyOwner {
        protocolsInfo[_protocolID].deployedAddress = _deployedAddress;
    }

    function getProtocolStartVersionInfo(uint256 _protocolID) external view returns(uint256) {
        return protocolsInfo[_protocolID].startVersionBlock;
    }

    struct ProtocolRiskInfo {
        bool isUpdated;
        bool isCommunityGoverned;
        uint256 riskFactor;
        uint256 riskPoolCategory; // low = 1, medium = 2, or high = 3, notCovered = 4
    }

    // protocolID => VersionNumber => ProtocolInfo
    mapping(uint256 => mapping(uint256 => ProtocolRiskInfo)) public protocolsRiskInfo;

    /// first adding a new version to ensure that risk category is applied from the time this function gets called
    function updateRiskPoolCategory(uint256 _protocolID, uint256 _riskPoolCategory) external onlyOwner {
        addNewVersion();
        ProtocolRiskInfo storage protocolRiskInfo = protocolsRiskInfo[_protocolID][latestVersion];
        protocolRiskInfo.isUpdated = true;
        protocolRiskInfo.riskPoolCategory = _riskPoolCategory;
    }

    function updateRiskFactor(uint256 _protocolID, uint256 _riskFactor) external onlyOwner {
        ProtocolRiskInfo storage protocolRiskInfo = protocolsRiskInfo[_protocolID][latestVersion];
        protocolRiskInfo.riskFactor = _riskFactor;
    }

    function getProtocolRiskCategory(uint256 _protocolID, uint256 _version) external view returns (uint256) {
        return protocolsRiskInfo[_protocolID][_version].riskPoolCategory;
    }

    function ifProtocolUpdated(uint256 _protocolID, uint256 _version) external view returns (bool) {
        return protocolsRiskInfo[_protocolID][_version].isUpdated;
    }

    function addNewVersion() internal {
        latestVersion += 1;
        versionLiquidationFactor[latestVersion].liquidation = 100;
    }

    function liduidateRiskPool(uint256 _riskPoolCategory, uint256 _liquidationFactor) external onlyOwner {
        versionLiquidationFactor[latestVersion].liquidation = _liquidationFactor;
        versionLiquidationFactor[latestVersion].riskPoolCategory = _riskPoolCategory;
        addNewVersion();
    }

     
}