// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IAAVE {
    // to supply the tokens to AAVE smart contract
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function supplyWithPermit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode, uint256 deadline, uint8 permitV, bytes32 permitR, bytes32 permitS) external;

    function withdraw(address asset, uint256 amount, address to) external;

    function claimRewards(address[] memory assets, uint256 amount, address to, address reward) external;

}