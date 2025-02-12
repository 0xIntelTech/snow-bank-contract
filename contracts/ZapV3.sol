// ref_010625: github.com/0xLancerLab/snow_bank_masterchef.git
// SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.15;
pragma solidity 0.8.24;

import "./ISnowLib.sol";
import "./ZapBase.sol";

// note: ZapBase is multiOperator is Ownable
contract ZapV3 is ZapBase { 
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------- */
    /* GLOBALS - house
    /* -------------------------------------------------------- */
    string public tVERSION = '0.4';     
    bool private FIRST_ = true;
    address public ADDR_CONF; // set via CONF_setConfig
    ISnowConfig private CONF; // set via CONF_setConfig

    /* -------------------------------------------------------- */
    /* GLOBALS - legacy
    /* -------------------------------------------------------- */
    event ZapIntoFarm(address indexed _recipient, uint256 indexed _pid, uint256 _amount);
    event ZapIntoAC(address indexed _recipient, uint256 indexed _pid, uint256 _amount);
    event ZapIntoBoardroom(address indexed _recipient, address _inputToken, uint256 _amount);
    event ZapIntoBoardrooms(address indexed _recipient, uint256 _lpAmount, uint256 _ssAmount);

    /* -------------------------------------------------------- */
    /* MODIFIERS - house
    /* -------------------------------------------------------- */
    modifier onlyKeeper() {
        require(msg.sender == CONF.KEEPER(), "!keeper :p");
        _;
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
        CONF = ISnowConfig(ADDR_CONF);
        devAddress = CONF.ADDR_DEV_EOA(); // set super class devAddress (ZapBase.sol)
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

    /* ========== BANK ========== */
    function zapIntoFarmWithToken(
        address _inputToken,
        uint256 _amount,
        address _targetToken,
        address _farm,
        uint256 _pid,
        bool _targetIsNative,

        // house_010825: promo free deposit support
        address _promotor, 
        string calldata _urn
    ) external nonReentrant returns (uint256 amountOut) {
        //Zap into token.
        amountOut = _universalZap(
            _inputToken, //_inputToken
            _amount, //_amount
            _targetToken, //_targetToken
            address(this), //_recipient
            _targetIsNative
        );

        //Stake in farm.
        IERC20(_targetToken).safeIncreaseAllowance(_farm, amountOut);
        // IRewardPool(_farm).depositFor(_pid, amountOut, msg.sender); // legacy
        IRewardPool(_farm).depositFor(_pid, amountOut, msg.sender, _promotor, _urn); // house_010825: promo free deposit support
        

        //Emit event.
        emit ZapIntoFarm(msg.sender, _pid, amountOut);
    }

    /* ========== BANK ========== */

    function zapIntoFarmWithETH(
        address _targetToken,
        address _farm,
        uint256 _pid,

        // house_010825: promo free deposit support
        address _promotor, 
        string calldata _urn
    ) external payable nonReentrant returns (uint256 amountOut) {
        //Zap into token.
        require(msg.value > 0, "Insufficient ETH");

        amountOut = _universalZapETH(
            msg.value, //_amount
            _targetToken, //_targetToken
            address(this) //_recipient
        );

        //Stake in farm.
        IERC20(_targetToken).safeIncreaseAllowance(_farm, amountOut);
        // IRewardPool(_farm).depositFor(_pid, amountOut, msg.sender); // legacy
        IRewardPool(_farm).depositFor(_pid, amountOut, msg.sender, _promotor, _urn); // house_010825: promo free deposit support

        //Emit event.
        emit ZapIntoFarm(msg.sender, _pid, amountOut);
    }
}
