// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ICompoundImplementation {
    
    function mintERC20Tokens(address userAddress, address tokenAddress, uint256 amount) external;

    function supplyToken(address tokenAddress, address rewardTokenAddress, uint256 _amount) external returns(uint256);

    function withdrawToken(address tokenAddress, address rewardTokenAddress, uint256 _amount) external returns(bool);

    function calculateUserBalance(address rewardTokenAddress) external view returns(uint256);

}