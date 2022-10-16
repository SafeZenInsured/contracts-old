// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

interface IAAVEERC20 {
    // minting fake tokens for testnet purpose
    function mint(uint256 value) external returns (bool);

    function name() external view returns (string memory);

    // minting fake tokens to given account address for testnet purpose
    function mint(address account, uint256 value) external returns (bool); 

    // returns balance of the tokens
    function balanceOf(address account) external returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function approve(address account, uint256 amount) external returns (bool);

}