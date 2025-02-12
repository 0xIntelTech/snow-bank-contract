// SPDX-License-Identifier: UNLICENSED
// ref: https://ethereum.org/en/history
//  code size limit = 24576 bytes (a limit introduced in Spurious Dragon _ 2016)
//  code size limit = 49152 bytes (a limit introduced in Shanghai _ 2023)
// model ref: LUSDST.sol (081024)
// NOTE: uint type precision ...
//  uint8 max = 255
//  uint16 max = ~65K -> 65,535
//  uint32 max = ~4B -> 4,294,967,295
//  uint64 max = ~18,000Q -> 18,446,744,073,709,551,615
pragma solidity ^0.8.24;

import "./node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./ISnowLib.sol";

interface ISetConfig {
    function CONF_setConfig(address _conf) external;
}
contract SnowConfig is Ownable {
    // address public constant TOK_WPLS = address(0xA1077a294dDE1B09bB078844df40758a5D0f9a27);
    // address public constant BURN_ADDR = address(0x0000000000000000000000000000000000000369);
    
    /* -------------------------------------------------------- */
    /* ADMIN SUPPORT 
    /* -------------------------------------------------------- */
    address public KEEPER;
    uint256 private KEEPER_CHECK; // misc key, set to help ensure no-one else calls 'KEEPER_collectiveStableBalances'
    string public constant tVERSION = '0.4';   

    // EOAs
    address private dev_ = address(0xEEd80539c314db19360188A66CccAf9caC887b22); // test (move to config?)
    address public ADDR_TREAS_EOA = dev_;
    address public ADDR_DEV_EOA = dev_;
    // address public ADDR_TREAS_EOA = address(0xF5F3b513b77182D83010dbe49C90EBDfF60e9964); // admin_010325 (move to config?)
    // address public ADDR_DEV_EOA = address(0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7); // admin_010325 (move to config?)
    // address public ADDR_FEE_EOA = address(0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40); // admin_010325 (move to config?)

    // contracts
    // address public ADDR_CONF = address(0x790C736Fd431420086a2b4C9505BADAf0676B8B9); // SnowConfig v0.4 (commented out)
    address public ADDR_CHEF = address(0x520E7c83B0859FC6915AcC75A7b4d4FD256F97FA); // MasterChef v0.5
    address public ADDR_ZAP = address(0x983389Eee6Bb76419b0176d64E1dB8191213A0B5); // ZapV3 v0.4
    address public ADDR_SNOW = address(0xdc318Ea55e15Fd480a7c9baEc6d957Cf602b5063); // SnowToken v0.5
    address public ADDR_SNOWNFT = address(0x2160B8BeeE78b71B5995245CCCd36b8D9E57ED56); // SnowNFT v0.2
    address public ADDR_TIMELOCK = address(0x97350f425ABa6554fb1bF879D98830C13A7A9819); // SnowTimelock v0.1
    address public ADDR_LIB = address(0x3e833F280b223CDaBDb52a16d8cf45A83B757d77); // SnowLib v0.2

    // configs used in this contract
    IMasterChef private CHEF = IMasterChef(ADDR_CHEF);
    // IZap private ZAP = IZap(ADDR_ZAP);
    // ISnowToken private SNOW = ISnowToken(ADDR_SNOW);
    ISnowNFT private SNOWNFT = ISnowNFT(ADDR_SNOWNFT);
    ISnowTimelock private TIMELOCK = ISnowTimelock(ADDR_TIMELOCK);
    ISnowLib private LIB = ISnowLib(ADDR_LIB);

    /* -------------------------------------------------------- */
    /* GLOBALS - settings/config
    /* -------------------------------------------------------- */
    address[] public USWAP_V2_ROUTERS; // NOTE: private is more secure (legacy) consider KEEPER getter
    address[] public WHITELIST_USD_STABLES; // NOTE: private is more secure (legacy) consider KEEPER getter
    address[] public USD_STABLES_HISTORY; // NOTE: private is more secure (legacy) consider KEEPER getter

    // admin: promotor / referral support
    uint16 public PROMO_PERC_SNOW_REWARD; // 10000 = 100.00% _ promotors receive % of each referal $SNOW earnings;
    uint8 public PROMO_NUM_FREE_DEPOSITS; // number of deposits before fees are charged
    bool public PROMO_REWAR_MINT_ENABLED; // true = rewards minted, false = rewards sub from user snow earns (safeSNOWTransfer)
        // LEFT OFF HERE ... needs setters ^^^
    
    // legacy...
    // SNOW tokens created per block.
    uint256 public SNOWPerBlock = 0; // house_011225: migrated to SnowConfig
    // mapping(address => uint64) public PROMO_USD_OWED; // maps promo code HASH to usd owed for that hash
    // mapping(address => ISnowLib.PROMO) public HASH_PROMO; // store promo code hashes to their PROMO mapping
    // mapping(address => address[]) public PROMOTOR_HASHES; // map promo code list to their promotor

    /* -------------------------------------------------------- */
    /* GLOBALS - storage
    /* -------------------------------------------------------- */
    // storage: promotor / referral support
    mapping(address => ISnowLib.PROMO) public PROMOTOR_PROMO; // map promotor to their PROMO 
    mapping(string => ISnowLib.PROMO) public URN_PROMO; // map custom URN to their PROMO 
    mapping(address => ISnowLib.FREE_DEPOSIT) public USER_FREE_DEP; // map user EOA to their FREE_DEPOSIT

    // timelock support
    bytes32[] public QUEUED_TIMELOCK_HASHES; // track all queued tx hashes in timelock support

    /* -------------------------------------------------------- */
    /* CONSTRUCTOR
    /* -------------------------------------------------------- */
    constructor() Ownable(msg.sender) {
        // note: Ownable only used in delegate contracts, via CONF.owner()
        KEEPER = msg.sender; // set KEEPER

        // add default whiteliste stable: weDAI
        _editWhitelistStables(address(0xefD766cCb38EaF1dfd701853BFCe31359239F305), true); // weDAI, true = add

        // add default routers: pulsex (x2)
        // _editDexRouters(address(0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02), address(0x1715a3E4A142d8b698131108995174F37aEBA10D), true); // pulseX v1, true = add
        // _editDexRouters(address(0x165C3410fC91EF562C50559f7d2289fEbed552d9), address(0x29eA7545DEf87022BAdc76323F373EA1e707C523), true); // pulseX v2, true = add
        _editDexRouters(address(0x165C3410fC91EF562C50559f7d2289fEbed552d9), true); // pulseX v2, true = add
            // NOTE: bug_fix_082724
            //  pulseX v1 was causing a failure when trying to swap 3000 PLS for ~1.04 weDAI
            //      the swap function kept returning 0 as amountsOut (or something like that)
            //  but pulseX v2 seems to be working fine
            //      tried 2 times with 3_000 and 30_000 PLS (both went through fine)
            //  *WARNING* should keep an eye on this

        // NOTE: ref pc dex addresses
        // ROUTER_pulsex_router02_v1='0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02' # PulseXRouter02 'v1' ref: https://www.irccloud.com/pastebin/6ftmqWuk
        // FACTORY_pulsex_router_02_v1='0x1715a3E4A142d8b698131108995174F37aEBA10D'
        // ROUTER_pulsex_router02_v2='0x165C3410fC91EF562C50559f7d2289fEbed552d9' # PulseXRouter02 'v2' ref: https://www.irccloud.com/pastebin/6ftmqWuk
        // FACTORY_pulsex_router_02_v2='0x29eA7545DEf87022BAdc76323F373EA1e707C523'
    }

    /* -------------------------------------------------------- */
    /* MODIFIERS - house
    /* -------------------------------------------------------- */
    modifier onlyKeeper() {
        require(msg.sender == KEEPER, "!keeper :p");
        _;
    }
    modifier onlyChef() {
        require(msg.sender == KEEPER || msg.sender == ADDR_CHEF, " not chef :p");
        _;
    }
    modifier onlyDev() {
        require(msg.sender == KEEPER || msg.sender == ADDR_DEV_EOA || msg.sender == ADDR_TIMELOCK, " not dev :p");
        _;
    }
    modifier onlyTreas() {
        require(msg.sender == KEEPER || msg.sender == ADDR_TREAS_EOA || msg.sender == ADDR_TIMELOCK, " not treas :p");
        _;
    }

    /* -------------------------------------------------------- */
    /* PUBLIC - admin - timelock support
    /* -------------------------------------------------------- */
    function getQueuedTxForHashOrAll(bytes32 _txHash, bool _all) public view returns(ISnowTimelock.TX_SET[] memory) {
        ISnowTimelock.TX_SET[] memory retTxSet;
        if (!_all) {
            retTxSet = new ISnowTimelock.TX_SET[](1);
            retTxSet[0] = TIMELOCK.queuedTransactions(_txHash);
        } else {
            retTxSet = new ISnowTimelock.TX_SET[](QUEUED_TIMELOCK_HASHES.length);
            for(uint i = 0; i < QUEUED_TIMELOCK_HASHES.length;) {
                retTxSet[i] = TIMELOCK.queuedTransactions(QUEUED_TIMELOCK_HASHES[i]);
                unchecked {
                    i++;
                }
            }            
        }
        return retTxSet;
    }
    function cancelTimelock(bytes32 _txHash) public onlyTreas {
        require(TIMELOCK.queuedTransactions(_txHash).target != address(0), "tx not found");
        TIMELOCK.cancelTransaction(
            TIMELOCK.queuedTransactions(_txHash).target,
            TIMELOCK.queuedTransactions(_txHash).value,
            TIMELOCK.queuedTransactions(_txHash).signature,
            TIMELOCK.queuedTransactions(_txHash).data,
            TIMELOCK.queuedTransactions(_txHash).eta
        );
        QUEUED_TIMELOCK_HASHES = LIB.remBytes32FromArray(_txHash, QUEUED_TIMELOCK_HASHES);
    }
    function executeTx(bytes32 _txHash) public onlyTreas {
        require(TIMELOCK.queuedTransactions(_txHash).target != address(0), "tx not found");
        TIMELOCK.executeTransaction(
            TIMELOCK.queuedTransactions(_txHash).target,
            TIMELOCK.queuedTransactions(_txHash).value,
            TIMELOCK.queuedTransactions(_txHash).signature,
            TIMELOCK.queuedTransactions(_txHash).data,
            TIMELOCK.queuedTransactions(_txHash).eta
        );
        QUEUED_TIMELOCK_HASHES = LIB.remBytes32FromArray(_txHash, QUEUED_TIMELOCK_HASHES);
    }
    function queueTx_NFT_setPriceAddressDAI(uint256 _daiBuyPrice, address _daiAddress, uint32 _secWait) external onlyTreas {
        // set params of function to call
        address target = address(this); // The address of the NFT contract
        uint value = 0; // No Ether is sent with this transaction
        string memory signature = "NFT_setPriceAddressDAI(uint256,address)";
        bytes memory data = abi.encode(_daiBuyPrice, _daiAddress); // Encode the parameters
        uint eta = block.timestamp + _secWait; // Set the execution time w/ seconds from now

        // queue tx to execute this function later
        bytes32 txHash = TIMELOCK.queueTransaction(target, value, signature, data, eta);

        // log tx to be referenced publicly (get deleted on execution)
        QUEUED_TIMELOCK_HASHES = LIB.addBytes32ToArraySafe(txHash, QUEUED_TIMELOCK_HASHES, true); // true = no dups
    }
    function queueTx_updateEmissionRate(uint256 _SNOWPerBlock, uint32 _secWait) external onlyTreas {
        // set params of function to call
        address target = address(this); // The address of this contract
        uint value = 0; // No Ether is sent with this transaction
        string memory signature = "updateEmissionRate(uint256)";
        bytes memory data = abi.encode(_SNOWPerBlock); // Encode the parameters
        uint eta = block.timestamp + _secWait; // Set the execution time w/ seconds from now

        // queue tx to execute this function later
        bytes32 txHash = TIMELOCK.queueTransaction(target, value, signature, data, eta);

        // log tx to be referenced publicly (get deleted on execution)
        QUEUED_TIMELOCK_HASHES = LIB.addBytes32ToArraySafe(txHash, QUEUED_TIMELOCK_HASHES, true); // true = no dups
    }
    function queueTx_setDev(address _devAddress, uint32 _secWait) external onlyDev {
        // set params of function to call
        address target = address(this); // The address of this contract
        uint value = 0; // No Ether is sent with this transaction
        string memory signature = "setDev(address)";
        bytes memory data = abi.encode(_devAddress); // Encode the parameters
        uint eta = block.timestamp + _secWait; // Set the execution time w/ seconds from now

        // queue tx to execute this function later
        bytes32 txHash = TIMELOCK.queueTransaction(target, value, signature, data, eta);

        // log tx to be referenced publicly (get deleted on execution)
        QUEUED_TIMELOCK_HASHES = LIB.addBytes32ToArraySafe(txHash, QUEUED_TIMELOCK_HASHES, true); // true = no dups
    }
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function queueTx_add( // MasterChef.add(...)
        uint256 _allocPoint,
        address _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate,
        bool _isNFTPool,
        uint32 _secWait
    ) public onlyTreas {
        // check requirements
        require(_depositFeeBP <= 1000, "add: invalid deposit fee basis points"); // MasterChef.add(...)

        // set params of function to call
        address target = address(ADDR_CHEF); // The address of the MasterChef contract
        uint value = 0; // No Ether is sent with this transaction
        string memory signature = "add(uint256,address,uint16,bool,bool)";
        bytes memory data = abi.encode(_allocPoint, _lpToken, _depositFeeBP, _withUpdate, _isNFTPool); // Encode the parameters
        uint eta = block.timestamp + _secWait; // Set the execution time w/ seconds from now

        // queue tx to execute this function later
        bytes32 txHash = TIMELOCK.queueTransaction(target, value, signature, data, eta);

        // log tx to be referenced publicly (get deleted on execution)
        QUEUED_TIMELOCK_HASHES = LIB.addBytes32ToArraySafe(txHash, QUEUED_TIMELOCK_HASHES, true); // true = no dups
    }
    // Update the given pool's SNOW allocation point and deposit fee. Can only be called by the owner.
    function queueTx_set( // MasterChef.set(...)
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint256 _startBlock,
        bool _withUpdate,
        uint32 _secWait
    ) public onlyTreas {
        // check requirements
        require(_depositFeeBP <= 1000, "set: invalid deposit fee basis points"); // MasterChef.set(...)
        require(_allocPoint < 10000, "set: invalid alloc point basis points"); // MasterChef.set(...)

        // set params of function to call
        address target = address(ADDR_CHEF); // The address of the MasterChef contract
        uint value = 0; // No Ether is sent with this transaction
        string memory signature = "set(uint256,uint256,uint16,uint256,bool)";
        bytes memory data = abi.encode(_pid, _allocPoint, _depositFeeBP, _startBlock, _withUpdate); // Encode the parameters
        uint eta = block.timestamp + _secWait; // Set the execution time w/ seconds from now

        // queue tx to execute this function later
        bytes32 txHash = TIMELOCK.queueTransaction(target, value, signature, data, eta);

        // log tx to be referenced publicly (get deleted on execution)
        QUEUED_TIMELOCK_HASHES = LIB.addBytes32ToArraySafe(txHash, QUEUED_TIMELOCK_HASHES, true); // true = no dups
    }

    /* -------------------------------------------------------- */
    /* PUBLIC - admin mutators
    /* -------------------------------------------------------- */
    function updateEmissionRate(uint256 _SNOWPerBlock) public onlyTreas {
        CHEF.massUpdatePools();
        SNOWPerBlock = _SNOWPerBlock;

        // house_011225: this function migrated from legacy MasterChef.sol
        //  order of execution was indeed maintained (ie. massUpdatePools() first, then SNOWPerBlock update)
        //   i DO NOT think this is a bug, but rather a feature (to ensure all pools are updated before new SNOWPerBlock)
    }
    function NFT_setPriceAddressDAI(uint256 _daiBuyPrice, address _daiTokenAddr) external onlyTreas {
        require(_daiBuyPrice > 0 && _daiTokenAddr != address(0), ' bad inputs :/ ');
        SNOWNFT.setNFTPrice(_daiBuyPrice);
        SNOWNFT.setDAIAddress(_daiTokenAddr);
    }
    function setDev(address _devAddress) external onlyDev {
        // require(msg.sender == ADDR_DEV_EOA, "dev: wut?");
        ADDR_DEV_EOA = _devAddress;
    }
    // Update dev address by the previous dev.
    function setTreasury(address _treasAddress) external onlyTreas {
        // require(msg.sender == ADDR_TREAS_EOA, "treasury: wut?");
        ADDR_TREAS_EOA = _treasAddress;
    }
    function addNewPromotor(ISnowLib.PROMO memory _promo) external onlyChef {
        // validate input promo struct initialized correctly
        require(_promo.promotor != address(0), ' no promotor :/ '); 

        // validate is new promotor (not already exists in PROMOTOR_PROMO nor URN_PROMO)
        require(!_promotorExistsForPromo(_promo), ' not new promotor :/ ');
        require(!_promoUrnExistsForPromo(_promo), ' not new URN :/ ');

        // add new promotor
        PROMOTOR_PROMO[_promo.promotor] = _promo;
        URN_PROMO[_promo.customURN] = _promo;
    }
    function attemptUseFreeDeposit(address _promotor, string memory _customURN, address _user) external onlyChef returns(bool) {
        // NOTE: _promotor takes priority (if found) over _customURN

        // validate promo exists
        if (!promotorExists(_promotor) && !promoUrnExists(_customURN)) return false; // no promo exists (return false)

        // get promo to validate if user has free deposits in
        ISnowLib.PROMO memory promo;
        if (promotorExists(_promotor)){
            promo = PROMOTOR_PROMO[_promotor];
        } else {
            promo = URN_PROMO[_customURN];
        }

        // validate free deposit exists (if not, create new)
        ISnowLib.FREE_DEPOSIT memory freeDep = USER_FREE_DEP[_user];
        if (freeDep.promotor == address(0)) { // user has no free deposit YET
            // create new FREE_DEPOSIT
            freeDep = ISnowLib.FREE_DEPOSIT({
                user: _user, // EOA who used a promo on deposit
                promotor: promo.promotor, // promo / influencer wallet that was used
                snowDeposited: 0, // cumulative amount of $SNOW deposited by user (if possible)
                freeDepositCnt: 0, // # of free deposits this user has used (default 0, increment to PROMO.numFreeDepPerUsr)
                blockTimestamp: block.timestamp,
                blockNumber: block.number
            });

            USER_FREE_DEP[_user] = freeDep; // write
        }

        // check if user has free deposits remaining (if so, increment + return true)
        if (freeDep.freeDepositCnt < promo.numFreeDepPerUsr) {
            freeDep.freeDepositCnt++; // increment deposit count
            USER_FREE_DEP[_user] = freeDep; // write
            return true; // return true if user used a free deposit
        }

        return false; // no free deposit used
    }
    function calcPromoRewardFromUserAmount(address _user, uint256 _amount) external view onlyChef returns(uint256, address) {
        uint256 promoRewardSNOW; // return value
        ISnowLib.FREE_DEPOSIT memory freeDep = USER_FREE_DEP[_user];
        if (freeDep.promotor != address(0)) { // validate _user has a promotor
            ISnowLib.PROMO memory promo = PROMOTOR_PROMO[freeDep.promotor];
            if (promo.promotor != address(0)) { // validate promo exists
                // if so, calc the reward to return & either mint or sub from user's _amount (admin controlled)
                promoRewardSNOW = LIB._perc_of_uint256(promo.percReward, _amount);
            }
        }
        return (promoRewardSNOW, freeDep.promotor);
    }

    /* -------------------------------------------------------- */
    /* PUBLIC - acessors
    /* -------------------------------------------------------- */
    function promotorExists(address _promotor) public view returns(bool) {
        if (_promotor == address(0)) return false;
        return PROMOTOR_PROMO[_promotor].promotor != address(0);
    }
    function promoUrnExists(string memory _customURN) public view returns(bool) {
        if (bytes(_customURN).length < 2) return false;
        return URN_PROMO[_customURN].promotor != address(0);
    }

    /* -------------------------------------------------------- */
    /* PRIVATE - supporting
    /* -------------------------------------------------------- */
    function _promotorExistsForPromo(ISnowLib.PROMO memory _promo) private view returns(bool) {
        // return true if promotor already exists in PROMOTOR_PROMO
        return PROMOTOR_PROMO[_promo.promotor].promotor != address(0);
    }
    function _promoUrnExistsForPromo(ISnowLib.PROMO memory _promo) private view returns(bool) {
        // return true if promotor already exists in PROMOTOR_PROMO
        return URN_PROMO[_promo.customURN].promotor != address(0);
    }

    /* -------------------------------------------------------- */
    /* PUBLIC - KEEPER
    /* -------------------------------------------------------- */
    function KEEPER_maintenance(address _erc20, uint256 _amount) external onlyKeeper() {
        if (_erc20 == address(0)) { // _erc20 not found: tranfer native PLS instead
            require(address(this).balance >= _amount, " Insufficient native PLS balance :[ ");
            payable(KEEPER).transfer(_amount); // cast to a 'payable' address to receive ETH
            // emit KeeperWithdrawel(_amount);
        } else { // found _erc20: transfer ERC20
            //  NOTE: _amount must be in uint precision to _erc20.decimals()
            require(IERC20(_erc20).balanceOf(address(this)) >= _amount, ' not enough amount for token :O ');
            IERC20(_erc20).transfer(KEEPER, _amount);
            // emit KeeperMaintenance(_erc20, _amount);
        }
    }
    function KEEPER_setKeeper(address _newKeeper, uint16 _keeperCheck) external onlyKeeper {
        require(_newKeeper != address(0), 'err: 0 address');
        // address prev = address(KEEPER);
        KEEPER = _newKeeper;
        if (_keeperCheck > 0)
            KEEPER_CHECK = _keeperCheck;
        // emit KeeperTransfer(prev, KEEPER);
    }
    function KEEPER_setContracts(address _lib, address _chef, address _SNOW, address _NFT, address _TIMELOCK, address _ZAP, address _conf) external onlyKeeper {
        // EOA may indeed send 0x0 to "opt-in" for changing _conf address in support contracts
        //  if no _conf, update support contracts w/ current CONFIG address
        if (    _chef != address(0)) ADDR_CHEF = _chef;
        if (     _ZAP != address(0)) ADDR_ZAP = _ZAP; 
        if (    _SNOW != address(0)) ADDR_SNOW = _SNOW; 
        if (     _NFT != address(0)) ADDR_SNOWNFT = _NFT; 
        if (_TIMELOCK != address(0)) ADDR_TIMELOCK = _TIMELOCK; 
        if (     _lib != address(0)) ADDR_LIB = _lib;
        if (    _conf == address(0)) _conf = address(this);

        // update contract configs
        //  note: make sure everything is set & done (above) before updating
        ISetConfig(ADDR_CHEF).CONF_setConfig(_conf);
        ISetConfig(ADDR_ZAP).CONF_setConfig(_conf);
        ISetConfig(ADDR_SNOW).CONF_setConfig(_conf);
        ISetConfig(ADDR_SNOWNFT).CONF_setConfig(_conf);
        ISetConfig(ADDR_TIMELOCK).CONF_setConfig(_conf);
        // ISetConfig(ADDR_LIB).CONF_setConfig(_conf); // not in lib.sol
        

        // reset configs used in this contract
        CHEF = IMasterChef(ADDR_CHEF); 
        // ZAP = IZap(ADDR_ZAP);
        // SNOW = ISnowToken(ADDR_SNOW);
        SNOWNFT = ISnowNFT(ADDR_SNOWNFT);
        TIMELOCK = ISnowTimelock(ADDR_TIMELOCK);
        LIB = ISnowLib(ADDR_LIB);
    }

    /* -------------------------------------------------------- */
    /* PUBLIC - SUPPORTING native token sent to contract
    /* -------------------------------------------------------- */
    fallback() external payable {
        // executes if:
        //  function invoked doesn't exist
        //   or ETH received w/ data 
        //   or ETH received w/o data & no receive() exists
        
        // fwd any PLS recieved to treasury
        payable(ADDR_TREAS_EOA).transfer(msg.value);

        // legacy: fwd any PLS recieved to VAULT (convert to USD stable & process deposit)
        // ICallitVault(ADDR_VAULT).deposit{value: msg.value}(msg.sender);
    }

    /* -------------------------------------------------------- */
    /* PRIVATE SUPPORTING
    /* -------------------------------------------------------- */
    function _editWhitelistStables(address _usdStable, bool _add) private { // allows duplicates
        if (_add) {
            WHITELIST_USD_STABLES = LIB.addAddressToArraySafe(_usdStable, WHITELIST_USD_STABLES, true); // true = no dups
            USD_STABLES_HISTORY = LIB.addAddressToArraySafe(_usdStable, USD_STABLES_HISTORY, true); // true = no dups
            // USD_STABLE_DECIMALS[_usdStable] = _decimals;
        } else {
            WHITELIST_USD_STABLES = LIB.remAddressFromArray(_usdStable, WHITELIST_USD_STABLES);
        }
    }
    function _editDexRouters(address _router, bool _add) private {
        require(_router != address(0x0), "0 address");
        if (_add) {
            USWAP_V2_ROUTERS = LIB.addAddressToArraySafe(_router, USWAP_V2_ROUTERS, true); // true = no dups
        } else {
            USWAP_V2_ROUTERS = LIB.remAddressFromArray(_router, USWAP_V2_ROUTERS); // removes only one & order NOT maintained
        }
    }
}