// ref_010325: forked from admin: ../legacy/Snow_Bank_MasterChef-main.zip
// ref_010625: merged latest dev source: github.com/0xLancerLab/snow_bank_masterchef.git
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
// pragma solidity ^0.8.20;

import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./node_modules/@openzeppelin/contracts/utils/Address.sol";
import "./node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./ISnowLib.sol";

// MasterChef is the master of SNOW. He can make SNOW and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SNOW is sufficiently
// distributed and the community can show to govern itself.
//

contract MasterChef is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------- */
    /* GLOBALS - house
    /* -------------------------------------------------------- */
    string public tVERSION = '0.5';    
    bool private FIRST_ = true;
    address public ADDR_CONF; // set via CONF_setConfig
    ISnowConfig private CONF; // set via CONF_setConfig
    ISnowToken private SNOW; // set via CONF_setConfig
    // ISnowTimelock private TIMELOCK; // set via CONF_setConfig
    ISnowLib private LIB;     // set via CONF_setConfig

    /* -------------------------------------------------------- */
    /* EVENTS
    /* -------------------------------------------------------- */
    event PromoCreated(address _promotor, string _customURN, uint16 _percReward, uint8 _numFreeDeposits, address _creator, uint256 _blockTimestamp, uint256 _blockNumber);

    /* -------------------------------------------------------- */
    /* MODIFIERS
    /* -------------------------------------------------------- */
    modifier onlyKeeper() {
        require(msg.sender == CONF.KEEPER(), "!keeper :p");
        _;
    }
    modifier onlyConfig() { 
        // allows 1st onlyConfig attempt to freely pass
        //  NOTE: don't waste this on anything but CONF_setConfig
        if (!FIRST_) 
            require(msg.sender == address(CONF), ' !CONF :/ ');
        FIRST_ = false;
        _;
    }
    function CONF_setConfig(address _conf) external onlyConfig() {
        require(_conf != address(0), ' !addy :< ');
        ADDR_CONF = _conf;
        CONF = ISnowConfig(_conf);
        SNOW = ISnowToken(CONF.ADDR_SNOW());
        // TIMELOCK = ISnowTimelock(CONF.ADDR_TIMELOCK());
        LIB = ISnowLib(CONF.ADDR_LIB());
    }
    
    /* -------------------------------------------------------- */
    /* GLOBALS - legacy
    /* -------------------------------------------------------- */
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastWithdrawBlock; // We count in Blockstamps so uin256 is sufficient.
        uint256 lastHarvestBlock;
        uint256 harvestBlocks;
        uint256[] tokenIds; // NFT token IDs which the user has provided.

        //
        // We do some fancy math here. Basically, any point in Block, the amount of SNOWs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSNOWPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSNOWPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SNOWs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SNOWs distribution occurs.
        uint256 accSNOWPerShare; // Accumulated SNOWs per share, Blocks 1e18. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        bool isNFTPool; // if lastRewardBlock has passed
    }

    // The SNOW TOKEN!
    // house_010325: using interface instead of contract object
    //  NOTE: should likely make private as well, but maybe client side is referencing it?
    // SNOWToken public SNOW;
    // ISnowToken public SNOW; 
    // address public SNOWAddr; // The SNOW Address
    // address public zapAddr; // Zap address
    // address public devaddr; // Dev address.
    // address public treasuryAddress; // Dev address.
    // address public marketAddress; // Deposit Fee address

    // SNOW tokens created per block.
    // uint256 public SNOWPerBlock = 0; // house_011225: migrated to SnowConfig

    // Bonus muliplier for early SNOW makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // maximim compound per day, per user.

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 1000; // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public startBlock; // The Blockstamp when SNOW mining starts.
    uint256 MAX_AMOUNT = 2 ** 256 - 1;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    // constructor(
    //     address _SNOW,
    //     address _ADDR_DEV_EOA,
    //     address _marketAddress,
    //     address _ADDR_TREAS_EOA,
    //     address _ADDR_ZAP,
    //     uint256 _startBlock
    // ) {
    //     SNOW = SNOWToken(_SNOW);
    //     ADDR_DEV_EOA = _ADDR_DEV_EOA;
    //     ADDR_TREAS_EOA = _ADDR_TREAS_EOA;
    //     marketAddress = _marketAddress;
    //     startBlock = block.number > _startBlock ? block.number : _startBlock;
    //     ADDR_SNOW = _SNOW;
    //     ADDR_ZAP = _ADDR_ZAP;
    // }

    // house_010325: refactored constructor for ease testing
    // constructor(uint256 _startBlock) Ownable(msg.sender) {
    constructor() Ownable(msg.sender) {
        // house_010325: updated support w/ using interface instead of object
        // SNOW = ISnowToken(_SNOW);

        // house_010325: using static EOAs
        // ADDR_DEV_EOA = address(ADDR_DEV_EOA);
        // feeAddress = address(ADDR_FEE_EOA);
        // ADDR_TREAS_EOA = address(ADDR_TREAS_EOA);
        // marketAddress = address(ADDR_FEE_EOA);

        // legacy
        // startBlock = block.number > _startBlock ? block.number : _startBlock;
        startBlock = block.number;
        // ADDR_SNOW = _SNOW;
        // ADDR_ZAP = _ADDR_ZAP;
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /* -------------------------------------------------------- */
    /* PUBLIC - referral support - accessors
    /* -------------------------------------------------------- */
    function getPromoForPromotorOrURN(address _promotor, string calldata _urn) external view returns(ISnowLib.PROMO memory) {
        // NOTE: priority promo returns for _promotor over _urn
        if (_promotor == address(0)) {
            require(bytes(_urn).length > 1, ' invalid _promotor & _urn.len :/ ');
            require(CONF.promoUrnExists(_urn), ' bad promo urn :/ ');
            return CONF.URN_PROMO(_urn);
        }
        require(CONF.promotorExists(_promotor), ' bad promo :/ ');
        return CONF.PROMOTOR_PROMO(_promotor);
    }

    /* -------------------------------------------------------- */
    /* PUBLIC - referral support - mutators
    /* -------------------------------------------------------- */
    function registerPromotor(address _promotor, string calldata _customURN) external {
        require(_promotor != address(0) && bytes(_customURN).length > 1, ' bad _promotor | _urn.len :/ ');

        // NOTE: reward perc and num free deposits are locked in for this _promotor EOA        
        uint16 perc_reward = CONF.PROMO_PERC_SNOW_REWARD();
        uint8 num_free_deps = CONF.PROMO_NUM_FREE_DEPOSITS();

        // reverts: if _promotor or _customURN already exists in SnowConfig
        CONF.addNewPromotor(ISnowLib.PROMO(_promotor, _customURN, perc_reward, num_free_deps, msg.sender, block.timestamp, block.number));
        emit PromoCreated(_promotor, _customURN, perc_reward, num_free_deps, msg.sender, block.timestamp, block.number);
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
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        address _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate,
        bool _isNFTPool
    ) public onlyOwner {
        require(_depositFeeBP <= 1000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        if (!_isNFTPool) {
            _increaseZapperAllowance(_lpToken, MAX_AMOUNT);
        }

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSNOWPerShare: 0,
                depositFeeBP: _depositFeeBP,
                isNFTPool: _isNFTPool
            })
        );
    }

    // Update the given pool's SNOW allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint256 _startBlock,
        bool _withUpdate
    ) public onlyOwner {
        require(_depositFeeBP <= 1000, "set: invalid deposit fee basis points");
        require(_allocPoint < 10000, "set: invalid alloc point basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].lastRewardBlock = _startBlock;
    }

    /* -------------------------------------------------------- */
    /* ACCESSORS - legacy
    /* -------------------------------------------------------- */
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
        if (_fromBlock >= _toBlock) return 0;
        if (_toBlock <= startBlock) return 0;
        if (_fromBlock <= startBlock) return _toBlock.sub(startBlock).mul(CONF.SNOWPerBlock());
        return _toBlock.sub(_fromBlock).mul(CONF.SNOWPerBlock());
    }

    // View function to see pending SNOWs on frontend.
    function pendingSNOW(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accSNOWPerShare = pool.accSNOWPerShare;
        uint256 lpSupply = pool.isNFTPool
            ? IERC721(pool.lpToken).balanceOf(address(this))
            : IERC20(pool.lpToken).balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 SNOWReward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);

            uint256 adjustedLpSupply = pool.isNFTPool ? lpSupply.mul(1e18) : lpSupply;
            accSNOWPerShare = accSNOWPerShare.add(SNOWReward.mul(1e18).div(adjustedLpSupply));
        }

        uint256 userAmount = user.amount;
        return userAmount.mul(accSNOWPerShare).div(1e18).sub(user.rewardDebt);
    }

    /* -------------------------------------------------------- */
    /* MUTATORS - legacy - public
    /* -------------------------------------------------------- */
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.isNFTPool
            ? IERC721(pool.lpToken).balanceOf(address(this))
            : IERC20(pool.lpToken).balanceOf(address(this));

        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 SNOWReward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
        // Distribute rewards
        distributeRewards(SNOWReward, multiplier);
        // Update pool's accumulated SNOW per share
        uint256 adjustedLpSupply = pool.isNFTPool ? lpSupply.mul(1e18) : lpSupply;
        pool.accSNOWPerShare = pool.accSNOWPerShare.add(SNOWReward.mul(1e18).div(adjustedLpSupply));

        pool.lastRewardBlock = block.number;
    }

    // Helper function to distribute rewards
    function distributeRewards(uint256 SNOWReward, uint256 multiplier) internal {
        // SNOWToken(SNOW).mint(ADDR_DEV_EOA, multiplier.div(100));
        // SNOWToken(SNOW).mint(marketAddress, multiplier.div(100));
        // SNOWToken(SNOW).mint(ADDR_TREAS_EOA, multiplier.mul(300).div(10000));
        // SNOWToken(SNOW).mint(address(this), SNOWReward);

        // house_010325: updated support w/ using interface instead of object
        SNOW.mint(CONF.ADDR_DEV_EOA(), multiplier.div(100));
        // SNOW.mint(marketAddress, multiplier.div(100));
        SNOW.mint(CONF.ADDR_TREAS_EOA(), multiplier.mul(300).div(10000));
        SNOW.mint(address(this), SNOWReward);
            // LEFT OFF HERE ...
            //  need to verify these numbers
            //  admin wants 1% to dev, 2% to treasury
            //   and remove marketAddress completely (not needed in this integration)
    }

    // Deposit LP tokens to MasterChef for SNOW allocation.
    function deposit(uint256 _pid, uint256 _amount, bool isNFTAll, address _promotor, string calldata _urn) public nonReentrant {
        _deposit(_pid, _amount, isNFTAll, _promotor, _urn);
    }

    /// @notice Deposit tokens to MasterChef for SNOW allocation.
    /// @param _pid pool id to deposit to
    /// @param _amount amount of tokens to deposit. This amount should be approved beforehand
    /// @param _recipient lock period in seconds to lock
    function depositFor(uint256 _pid, uint256 _amount, address _recipient, address _promotor, string calldata _urn) external nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_recipient];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSNOWPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                safeSNOWTransfer(_recipient, pending);
            }
        }
        if (_amount > 0) {
            if (pool.isNFTPool) {
                require(IERC721(pool.lpToken).ownerOf(_amount) == _sender, "Invalid owner");
                IERC721(pool.lpToken).safeTransferFrom(_sender, address(this), _amount);
                user.amount = user.amount.add(1e18);
                user.tokenIds.push(_amount);
            } else {
                IERC20(pool.lpToken).safeTransferFrom(address(_sender), address(this), _amount);
                // if (pool.depositFeeBP > 0) { // legacy (no promo free deposit check)
                if (pool.depositFeeBP > 0 && !CONF.attemptUseFreeDeposit(_promotor, _urn, _sender)) { // house_010825: update w/ free deposit attempt
                    uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                    // IERC20(pool.lpToken).safeTransfer(marketAddress, depositFee.div(2));
                    IERC20(pool.lpToken).safeTransfer(CONF.ADDR_DEV_EOA(), depositFee.div(2));
                        // LET OFF HERE ... amdin wants all deposit fees burned 
                        //      nothing sent to market or dev address
                    user.amount = user.amount.add(_amount).sub(depositFee);
                } else {
                    user.amount = user.amount.add(_amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accSNOWPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function _deposit(
        uint256 _pid,
        uint256 _amount,
        bool isNFTAll,
        address _promotor, // house_010825: promo deposits
        string memory _urn // house_010825: promo deposits
    ) internal validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        address _sender = msg.sender;
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSNOWPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                safeSNOWTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            if (pool.isNFTPool) {
                uint256[] memory tokenIds = ISnowNFT(pool.lpToken).walletOfOwner(_sender);
                if (isNFTAll) {
                    if (tokenIds.length > 0) {
                        for (uint256 i = 0; i < tokenIds.length; i++) {
                            IERC721(pool.lpToken).safeTransferFrom(
                                _sender,
                                address(this),
                                tokenIds[i]
                            );
                            user.amount = user.amount.add(1e18);
                            user.tokenIds.push(tokenIds[i]);
                        }
                    }
                } else {
                    require(tokenIds.length >= _amount, "Invalid token amount");
                    if (tokenIds.length > 0) {
                        for (uint256 i = 0; i < _amount; i++) {
                            IERC721(pool.lpToken).safeTransferFrom(
                                _sender,
                                address(this),
                                tokenIds[i]
                            );
                            user.amount = user.amount.add(1);
                            user.tokenIds.push(tokenIds[i]);
                        }
                    }
                }
            } else {
                IERC20(pool.lpToken).safeTransferFrom(address(_sender), address(this), _amount);
                // if (pool.depositFeeBP > 0) { // legacy (no promo free deposit check)
                if (pool.depositFeeBP > 0 && !CONF.attemptUseFreeDeposit(_promotor, _urn, _sender)) { // house_010825: update w/ free deposit attempt
                    uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                    // IERC20(pool.lpToken).safeTransfer(marketAddress, depositFee.div(2));
                    IERC20(pool.lpToken).safeTransfer(CONF.ADDR_DEV_EOA(), depositFee.div(2));
                        // LET OFF HERE ... amdin wants all deposit fees burned 
                        //      nothing sent to market or dev address
                    user.amount = user.amount.add(_amount).sub(depositFee);
                } else {
                    user.amount = user.amount.add(_amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accSNOWPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Function to harvest or compound many pools in a single transaction
    function harvestMany(uint256[] calldata _pids) public nonReentrant {
        for (uint256 index = 0; index < _pids.length; index++) {
            _deposit(_pids[index], 0, false, address(0), ""); // house_010825: ignoare last 2 params added: defaults for promo deposits
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount, bool isNFTAll) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        address _sender = msg.sender;
        uint256 pending = user.amount.mul(pool.accSNOWPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            safeSNOWTransfer(msg.sender, pending);
        }

        if (_amount > 0) {
            if (pool.isNFTPool) {
                uint256[] memory _tokenIds = user.tokenIds;
                if (isNFTAll) {
                    if (_tokenIds.length > 0) {
                        uint256[] memory empyArr;
                        user.tokenIds = empyArr;
                        for (uint256 i = 0; i < _tokenIds.length; i++) {
                            user.amount = user.amount.sub(1e18);
                            IERC721(pool.lpToken).safeTransferFrom(
                                address(this),
                                _sender,
                                _tokenIds[i]
                            );
                        }
                    }
                } else {
                    require(_tokenIds.length >= _amount, "Invalid token amount");
                    if (_tokenIds.length > 0) {
                        uint256[] memory newArr = new uint256[](_tokenIds.length - _amount);
                        for (uint256 i = _amount; i < _tokenIds.length; i++) {
                            newArr[i - _amount] = _tokenIds[i];
                        }
                        user.tokenIds = newArr;
                        for (uint256 i = 0; i < _amount; i++) {
                            user.amount = user.amount.sub(1e18);
                            IERC721(pool.lpToken).safeTransferFrom(
                                address(this),
                                _sender,
                                _tokenIds[i]
                            );
                        }
                    }
                }
            } else {
                require(user.amount >= _amount, "withdraw: not good");
                if (_amount > 0) {
                    user.amount = user.amount.sub(_amount);
                    IERC20(pool.lpToken).safeTransfer(_sender, _amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accSNOWPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        address _sender = msg.sender;
        user.amount = 0;
        user.rewardDebt = 0;
        if (pool.isNFTPool) {
            uint256[] memory _tokenIds = user.tokenIds;
            uint256[] memory empyArr;
            user.tokenIds = empyArr;
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IERC721(pool.lpToken).safeTransferFrom(address(this), _sender, _tokenIds[i]);
            }
        } else {
            IERC20(pool.lpToken).safeTransfer(_sender, amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    // Safe SNOW transfer function, just in case if rounding error causes pool to not have enough SNOWs.
    function _increaseZapperAllowance(address _token, uint256 _amount) private {
        IERC20(_token).safeIncreaseAllowance(CONF.ADDR_ZAP(), _amount);
    }
    // Safe SNOW transfer function, just in case if rounding error causes pool to not have enough SNOWs.
    function safeSNOWTransfer(address _to, uint256 _amount) internal {
        // house_010825: updated support for promo reward payments
        //  check if _to has a promotor & calc/pay them their reward
        (uint256 promoRewardSNOW, address promotor) = CONF.calcPromoRewardFromUserAmount(_to, _amount);
        if (CONF.PROMO_REWAR_MINT_ENABLED())
            SNOW.mint(promotor, promoRewardSNOW); // mint new supply
        else {
            uint256 snow_bal = SNOW.balanceOf(address(this));
            SNOW.transfer(promotor, promoRewardSNOW > snow_bal ? snow_bal : promoRewardSNOW);
            _amount -= promoRewardSNOW; // sub from _amount to send to _to
        }

        // legacy
        uint256 SNOWBal = SNOW.balanceOf(address(this));
        if (_amount > SNOWBal) {
            SNOW.transfer(_to, SNOWBal);
        } else {
            SNOW.transfer(_to, _amount);
        }

        // LEFT OFF HERE ...
        // house_010325: if _amount is too large above ... (also promoRewardSNOW)
        //  defaulting to full contract balance of SNOW, might be exploitable or innefficient
        //  instead, we should be tracking this contract's holdings of SNOW 
        //   to ensure that _amount can never be larger than current balance (where ever 'safeSnowTransfer' is invoked)
    }

    function compound(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amountOut = 0;
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSNOWPerShare).div(1e18).sub(user.rewardDebt);
            uint256 SNOWBal = SNOW.balanceOf(address(this));

            if (user.amount > 0) {
                if (pending > 0) {
                    if (pending > SNOWBal) {
                        amountOut = IZap(CONF.ADDR_ZAP()).universalZapForCompound(
                            CONF.ADDR_SNOW(), //_inputToken
                            SNOWBal, //_amount
                            pool.lpToken, //_targetToken
                            address(this) //_recipient
                        );
                    } else {
                        amountOut = IZap(CONF.ADDR_ZAP()).universalZapForCompound(
                            CONF.ADDR_SNOW(), //_inputToken
                            pending, //_amount
                            pool.lpToken, //_targetToken
                            address(this) //_recipient
                        );
                    }
                }
            }

            if (amountOut > 0) {
                if (pool.depositFeeBP > 0) {
                    uint256 depositFee = amountOut.mul(pool.depositFeeBP).div(10000);
                    // IERC20(pool.lpToken).safeTransfer(marketAddress, depositFee.div(2));
                    IERC20(pool.lpToken).safeTransfer(CONF.ADDR_DEV_EOA(), depositFee.div(2));
                        // LET OFF HERE ... amdin wants all deposit fees burned 
                        //      nothing sent to market or dev address
                    user.amount = user.amount.add(amountOut).sub(depositFee);
                } else {
                    user.amount = user.amount.add(amountOut);
                }
            }
            user.rewardDebt = user.amount.mul(pool.accSNOWPerShare).div(1e18);
        }
    }

    // /* -------------------------------------------------------- */
    // /* MUTATORS - legacy - admin
    // /* -------------------------------------------------------- */
    // legacy dead code _ // house_011225: migrated to SnowConfig
    // function updateEmissionRate(uint256 _SNOWPerBlock) public onlyConfig {
    //     massUpdatePools();
    //     SNOWPerBlock = _SNOWPerBlock;
    // }
    // function setMainTokenAddress(address _SNOW) public onlyOwner {
    //     require(_SNOW != address(0), "Invalid Address");
    //     // SNOW = SNOWToken(_SNOW);
    //     SNOW = ISnowToken(_SNOW);
    //         // house_010325: updated support w/ using interface instead of object
    // }

    function getUserStakedNFTs(uint256 _pid, address _user) public view returns (uint256[] memory) {
        return userInfo[_pid][_user].tokenIds;
    }

    /* -------------------------------------------------------- */
    /* ACCESSORS - legacy - NFT (Snow_Bank_MasterChef-main.zip)
    /* -------------------------------------------------------- */
    // function getAmountPerNFT() public view returns (uint256) {
    //     return amountPerNFT;
    // }

    // function getUserStakedNFTs(uint256 _pid, address _user) public view returns (uint256[] memory) {
    //     return userInfo[_pid][_user].tokenIds;
    // }
}
