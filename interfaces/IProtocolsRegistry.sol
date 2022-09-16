// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
interface IProtocolsRegistry {

    function calculateRiskPoolLiquidity(uint256 _riskPoolCategory) external view returns(uint256);

    function ifEnoughLiquidity(uint256 _insuredAmount, uint256 _protocolID) external view returns(bool);

    function getStreamFlowRate(uint256 _protocolID) external view returns(uint256);

    function protocolID() external view returns(uint256);

    function version() external view returns(uint256);

    function addCoverageOffered(
        uint256 _protocolID, 
        uint256 _coverageAmount,
        uint256 _incomingFlowRate
    ) external;

    function removeCoverageOffered(
        uint256 _protocolID, 
        uint256 _coverageAmount, 
        uint256 _incomingFlowRate
    ) external;

    function addProtocolLiquidation(
        uint256 _protocolID, 
        uint256 _liquiditySupplied
    ) external;

    function requestAddNewProtocol(string memory _protocolName, address _protocolAddress) external;

    function ifProtocolUpdated(uint256 _protocolID, uint256 _version) external view returns (bool);

    function getProtocolRiskCategory(uint256 _protocolID, uint256 _version) external view returns (uint256);

    function getLiquidationFactor(uint256 _riskPoolCategory, uint256 _version) external view returns(uint256);

    function isRiskPoolLiquidated(uint256 _version, uint256 _riskPoolCategory) external view returns (bool);

}