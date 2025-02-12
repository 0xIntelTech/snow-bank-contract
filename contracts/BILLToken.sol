// ref_010325: https://<private>:<key>@github.com/0xLancerLab/snow_bank_masterchef
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./pancakeSwap/interfaces/IPancakeFactory.sol";
import "./pancakeSwap/interfaces/IPancakeRouter02.sol";

contract BILLToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
    using SafeMath for uint256;

    address public admin;
    uint256 private constant INITIAL_SUPPLY = 1000000000 * 10 ** 18;
    address public devAddress;
    address public marketAddress;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public startTime;
    uint256 public totalBurned;

    uint256 public staticTaxRate = 600;
    uint256 public constant duration = 1 days;

    mapping(address => bool) public isPair;
    mapping(address => bool) public proxylist;

    constructor(
        address _routerAddress,
        address _devAddress,
        address _marketAddress,
        address _wpls
    ) ERC20("TESTBANK.IO", "TEST222") ERC20Permit("TEST222") {
        admin = msg.sender;
        IPancakeRouter02 uniswapV2Router = IPancakeRouter02(_routerAddress);
        address WETH = _wpls;
        // Create a uniswap pair for this new token
        address pair = IPancakeFactory(uniswapV2Router.factory()).createPair(address(this), WETH);
        isPair[pair] = true;
        proxylist[_routerAddress] = true;
        startTime = block.timestamp;
        admin = msg.sender;
        devAddress = _devAddress;
        marketAddress = _marketAddress;
        _mint(msg.sender, INITIAL_SUPPLY);
        renounceOwnership(); // Renounce ownership
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function getCurrentTaxRate() public view returns (uint256) {
        return staticTaxRate;
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        require(_amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (isPair[_to] && !proxylist[_from]) {
            taxAmount = (_amount * getCurrentTaxRate()) / 10000;
        }
        uint256 netAmount = _amount - taxAmount;

        require(netAmount > 0, "Transfer amount after tax must be greater than zero");

        // If tax is applied, send it to the tax wallet and burns remainings
        if (taxAmount > 0) {
            uint256 tokenAmountForTreasury = taxAmount.mul(100).div(600);
            super._transfer(_from, devAddress, tokenAmountForTreasury);
            super._transfer(_from, marketAddress, tokenAmountForTreasury);
            _burn(_from, taxAmount - tokenAmountForTreasury - tokenAmountForTreasury);
        }

        // Transfer the remaining tokens
        super._transfer(_from, _to, netAmount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        totalBurned += amount;
        super._transfer(account, deadAddress, amount);
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setProxy(address _proxy) public {
        require(msg.sender == admin, "You are not the admin");
        require(isContract(_proxy), "only contracts can be whitelisted");
        proxylist[_proxy] = true;
    }

    function setPair(address _pair) public {
        require(msg.sender == admin, "You are not the admin");
        require(isContract(_pair), "only contracts can be whitelisted");
        isPair[_pair] = true;
    }

    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "You are not the admin");
        devAddress = _devAddress;
    }

    function setMarketAddress(address _marketAddress) public {
        require(msg.sender == marketAddress, "You are not the admin");
        marketAddress = _marketAddress;
    }
}
