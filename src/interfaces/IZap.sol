
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IZap {
    function zapIn(
        uint poolId,
        uint256 amountInETH,
        bool isWETH
    ) external payable;

    function swapTokens(
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOutMin
    ) external payable returns (uint256);
}