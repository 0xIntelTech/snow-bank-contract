// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
interface IZap {
    function universalZapForCompound(
        address _inputToken,
        uint256 _amount,
        address _targetToken,
        address _recipient
    ) external returns (uint256 amountOut);
}
interface ISnowNFT {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function setDAIAddress(address _DAI) external;
    function setNFTPrice(uint256 _newPrice) external;
}
interface ISnowToken {
    function balanceOf(address account) external returns(uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function mint(address to, uint256 amount) external;
}
interface IMasterChef {
    function massUpdatePools() external;
}
interface ISnowTimelock {
    // structs
    struct TX_SET {
        bytes32 txHash;
        address target;
        uint value;
        string signature;
        bytes data;
        uint eta;
    }

    // accessors
    function queuedTransactions(bytes32 _txHash) external view returns(TX_SET memory);

    // mutators
    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external returns (bytes32);
    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external;
    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external payable returns (bytes memory);   
}
interface ISnowConfig {
    // accessors
    function owner() external view returns(address); // owner of everything 
    function KEEPER() external view returns(address);
    function ADDR_TREAS_EOA() external view returns(address);
    function ADDR_DEV_EOA() external view returns(address);
    function ADDR_CHEF() external view returns(address);
    function ADDR_SNOW() external view returns(address);
    function ADDR_SNOWNFT() external view returns(address); 
    function ADDR_ZAP() external view returns(address);
    function ADDR_LIB() external view returns(address);
    function ADDR_TIMELOCK() external view returns(address);
    

    function SNOWPerBlock() external view returns(uint256); // from legacy master chef
    function PROMO_PERC_SNOW_REWARD() external view returns(uint16); // promotors receive % of each referal $SNOW earnings; 10000 = 100.00%
    function PROMO_NUM_FREE_DEPOSITS() external view returns(uint8); // number of free deposits each promotor promo is good for
    function PROMO_REWAR_MINT_ENABLED() external view returns(bool); // true = rewards minted, false = rewards sub from user snow earns (safeSNOWTransfer)
    function URN_PROMO(string calldata _key) external view returns(ISnowLib.PROMO memory); // public
    function PROMOTOR_PROMO(address _key) external view returns(ISnowLib.PROMO memory); // public
    function promotorExists(address _promotor) external view returns(bool);
    function promoUrnExists(string memory _customURN) external view returns(bool);

    // mutators
    function setDev(address _devAddress) external;
    function setTreasury(address _treasAddress) external;
    function addNewPromotor(ISnowLib.PROMO memory _promo) external;
    function attemptUseFreeDeposit(address _promotor, string memory _customURN, address _user) external returns(bool);
    function calcPromoRewardFromUserAmount(address _user, uint256 _amount) external view returns(uint256, address);
}
interface ISnowLib {
    /* -------------------------------------------------------- */
    /* STRUCTS (SNOW)
    /* -------------------------------------------------------- */
    struct PROMO { // NOTE: 1 promo per promotor EOA (created in MasterChef.registerPromotor)
        address promotor; // influencer wallet this promo is for
        string customURN; // custom promo code for snowbank.io custom referral url (eg. "snowbank.io/SNOW123")
        uint16 percReward; // 100.00% = 10000; % of user $SNOW earnings rewarded (dynamic control by admin)
        uint8 numFreeDepPerUsr; // number of free deposits this promo is good for per user
        address creator; // address who created this promo
        uint256 blockTimestamp; // sec timestamp this promo was created
        uint256 blockNumber; // block number this promo was created
    }
    // created in ... (during deposits)
    // struct SNOW_REWARD { // NOTE: many snow reward per promotor EOA
    //     address promotor; // the promo / influencer wallet thats earning rewards
    //     uint16 percReceived; // 100.00% = 10000; % of user $SNOW earnings promotor received (from promotor's PROMO.percReward)
    //     uint256 snowEarned; // amount of $SNOW recieved from user earnings (when calc? when do we know how much $SNOW was earned by promotor?)
    //     bool isPaid; // true = promotor has been paid snowEarned amount

    //     uint256 blockTimestamp; // sec timestamp this promo was used
    //     uint256 blockNumber; // block number this promo was created
    // }
    struct FREE_DEPOSIT { // NOTE: 1 free deposits per user
        address user; // EOA who used a promo on deposit
        address promotor; // promo / influencer wallet that was used
        uint256 snowDeposited; // cumulative amount of $SNOW deposited by user (if possible)
        uint8 freeDepositCnt; // # of free deposits this user has used (default 0, increment to PROMO.numFreeDepPerUsr)
        uint256 blockTimestamp; // sec timestamp this promo was used
        uint256 blockNumber; // block number this promo was created
    }

    // note: snowbank functions
    function addBytes32ToArraySafe(bytes32 _bytes, bytes32[] memory _arr, bool _safe) external pure returns (bytes32[] memory);
    function remBytes32FromArray(bytes32 _bytes, bytes32[] memory _arr) external pure returns (bytes32[] memory);
    function addAddressToArraySafe(address _addr, address[] memory _arr, bool _safe) external pure returns (address[] memory);
    function remAddressFromArray(address _addr, address[] memory _arr) external pure returns (address[] memory);
    function _perc_of_uint256(uint16 _perc, uint256 _num) external pure returns (uint256);
    
    // debugging...
    // function debug_log_uint(address _sender, uint8 _uint8, uint16 _uint16, uint32 _uint32, uint64 _uint64, uint256 _uint256) external pure;
    // function debug_log_addess(address _sender, address _address0, address _address1, address _address2) external pure;
    // function debug_log_string(address _sender, string calldata _string0, string calldata _string1, string calldata _string2) external pure;

    // note: legacy
    // function addStringToArraySafe(string calldata _str, string[] memory _arr, bool _safe) external pure returns (string[] memory);
    // function remStringFromArray(string calldata _str, string[] memory _arr) external pure returns (string[] memory);
    // function _isAddressInArray(address _addr, address[] memory _addrArr) external pure returns(bool);   
    // function _validNonWhiteSpaceString(string calldata _s) external pure returns(bool);
    // function generateAddressHash(address host, string calldata uid) external pure returns (address);
    // function _perc_of_uint64(uint16 _perc, uint64 _num) external pure returns (uint64);
    // function _uint64_from_uint256(uint256 value) external pure returns (uint64);
    // function _perc_total_supply_owned(address _token, address _account) external view returns (uint64);
    // function _normalizeStableAmnt(uint8 _fromDecimals, uint256 _usdAmnt, uint8 _toDecimals) external pure returns (uint256);
}