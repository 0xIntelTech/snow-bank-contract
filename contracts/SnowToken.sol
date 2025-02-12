// ref_010325: forked from admin: ../legacy/Snow_Bank_MasterChef-main.zip
// ref_010625: merged latest dev source: github.com/0xLancerLab/snow_bank_masterchef.git
// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.15;
pragma solidity ^0.8.20;
import "./node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./node_modules/@openzeppelin/contracts/access/Ownable.sol";
// import "./node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol"; // house: legacy using 'draft-ERC20Permit.sol'
import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "./node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol"; // house: is votes (from legacy) needed for snowtoken?
import "./pancakeSwap/interfaces/IPancakeFactory.sol";
import "./pancakeSwap/interfaces/IPancakeRouter02.sol";

import "./ISnowLib.sol";

// contract SNOWToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
contract SnowToken is ERC20, Ownable {
    using SafeMath for uint256;

    /* -------------------------------------------------------- */
    /* GLOBALS - house
    /* -------------------------------------------------------- */
    string public tVERSION = '0.5';   
    bool private FIRST_ = true;
    address public ADDR_CONF; // set via CONF_setConfig
    ISnowConfig private CONF; // set via CONF_setConfig

    string private TOK_SYMB = string(abi.encodePacked("tSNOW", tVERSION));
    string private TOK_NAME = string(abi.encodePacked("tSNOWBANK_", tVERSION));

    address public ADDR_INIT_PAIR; // note: first pulsex pair created in constructor
    address public constant ADDR_PULSEX_V2 = address(0x165C3410fC91EF562C50559f7d2289fEbed552d9); // pulsex router_v2
    address public constant ADDR_WPLS = address(0xA1077a294dDE1B09bB078844df40758a5D0f9a27);

    /* -------------------------------------------------------- */
    /* GLOBALS - legacy
    /* -------------------------------------------------------- */
    // address public admin; // house_010325: switching to owner control
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public totalBurned;

    uint256 public staticTaxRate = 600;
    // uint256 public MAX_TAX_RATE = 1200; // house_010625: part of legacy cool down algorithm
    // uint256 public constant duration = 1 days; // house_010625: part of legacy cool down algorithm

    mapping(address => bool) public isPair;
    mapping(address => bool) public proxylist;

    // constructor(
    //     address _routerAddress,
    //     address _wpls
    // ) ERC20("TESTBANK.IO", "TEST111") ERC20Permit("TEST111") {
    //     admin = msg.sender;
    //     IPancakeRouter02 uniswapV2Router = IPancakeRouter02(_routerAddress);
    //     address WETH = _wpls;
    //     // Create a uniswap pair for this new token
    //     address pair = IPancakeFactory(uniswapV2Router.factory()).createPair(address(this), WETH);
    //     isPair[pair] = true;
    //     proxylist[_routerAddress] = true;
    //     admin = msg.sender;
    // }

    // house_010625
    // constructor() ERC20("TESTBANK.IO", "TEST111") ERC20Permit("TEST111") {
    constructor() ERC20(TOK_NAME, TOK_SYMB) Ownable(msg.sender) { // house: missing owner constructor

        // Create a uniswap pair for this new token
        IPancakeRouter02 uniswapV2Router = IPancakeRouter02(ADDR_PULSEX_V2);
        address pair = IPancakeFactory(uniswapV2Router.factory()).createPair(address(this), ADDR_WPLS);
        isPair[pair] = true; // set pair to tax
        proxylist[ADDR_PULSEX_V2] = true; // set pair router as proxy (not tax i think)

        // set initial tax rates
        staticTaxRate = 600; // 6% tax rate
        // MAX_TAX_RATE = 1200; // house_010625: part of legacy cool down algorithm
        
        // house_010625: legacy code was already creating pair with no initial liqiduity ^
        //  but not storing the initial pair address (hence, added global ADDR_INIT_PAIR)
        ADDR_INIT_PAIR = pair;
    }

    /* -------------------------------------------------------- */
    /* MODIFIERS - house
    /* -------------------------------------------------------- */
    modifier onlyKeeper() {
        require(msg.sender == CONF.KEEPER(), "!keeper :p");
        _;
    }
    modifier onlyChef() { 
        require(msg.sender == CONF.KEEPER() || msg.sender == CONF.ADDR_CHEF(), " not chef :p");
        _;
    }

    modifier onlyConfig() { 
        // allows 1st onlyConfig attempt to freely pass
        //  NOTE: don't waste this on anything but CONF_setConfig
        // if (!FIRST_) 
        //     require(msg.sender == address(ADDR_CONF), ' !CONF :/ ');
        // FIRST_ = false;
        // _;

        if (!FIRST_) {
            require(msg.sender == address(CONF), ' !CONF :p '); // first validate CONF
            _; // then proceed to set CONF++
        } else {
            FIRST_ = false; // never again
            _; // first proceed to set CONF++
            // house_010325: initial mint to static EOA
            _mint(CONF.ADDR_TREAS_EOA(), 1000000 * 10**uint8(decimals()));
        } 
    }
    function CONF_setConfig(address _conf) external onlyConfig() {
        require(_conf != address(0), ' !addy :< ');
        ADDR_CONF = _conf;
        CONF = ISnowConfig(ADDR_CONF);
    }

    /* -------------------------------------------------------- */
    /* PRIVATE - ownable overrides - timelock support
    /* -------------------------------------------------------- */
    // override Owanable to consolidate support to SnowConfig (CONF)
    function _checkOwner() internal view override {
        if (CONF.owner() != msg.sender && msg.sender != CONF.ADDR_TIMELOCK() && msg.sender != CONF.KEEPER()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
    
    /* -------------------------------------------------------- */
    /* MUTATORS - legacy - admin
    /* -------------------------------------------------------- */
    // house_010325: changed onlyOwner to onlyChef (only MasterChef should be able to mint; algorithmically)
    function mint(address to, uint256 amount) external onlyChef {
        _mint(to, amount);
    }

    // function _mint(address to, uint256 amount) internal override (ERC20, ERC20Votes) {
    function _mint(address to, uint256 amount) internal override (ERC20) { // house: is votes needed for snowtoken
        super._mint(to, amount);
    }


    /* -------------------------------------------------------- */
    /* ACCESSORS - legacy - public
    /* -------------------------------------------------------- */
    function getCurrentTaxRate() public view returns (uint256) {
        return staticTaxRate;
    }
    // legacy Snow_Bank_MasterChef-main.zip (includes cool down algo)
    // function getCurrentTaxRate() public view returns (uint256) {
    //     for (uint256 i = 0; i < 30; i++) {
    //         if (block.timestamp <= startTime + duration * i) {
    //             uint256 tax = MAX_TAX_RATE - (i - 1) * 200;
    //             return tax < staticTaxRate ? staticTaxRate : tax;
    //         }
    //     }
    //     return staticTaxRate;

    //     // admin (TG _ 010525): algorithim describing cooldown tax (^using MAX_TAX_RATE and starttime and duration)
    //     //  So big picture snowbank is a variation of a simple yieldcoin. 
    //     //  I do want the "cooldown tax" hard-coded. 
    //     //  It should start at 12% and drop 1% a day until it hits 6% then stay there. 
    //     //  SNOW will run itself (I can maintain emissions) while dev focus should be on immediate testing on more chains
    // }

    /* -------------------------------------------------------- */
    /* PRIVATE - legacy
    /* -------------------------------------------------------- */
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
            _burn(_from, taxAmount);
        }

        // Transfer the remaining tokens
        super._transfer(_from, _to, netAmount);
    }

    // house: non-active
    //  if needed: update latest version of "./node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol"
    // function _afterTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 amount
    // ) internal override(ERC20, ERC20Votes) {
    //     super._afterTokenTransfer(from, to, amount);
    // }

    // function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    function _burn(address account, uint256 amount) internal override(ERC20) { // house: is votes needed for snowtoken
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

    /* -------------------------------------------------------- */
    /* MUTATORS - legacy - admin
    /* -------------------------------------------------------- */
    function setProxy(address _proxy) public onlyOwner {
        // require(msg.sender == admin, "You are not the admin"); // house_010325: switching to owner control
        require(_proxy != address(0), "Cannot whitelist zero address");
        require(isContract(_proxy), "only contracts can be whitelisted");
        proxylist[_proxy] = true;
    }

    function setPair(address _pair) public onlyOwner {
        // require(msg.sender == admin, "You are not the admin"); // house_010325: switching to owner control
        require(isContract(_pair), "only contracts can be whitelisted");
        isPair[_pair] = true;
    }

    /* -------------------------------------------------------- */
    /* MUTATORS - legacy - admin (Snow_Bank_MasterChef-main.zip)
    /* -------------------------------------------------------- */
    // house_010625: part of cool down algorithm
    // function setMaxTaxRate(uint256 _newMaxRate) external onlyOwner {
    //     require(_newMaxRate > staticTaxRate, "Invalid Max Tax Rate");
    //     MAX_TAX_RATE = _newMaxRate;
    // }

    function setStaticTaxRate(uint256 _newStaticRate) external onlyOwner {
        require(_newStaticRate > 0, "Invalid Static Tax Rate");
        staticTaxRate = _newStaticRate;
    }
}
