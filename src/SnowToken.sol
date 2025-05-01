// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libraries/AddressUtils.sol";  

contract SnowToken is ERC20, Ownable {
    using AddressUtils for address;  // Use the library for address type

    uint256 public sales_tax = 60; // 6% tax
    address public constant BURN_ADDRESS = address(0xdead);
    mapping(address => bool) public isPair;
    mapping(address => bool) public proxylist;
    mapping(address => bool) public authorized;

    modifier Authenticated() { 
        require(authorized[msg.sender], "No authorized");
        _;
    }

    constructor() ERC20("T SNOW BANK", "tSNOW") Ownable(msg.sender) {
        authorized[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transferWithTax(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _spendAllowance(sender, msg.sender, amount);
        return _transferWithTax(sender, recipient, amount);
    }

    function _transferWithTax(address sender, address recipient, uint256 amount) internal returns (bool) {

        if (!proxylist[sender] && isPair[recipient]) {
            uint256 taxAmount = (amount * sales_tax) / 1000;
            uint256 netAmount = amount - taxAmount;
            _transfer(sender, BURN_ADDRESS, taxAmount);
            _transfer(sender, recipient, netAmount);            
        } else {
            _transfer(sender, recipient, amount);
        }
        return true;
    }

    function setTax(uint _tax) public onlyOwner {
        sales_tax = _tax;
    }    

    function setPair(address _pair, bool _value) public onlyOwner {
        require(_pair.isContract(), "Address is not a contract, only contract addresses can be whitelisted");
        isPair[_pair] = _value;
    }    

    function setProxy(address _proxy, bool _value) public onlyOwner {
        require(_proxy.isContract(), "Address is not a contract, only contract addresses can be whitelisted");
        proxylist[_proxy] = _value;
    }

    function setAuthorized(address _addr, bool _val) public onlyOwner {
        authorized[_addr] = _val;
    }

    function mint(address to, uint256 amount) external Authenticated {
        _mint(to, amount);
    }
}
