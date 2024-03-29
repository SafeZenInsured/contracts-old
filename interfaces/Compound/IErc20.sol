// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IErc20 {
    function allocateTo(address toAddress, uint256 value) external;

    function approve(address, uint256) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    function balanceOf(address account) external returns (uint256);
}