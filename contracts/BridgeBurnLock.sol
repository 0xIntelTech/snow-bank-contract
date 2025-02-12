// ref: chatgpt_011325
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BridgeLock {
    event AssetLocked(address indexed user, uint256 amount, uint256 nonce);

    mapping(uint256 => bool) public processedNonces;

    function lockTokens(uint256 amount, uint256 nonce) external payable {
        require(!processedNonces[nonce], "Nonce already processed");
        processedNonces[nonce] = true;

        // Lock tokens (for simplicity, assume tokens are native chain currency)
        require(msg.value == amount, "Incorrect token amount sent");

        emit AssetLocked(msg.sender, amount, nonce);
    }
}
