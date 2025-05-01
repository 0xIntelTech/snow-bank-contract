// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ISnowToken.sol";
import "./interfaces/IZap.sol";
import "./interfaces/ISnowNFT.sol";

contract MasterChef is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    enum TokenType { NONE, ERC20, LP, NFT }
    // Struct to store details of each staking pool
    struct Pool {
        address src;               // The source token for staking (ERC-20 or ERC-721)
        uint256 rewardRate;        // Reward rate for the pool
        uint256 depositFee;        // Fee charged for deposits (in basis points, e.g., 100 = 10%)
        uint256 totalStaked;       // Total staked amount in the pool (for ERC-20, this is the total amount staked)
        uint256 totalReward;       // Total rewarded amount in the pool (for ERC-20, this is the total amount staked)
        mapping(address => uint256) erc20Balances; // User's ERC-20 staked amount
        mapping(address => uint256) rewards;  // User's accumulated rewards
        mapping(address => uint256) lastUpdate; // Last update block for rewards
        mapping(address => uint256[]) stakedTokenIds; // Array of token IDs staked by a user (for ERC-721)
    }

    mapping(uint256 => Pool) public pools;
    address public zapAddr;
    ISnowToken public snowToken;  // Snow token for rewards
    uint256 public poolCount; // Total number of pools
    uint256 public SCALE = 1e8;
    mapping(address => TokenType) public tokenTypes;

    event PoolAdded(uint256 poolId, address indexed source, uint256 rewardRate, uint256 depositFee);
    event PoolUpdated(uint256 poolId, uint256 rewardRate, uint256 depositFee);
    event PoolRemoved(uint256 poolId);
    event Staked(uint256 poolId, address indexed user, uint256 amount);
    event Compounded(uint256 poolId, address indexed user, uint256 amount);
    event Withdrawn(uint256 poolId, address indexed user, uint256 amount);
    event RewardsClaimed(uint256 poolId, address indexed user, uint256 amount);
    event NFTStaked(uint256 poolId, address indexed user, uint256 amount);
    event NFTWithdrawn(uint256 poolId, address indexed user, uint256 amount);

    modifier onlyZap() {
        require(msg.sender == zapAddr, "not zap address");
        _;
    }

    constructor(address _snowToken) Ownable(msg.sender) {
        snowToken = ISnowToken(_snowToken);
        tokenTypes[_snowToken] = TokenType.ERC20;
    }

    function getAPR(uint256 poolId) external view returns(uint256) {
        Pool storage pool = pools[poolId];        
        return pool.rewardRate * 60 * 60 * 24 * 365 / SCALE;
    }

    function setScale(uint256 _scale) external onlyOwner {
        SCALE = _scale;
    }

    function setZapAddress(address _addr) external onlyOwner {
        zapAddr = _addr;
    }

    function setTokenType(address _addr, uint _tokenType) external onlyOwner {
        tokenTypes[_addr] = TokenType(_tokenType); 
    }

    function getTokenType(address _addr) external view returns (uint) {
        return uint(tokenTypes[_addr]);
    }

    // Add a new staking pool
    function addPool(address source, uint256 rewardRate, uint256 depositFee) external onlyOwner {
        poolCount++;
        Pool storage pool = pools[poolCount];
        
        pool.src = source;
        pool.rewardRate = rewardRate;
        pool.depositFee = depositFee;
        pool.totalStaked = 0;

        emit PoolAdded(poolCount, source, rewardRate, depositFee);
    }

    // Remove a staking pool
    function removePool(uint256 poolId) external onlyOwner {
        poolCount--;
        delete pools[poolId];
        emit PoolRemoved(poolId);
    }

    // Update pool settings like reward rate or deposit fee
    function updatePool(uint256 poolId, uint256 rewardRate, uint256 depositFee) external onlyOwner {
        Pool storage pool = pools[poolId];
        pool.rewardRate = rewardRate;
        pool.depositFee = depositFee;

        emit PoolUpdated(poolId, rewardRate, depositFee);
    }

    function getPoolInfo(uint256 poolId) external view returns (address, uint256, uint256, uint256, uint256) {
        Pool storage pool = pools[poolId];
        return (pool.src, pool.rewardRate, pool.depositFee, pool.totalReward, pool.totalStaked);
    }

    function getStakedERC20Amount(uint256 poolId, address user) external view returns (uint256) {
        Pool storage pool = pools[poolId];
        require(isERC20(pool.src), "Not an ERC-20 pool");
        return pool.erc20Balances[user];
    }

    function getStakedNFTAmount(uint256 poolId, address user) external view returns (uint256) {
        Pool storage pool = pools[poolId];
        require(isERC721(pool.src), "Not an ERC-721 pool");
        return pool.stakedTokenIds[user].length;
    }

    function getStakedNFTIds(uint256 poolId, address user) external view returns (uint256[] memory) {
        Pool storage pool = pools[poolId];
        require(isERC721(pool.src), "Not an ERC-721 pool");
        return pool.stakedTokenIds[user];
    }

    function getPendingRewards(uint256 poolId, address user) external view returns (uint256) {
        return calculateReward(poolId, user);
    }

    function stakeFromZap(uint256 poolId, uint256 amount, address _user) external onlyZap {
        _stake(poolId, amount, _user, true);
    }

    function stake(uint256 poolId, uint256 amount) external nonReentrant {
        _stake(poolId, amount, msg.sender, false);
    }
    
    // Stake ERC-20 tokens or ERC-721 NFTs in a specific pool
    function _stake(uint256 poolId, uint256 amount, address _user, bool _isFromZap) internal {
        require(amount > 0, "Cannot stake zero");

        Pool storage pool = pools[poolId];

        // If the source token is ERC-20
        if (isERC20(pool.src)) {
            uint256 feeAmount = (amount * pool.depositFee) / SCALE;  // Deposit fee in basis points (e.g., 100 = 10%)
            uint256 netAmount = amount - feeAmount;

            if (_isFromZap)
                IERC20(pool.src).safeTransferFrom(zapAddr, address(this), amount);
            else
                IERC20(pool.src).safeTransferFrom(_user, address(this), amount);

            IERC20(pool.src).safeTransfer(owner(), feeAmount);

            uint256 reward = calculateReward(poolId, _user);
            if (reward > 0) {
                pool.rewards[_user] += reward;
                pool.totalReward += reward;
                snowToken.mint(_user, reward);
                updateRewardBlock(poolId, _user);
                emit RewardsClaimed(poolId, _user, reward);
            }

            pool.erc20Balances[_user] += netAmount;
            pool.totalStaked += netAmount;

            emit Staked(poolId, _user, netAmount);
        } else if (isERC721(pool.src)) {
            uint256 balance = IERC721(pool.src).balanceOf(_user);
            require(balance >= amount, "Not enough nft balance.");

            uint256 reward = calculateReward(poolId, _user);
            if (reward > 0) {
                pool.rewards[_user] += reward;
                pool.totalReward += reward;
                snowToken.mint(_user, reward);
                updateRewardBlock(poolId, _user);
                emit RewardsClaimed(poolId, _user, reward);
            }

            for (uint i = 0; i < amount; i++){
                // Transfer the ERC-721 to this contract
                uint256 tokenId = ISnowNFT(pool.src).tokenOfOwnerByIndex(_user, i);
                IERC721(pool.src).safeTransferFrom(_user, address(this), tokenId);
                pool.stakedTokenIds[_user].push(tokenId);
            }
            pool.totalStaked += amount;
            // Store the staked token ID for the user
            emit NFTStaked(poolId, _user, amount);
        } else {
            revert("Invalid token type");
        }
    }

    // Withdraw ERC-20 tokens or ERC-721 NFTs from a specific pool
    function withdraw(uint256 poolId, uint256 amount) external nonReentrant {
        Pool storage pool = pools[poolId];

        // If the source token is ERC-20
        if (isERC20(pool.src)) {
            require(pool.erc20Balances[msg.sender] >= amount, "Not enough staked");

            uint256 reward = calculateReward(poolId, msg.sender);

            if (reward > 0){
                pool.rewards[msg.sender] += reward;
                pool.totalReward += reward;
                updateRewardBlock(poolId, msg.sender);
                snowToken.mint(msg.sender, reward);
                emit RewardsClaimed(poolId, msg.sender, reward);
            }

            pool.erc20Balances[msg.sender] -= amount;
            pool.totalStaked -= amount;

            IERC20(pool.src).safeTransfer(msg.sender, amount);

            emit Withdrawn(poolId, msg.sender, amount);
        }
        // If the source token is ERC-721 (NFT)
        else if (isERC721(pool.src)) {
            require(pool.stakedTokenIds[msg.sender].length >= amount, "No enough NFTs staked");

            uint256 reward = calculateReward(poolId, msg.sender);
            if (reward > 0){
                pool.rewards[msg.sender] += reward;
                pool.totalReward += reward;
                updateRewardBlock(poolId, msg.sender);
                snowToken.mint(msg.sender, reward);
                emit RewardsClaimed(poolId, msg.sender, reward);
            }

            // Loop through the staked tokens and find the tokenId to remove
            for (uint256 i = 0; i < amount; i++) {
                uint256 tokenId = pool.stakedTokenIds[msg.sender][i];
                IERC721(pool.src).safeTransferFrom(address(this), msg.sender, tokenId);
            }

            if (amount == pool.stakedTokenIds[msg.sender].length){
                 delete pool.stakedTokenIds[msg.sender];
            } else {
                 for (uint256 i = amount; i < pool.stakedTokenIds[msg.sender].length; i++) {
                    pool.stakedTokenIds[msg.sender][i - amount] = pool.stakedTokenIds[msg.sender][i];
                 }
                 for (uint256 i = 0; i < amount; i++) {
                    pool.stakedTokenIds[msg.sender].pop();
                 }
            }
            pool.totalStaked -= amount;
            emit NFTWithdrawn(poolId, msg.sender, amount);
        } else {
            revert("Invalid token type");
        }
    }


    function Compound(uint poolId) external nonReentrant {
        Pool storage pool = pools[poolId];
        uint256 pending = calculateReward(poolId, msg.sender);
        require(pending > 0 && pool.erc20Balances[msg.sender] > 0, "No pending rewards or staking amount");        
        require(isERC20(pool.src), "Invalid compound pool");   

        uint256 output = pending;
        snowToken.mint(address(this), pending);
        if (tokenTypes[pool.src] == TokenType.LP){
            snowToken.approve(zapAddr, pending);
            output = IZap(zapAddr).swapTokens(address(snowToken), pool.src, pending, 0);
        } 
        pool.erc20Balances[msg.sender] += output;
        pool.totalStaked += output;
        pool.rewards[msg.sender] += pending;
        pool.totalReward += pending;
        updateRewardBlock(poolId, msg.sender);
        emit Compounded(poolId, msg.sender, output);
    }

    // Claim rewards for a specific pool
    function claimRewards(uint256 poolId) external nonReentrant {
        uint256 reward = calculateReward(poolId, msg.sender);
        require(reward > 0, "No rewards");

        Pool storage pool = pools[poolId];
        pool.rewards[msg.sender] += reward;
        pool.totalReward += reward;
        updateRewardBlock(poolId, msg.sender);

        snowToken.mint(msg.sender, reward);

        emit RewardsClaimed(poolId, msg.sender, reward);
    }

    // Calculate pending rewards for a user in a specific pool
    function calculateReward(uint256 poolId, address user) internal view returns (uint256) {
        Pool storage pool = pools[poolId];

        if (isERC20(pool.src)){
            uint256 stakedAmount = pool.erc20Balances[user]; // ERC-20 balance
            uint256 stakedDuration = block.timestamp - pool.lastUpdate[user];
            return (stakedAmount * pool.rewardRate * stakedDuration) / SCALE;
        } else {
            uint256 stakedAmount = pool.stakedTokenIds[user].length; // NFT staked count
            uint256 stakedDuration = block.timestamp - pool.lastUpdate[user];
            return (stakedAmount * pool.rewardRate * stakedDuration) / SCALE;
        }
    }

    function getLatestRewardBlock(uint256 poolId, address user) external view returns (uint256) {
        return pools[poolId].lastUpdate[user];
    }

    // Update the reward block for a specific user in a pool
    function updateRewardBlock(uint256 poolId, address user) internal {
        pools[poolId].lastUpdate[user] = block.timestamp;
    }

    // Check if a token is ERC-20
    function isERC20(address token) public view returns (bool) {
        return tokenTypes[token] == TokenType.ERC20 || tokenTypes[token] == TokenType.LP;
    }

    // Check if a token is ERC-721 (NFT)
    function isERC721(address token) public view returns (bool) {
        return tokenTypes[token] == TokenType.NFT;
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
