// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakePair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
}