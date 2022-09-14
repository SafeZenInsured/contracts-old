// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../dependencies/openzeppelin/Ownable.sol";

contract ZPController is Ownable {
    uint256 protocolID = 0;
    uint256 public latestVersion = 0; // version changes whenever there is asset liquidation, i.e. insurance gets activated
    mapping(uint256 => uint256) public versionLiquidationFactor; // for each insurance coverage event, keeping a track of liquidation percent

    constructor() {
        versionLiquidationFactor[0] = 100;
    }

    struct ProtocolInfo {
        string protocolName;
        address deployedAddress;
        uint256 riskFactor;
        bool isCommunityGoverned;
        uint256 riskPoolCategory; // notCovered = 0, low = 1, medium = 2, or high = 3
    }

    mapping(uint256 => ProtocolInfo) public protocolsInfo;

    function updateVersionInfo(uint256 _version, uint256 _liquidationFactor) external onlyOwner {
        versionLiquidationFactor[_version] = _liquidationFactor;
        addNewVersion();
    }

    function addNewVersion() internal {
        latestVersion += 1;
        versionLiquidationFactor[latestVersion] = 100;
    }

    function addCoveredProtocol(
        string memory _protocolName,
        address _deployedAddress,
        uint256 _riskFactor, 
        bool _isCommunityGoverned, 
        uint256 _riskPoolCategory
        ) external onlyOwner {
        ProtocolInfo storage protocolInfo = protocolsInfo[protocolID];
        protocolInfo.protocolName = _protocolName;
        protocolInfo.deployedAddress = _deployedAddress;
        protocolInfo.riskFactor = _riskFactor;
        protocolInfo.isCommunityGoverned = _isCommunityGoverned;
        protocolInfo.riskPoolCategory = _riskPoolCategory;
        }

    function updateRiskPoolCategory(uint256 _protocolID, uint256 _riskPoolCategory) external onlyOwner {
        ProtocolInfo storage protocolInfo = protocolsInfo[_protocolID];
        protocolInfo.riskPoolCategory = _riskPoolCategory;
    }

    function updateRiskFactor(uint256 _protocolID, uint256 _riskFactor) external onlyOwner {
        ProtocolInfo storage protocolInfo = protocolsInfo[_protocolID];
        protocolInfo.riskFactor = _riskFactor;
    } 
}