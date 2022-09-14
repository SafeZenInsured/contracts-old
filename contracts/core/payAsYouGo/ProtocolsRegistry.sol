// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ProtocolRegistry {
    uint256 public protocolID = 0;

    struct ProtocolInfo { 
        string protocolName;
        bool isProtocolActive;
        uint256 protocolLiquidity;
        uint256 coverageOffered;
        uint256 riskFactor;
        bool isCommunityGoverned;
        uint256 riskPoolCategory;
        uint256 streamFlowRate;
    }

    mapping (uint256 => ProtocolInfo) public ProtocolInfos;

    function ifEnoughLiquidity(uint256 _insuredAmount, uint256 _protocolID) external view returns(bool) {
        bool isTrue=  ProtocolInfos[_protocolID].protocolLiquidity >= (ProtocolInfos[_protocolID].coverageOffered + _insuredAmount);
        return isTrue;
    }

    function updateStreamFlowRate(uint256 _protocolID, uint256 _newFlowRate) external {
        ProtocolInfos[_protocolID].streamFlowRate = _newFlowRate;
    }

    function getStreamFlowRate(uint256 _protocolID) external view returns(uint256) {
        return ProtocolInfos[_protocolID].streamFlowRate;
    }

    function addCoverageOffered(uint256 _protocolID, uint256 _insuredAmount) external {
        ProtocolInfos[_protocolID].coverageOffered += _insuredAmount;
    }

    function withdrawCoverageOffered(uint256 _protocolID, uint256 _insuredAmount) external {
        ProtocolInfos[_protocolID].coverageOffered -= _insuredAmount;
    }

    function addProtocolInfo(string memory _protocolName, uint256 _protocolLiquidity) external {
        protocolID ++;
        ProtocolInfo storage newProtocol = ProtocolInfos[protocolID];
        newProtocol.protocolName = _protocolName;
        newProtocol.isProtocolActive = true;
        newProtocol.protocolLiquidity = _protocolLiquidity;
        newProtocol.coverageOffered = 0;
        newProtocol.riskFactor = 100;
        newProtocol.isCommunityGoverned = false;
        newProtocol.riskPoolCategory = 2;
    }

    function addProtocolLiquidation(uint256 _protocolID, uint256 _liquidityAmount) external {
        ProtocolInfos[_protocolID].protocolLiquidity += _liquidityAmount;
    }

    function updateProtocolStatus(uint256 _protocolID, bool _isActive) external {
        ProtocolInfos[_protocolID].isProtocolActive = _isActive;
    }

    function withdrawProtcolLiquidity(uint256 _protocolID, uint256 _liquidityAmount) external {
        ProtocolInfos[_protocolID].protocolLiquidity -= _liquidityAmount;
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