
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISnowToken is IERC20 {
    function sales_tax() external view returns (uint256);
    function BURN_ADDRESS() external pure returns (address);
    function mint(address to, uint256 amount) external;    
}