// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ProtocolRegistry {
    uint256 public protocolCount;

    struct ProtocolInfo { 
        string protocolName;
        bool isProtocolActive;
        uint256 protocolLiquidation;
        uint256 insuredAmount;
        uint256 riskFactor;
        bool isCommunityGoverned;
        uint256 riskPoolCategory;
    }

    mapping (uint256 => ProtocolInfo) public ProtocolInfos;

    function addProtocolInfo(string memory _protocolName, uint256 _protocolLiquidation) external {
        protocolCount ++;
        ProtocolInfo storage newProtocol = ProtocolInfos[protocolCount];
        newProtocol.protocolName = _protocolName;
        newProtocol.isProtocolActive = true;
        newProtocol.protocolLiquidation = _protocolLiquidation;
        newProtocol.insuredAmount = 0;
        newProtocol.riskFactor = 100;
        newProtocol.isCommunityGoverned = false;
        newProtocol.riskPoolCategory = 2;
    }

    function addProtocolLiquidation(uint256 _protocolID, uint256 _liquidityAmount) external {
        ProtocolInfos[_protocolID].protocolLiquidation += _liquidityAmount;
    }

    function updateProtocolStatus(uint256 _protocolID, bool _isActive) external {
        ProtocolInfos[_protocolID].isProtocolActive = _isActive;
    }

    function withdrawProtcolLiquidity(uint256 _protocolID, uint256 _liquidityAmount) external {
        ProtocolInfos[_protocolID].protocolLiquidation -= _liquidityAmount;
    }

    function getIsProtocolActive(uint256 _protocolID) public view returns(bool) {
        return ProtocolInfos[_protocolID].isProtocolActive;
    }

    function updateProtocolRisk(uint256 _protocolID, uint256 _riskFactor, uint256 _riskPoolCategory, bool _isCommunityGoverned) external {
        ProtocolInfos[_protocolID].riskFactor = _riskFactor;
        ProtocolInfos[_protocolID].riskPoolCategory = _riskPoolCategory;
        ProtocolInfos[_protocolID].isCommunityGoverned = _isCommunityGoverned;       
    }
}