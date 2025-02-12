pragma solidity ^0.8.0;

import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ISnowLib.sol";

contract SnowTimelock {
    using SafeMath for uint;

    /* -------------------------------------------------------- */
    /* GLOBALS - house
    /* -------------------------------------------------------- */
    string public tVERSION = '0.1';  
    bool private FIRST_ = true;
    address public ADDR_CONF; // set via CONF_setConfig
    // ISnowConfig private CONF; // set via CONF_setConfig

    /* -------------------------------------------------------- */
    /* GLOBALS - legacy
    /* -------------------------------------------------------- */
    // address public admin; // NOTE: repalced admin w/ onlyConfig modifier
    // mapping(bytes32 => bool) public queuedTransactions;
    mapping(bytes32 => ISnowTimelock.TX_SET) public queuedTransactions;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 6 hours;
    uint public constant MAXIMUM_DELAY = 30 days;

    // constructor(address admin_) {
    //     admin = admin_;
    // }
    constructor() {
        // NOTE: repalced admin w/ onlyConfig modifier
    }

    modifier onlyConfig() { 
        // allows 1st onlyConfig attempt to freely pass
        //  NOTE: don't waste this on anything but CONF_setConfig
        if (!FIRST_) 
            require(msg.sender == address(ADDR_CONF), ' !CONF :/ ');
        FIRST_ = false;
        _;
    }
    function CONF_setConfig(address _conf) external onlyConfig() {
        require(_conf != address(0), ' !addy :< ');
        ADDR_CONF = _conf;
        // CONF = ISnowConfig(ADDR_CONF);
    }

    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public onlyConfig returns (bytes32) {
        // NOTE: repalced admin w/ onlyConfig modifier
        // require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(
            eta >= getBlockTimestamp().add(MINIMUM_DELAY),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );
        require(
            eta <= getBlockTimestamp().add(MAXIMUM_DELAY),
            "Timelock::queueTransaction: Estimated execution block must not exceed maximum delay."
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        // queuedTransactions[txHash] = true;
        queuedTransactions[txHash] = ISnowTimelock.TX_SET(txHash, target, value, signature, data, eta);

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public onlyConfig {
        // NOTE: repalced admin w/ onlyConfig modifier
        // require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        // queuedTransactions[txHash] = false;
        delete queuedTransactions[txHash];

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public payable onlyConfig returns (bytes memory) {
        // NOTE: repalced admin w/ onlyConfig modifier
        // require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(
            // queuedTransactions[txHash],
            queuedTransactions[txHash].target != address(0),
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            getBlockTimestamp() >= eta,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta.add(GRACE_PERIOD),
            "Timelock::executeTransaction: Transaction is stale."
        );

        // queuedTransactions[txHash] = false;
        delete queuedTransactions[txHash];

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}