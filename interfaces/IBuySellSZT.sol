// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IBuySellSZT {

    event BoughtSZT(address indexed userAddress, uint256 value);

    event SoldSZT(address indexed userAddress, uint256 value);

    event GSZTMint(address indexed userAddress, uint256 value);

    event GSZTBurn(address indexed userAddress, uint256 value);

    event TransferredSZT(address indexed from, address indexed to, uint256 value);

    event GSZTOwnershipTransferred(
        address indexed investorAddress, 
        address indexed newInvestorAddress, 
        uint256 value
    );

    function viewSZTCurrentPrice() view external returns(uint);

    function buySZTToken(uint256 _value) external returns(bool);

    function sellSZTToken(uint256 _value) external returns(bool);

    function getTokenCounter() external view returns(uint256);

    function calculateSZTPrice(
        uint256 issuedSZTTokens, 
        uint256 requiredTokens
    ) view external returns(uint, uint);

    function getSZTTokenCount() external view returns(uint256);
}