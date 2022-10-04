// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICErc20 {

    function name() external view returns (string memory);
    
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
    
    function balanceOf(address account) external returns (uint256);
}