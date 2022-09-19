// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuySellSZT {

    event BoughtSZT(address indexed to, uint256 value);

    event SoldSZT(address indexed from, uint256 value);

    event TransferredSZT(address indexed from, address indexed to, uint256 value);

    function viewSZTCurrentPrice() view external returns(uint);

    function buySZTToken(uint256 _value) external returns(bool);

    function activateSellTimer(uint256 _value) external returns(bool);

    function sellSZTToken(uint256 _value) external returns(bool);

    function transferSZT(address _from, address _to, uint _value) external returns(bool);

    function tokenCounter() external view returns(uint256);

    function calculateSZTPrice(uint256 issuedSZTTokens, uint256 requiredTokens) view external returns(uint, uint);

    function getSZTTokenCount() external view returns(uint256);

    function stakingTransferSZT(address _from, address _to, uint _value) external returns(bool);
}