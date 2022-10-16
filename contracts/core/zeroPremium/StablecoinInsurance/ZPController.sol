// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../../dependencies/openzeppelin/Ownable.sol";

contract StablecoinZPController is Ownable {
    uint256 public stablecoinID;
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

    struct StablecoinInfo {
        string stablecoinName;
        address deployedAddress;
        uint256 startVersionBlock;
    }

    struct StablecoinRiskInfo {
        bool isUpdated;
        bool isCommunityGoverned;
        uint256 riskFactor;
        uint256 riskPoolCategory; // low = 1, medium = 2, or high = 3, notCovered = 4
    }

    // protocolID => VersionNumber => ProtocolInfo
    mapping(uint256 => mapping(uint256 => StablecoinRiskInfo)) public stablecoinsRiskInfo;

    mapping (uint256 => StablecoinInfo) public stablecoinsInfo;

    event NewProtocolAdded(uint256 indexed _stablecoinID, string indexed _stablecoinName);

    function addCoveredProtocol(
        string memory _stablecoinName,
        address _deployedAddress,
        bool _isCommunityGoverned,
        uint256 _riskFactor,
        uint256 _riskPoolCategory
    ) external onlyOwner {
        StablecoinInfo storage protocolInfo = stablecoinsInfo[stablecoinID];
        protocolInfo.stablecoinName = _stablecoinName;
        protocolInfo.deployedAddress = _deployedAddress;
        protocolInfo.startVersionBlock = latestVersion;
        StablecoinRiskInfo storage protocolRiskInfo = stablecoinsRiskInfo[stablecoinID][latestVersion];
        protocolRiskInfo.isUpdated = true;
        protocolRiskInfo.isCommunityGoverned = _isCommunityGoverned;
        protocolRiskInfo.riskFactor = _riskFactor;
        protocolRiskInfo.riskPoolCategory = _riskPoolCategory;
        emit NewProtocolAdded(stablecoinID, _stablecoinName);
        ++stablecoinID;
    }

    function updateProtocolInfo(address _deployedAddress, uint256 _protocolID) external onlyOwner {
        stablecoinsInfo[_protocolID].deployedAddress = _deployedAddress;
    }

    /// first adding a new version to ensure that risk category is applied from the time this function gets called
    function updateRiskPoolCategory(uint256 _protocolID, uint256 _riskPoolCategory) external onlyOwner {
        addNewVersion();
        StablecoinRiskInfo storage protocolRiskInfo = stablecoinsRiskInfo[_protocolID][latestVersion];
        protocolRiskInfo.isUpdated = true;
        protocolRiskInfo.riskPoolCategory = _riskPoolCategory;
    }

    function updateRiskFactor(uint256 _protocolID, uint256 _riskFactor) external onlyOwner {
        StablecoinRiskInfo storage protocolRiskInfo = stablecoinsRiskInfo[_protocolID][latestVersion];
        protocolRiskInfo.riskFactor = _riskFactor;
    }

    function liquidateRiskPool(uint256 _riskPoolCategory, uint256 _liquidationFactor) external onlyOwner {
        versionLiquidationFactor[latestVersion].liquidation = _liquidationFactor;
        versionLiquidationFactor[latestVersion].riskPoolCategory = _riskPoolCategory;
        addNewVersion();
    }

    function addNewVersion() internal {
        latestVersion += 1;
        versionLiquidationFactor[latestVersion].liquidation = 100;
    }

    function getProtocolRiskCategory(uint256 _protocolID, uint256 _version) external view returns (uint256) {
        return stablecoinsRiskInfo[_protocolID][_version].riskPoolCategory;
    }

    function ifProtocolUpdated(uint256 _protocolID, uint256 _version) external view returns (bool) {
        return stablecoinsRiskInfo[_protocolID][_version].isUpdated;
    }

    function getProtocolStartVersionInfo(uint256 _protocolID) external view returns(uint256) {
        return stablecoinsInfo[_protocolID].startVersionBlock;
    }
}