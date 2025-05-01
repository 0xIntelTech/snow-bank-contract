pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(uint256 initialSupply) ERC20("MockToken", "MTK") {
        _mint(msg.sender, initialSupply);  // Mint initial supply to the sender
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
