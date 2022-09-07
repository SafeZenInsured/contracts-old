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
}