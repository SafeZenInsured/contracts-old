// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./IERC20.sol";

/**
 * @dev Interface for the optional mint and burnFrom functions from the ERC20 standard.
 */
interface IERC20Extended is IERC20 {
    
    function mint(address to, uint256 amount) external returns(bool);

    function burnFrom(address account, uint256 amount) external returns(bool);
}