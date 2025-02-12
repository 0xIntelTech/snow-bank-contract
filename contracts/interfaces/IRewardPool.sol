// SPDX-License-Identifier: UNLICENSED











pragma solidity ^0.8.15;
// Part: IRewardPool

interface IRewardPool {
    // function depositFor(uint256 _pid, uint256 _amount÷, address _recipient) external; // legacy
    function depositFor(uint256 _pid, uint256 _amount, address _recipient, address _promotor, string calldata _urn) external; // house_010825: promo free deposit support
    
}