// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IAAVEImplementation {
    
    function mintERC20Tokens(address tokenAddress, uint256 amount) external;

    function supplyToken(address tokenAddress, address rewardTokenAddress, uint256 _amount) external;

    function withdrawToken(address tokenAddress, address rewardTokenAddress, uint256 _amount) external;

    function calculateUserBalance(address rewardTokenAddress) external view returns(uint256);

}