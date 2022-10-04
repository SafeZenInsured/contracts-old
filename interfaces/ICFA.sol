// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;


interface ICFA {

    function activateInsurance(uint256 _insuredAmount, uint256 _protocolID) external;

    function findActiveFlows(address userAddress, uint256 protocolCount) external view returns(uint256[] memory);

    function calculateTotalFlowMade(address _userAddress) external view returns(uint256);

    function closeTokenStream(address userAddress, uint256 protocolID) external returns(bool);

    function transferFrom(address from, address to, uint256 amount) external returns(bool);

    function getUserInsuranceValidTillInfo(address _userAddress, uint256 _protocolID) external view returns(uint256);

    function getUserInsuranceStatus(address _userAddress, uint256 _protocolID) external view returns(bool);
    
    function closeAllStream(address _userAddress) external returns(bool);

    function addInsuranceAmount(uint256 _insuredAmount, uint256 _protocolID) external;

    function minusInsuranceAmount(uint256 _insuredAmount, uint256 _protocolID) external;

}