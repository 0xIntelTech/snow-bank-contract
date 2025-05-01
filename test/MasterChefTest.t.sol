// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../src/MasterChef.sol";
import "../src/SnowToken.sol";
import "../src/SnowNFT.sol";
import "./Mock/ERC20Mock.sol";

// Assuming the address for Snow token and ERC-20 contract are provided in this test setup
contract MasterChefTest is Test {
    using SafeERC20 for IERC20;

    MasterChef public masterChef;
    SnowToken public snowToken;
    ERC20Mock public erc20Token;
    SnowNFT public nftToken;
    ERC20Mock public scUSD;

    address public user = address(2);
    address public owner = address(1);
    uint256 public poolId;
    uint256 public poolNftId;
    uint256 public nftId = 1; // Assuming we are testing with tokenId = 1 for NFTs

    // Setup for forking SONIC mainnet
    function setUp() public {
        vm.startPrank(owner);
        // Deploy SnowToken and ERC-20 Token (mocked here, replace with real contract address)
        snowToken = new SnowToken();  // Replace with real Snow token address if needed

        erc20Token = new ERC20Mock(1000 ether);  // Replace with a mock or real ERC-20 token address
        scUSD = new ERC20Mock(100 * 1e18);
        nftToken = new SnowNFT("SnowNFT", "SNFT", "https://example.com/metadata/", address(scUSD));

        // Deploy the MasterChef contract
        masterChef = new MasterChef(address(snowToken));

        snowToken.setAuthorized(address(masterChef), true);
        snowToken.setProxy(address(masterChef), true);
        // Add a new ERC-20 pool to the MasterChef contract
        poolId = 1;
        masterChef.addPool(address(erc20Token), 10, 0);  // 10 reward rate, 5% deposit fee
        masterChef.setTokenType(address(erc20Token), 1);

        poolNftId = 2;
        masterChef.addPool(address(nftToken), 1000, 0);  // 10 reward rate, 5% deposit fee
        masterChef.setTokenType(address(nftToken), 3);

        // Transfer tokens to user for staking
        erc20Token.mint(user, 1000 ether);  // Mint 1000 tokens to the user
        nftToken.mint(user);  // Mint a NFT to the user
        nftToken.mint(user);  // Mint a NFT to the user
        nftToken.mint(user);  // Mint a NFT to the user
    }

    // Test adding a new pool
    function testAddPool() public view {
        // Ensure the pool has been added correctly
        address src;
        uint rewardRate = 0;
        uint depositFee = 0;
        uint totalRewards = 0;
        uint totalStaked = 0;
        (src, rewardRate, depositFee, totalRewards, totalStaked) = masterChef.getPoolInfo(poolId);
        assertEq(src, address(erc20Token));
        assertEq(rewardRate, 10);
        assertEq(depositFee, 0);
    }

    // Test staking ERC-20 tokens in the pool
    function testStakeERC20() public {
        uint256 amountToStake = 100 ether;
        
        // Make the user approve the contract to transfer tokens
        vm.startPrank(user);
        console.log('testStakeERC20 started');
        erc20Token.approve(address(masterChef), amountToStake);
        // Stake the tokens
        masterChef.stake(poolId, amountToStake);

        // Check the user's staked balance
        uint256 stakedAmount = masterChef.getStakedERC20Amount(poolId, user);
        console.log('stakedAmount', stakedAmount);
        // Check total staked in the pool
        address src;
        uint rewardRate = 0;
        uint depositFee = 0;
        uint totalRewards = 0;
        uint totalStaked = 0;
        (src, rewardRate, depositFee, totalRewards, totalStaked) = masterChef.getPoolInfo(poolId);

        console.log('testStakeERC20 - getPoolInfo');

        uint256 feeAmount = (amountToStake * depositFee) / 1000;  // Deposit fee in basis points (e.g., 100 = 10%)
        uint256 netAmount = amountToStake - feeAmount + 0;

        console.log('testStakeERC20', netAmount);
        assertEq(totalStaked, netAmount);
    }

    // Test claiming rewards
    function testClaimRewards() public {
        uint256 amountToStake = 100 ether;

        // Make the user approve the contract to transfer tokens
        vm.startPrank(user);
        erc20Token.approve(address(masterChef), amountToStake);


        // Stake the tokens
        masterChef.stake(poolId, amountToStake);

        // Fast-forward the block to simulate time passing
        vm.roll(block.number + 10);  // move ahead by 10 blocks

        // Claim the rewards
        masterChef.claimRewards(poolId);

        // Check if the reward has been minted to the user
        uint256 rewardBalance = snowToken.balanceOf(user);
        assertGt(rewardBalance, 0, "User should have rewards");
    }

    // Test withdrawing ERC-20 tokens
    function testWithdrawERC20() public {
        uint256 amountToStake = 10 ether;

        // Make the user approve the contract to transfer tokens
        vm.startPrank(user);
        erc20Token.approve(address(masterChef), amountToStake * 2);

        // Stake the tokens
        masterChef.stake(poolId, amountToStake);

        // Stake the tokens
        masterChef.stake(poolId, amountToStake);

        // Withdraw the tokens
        masterChef.withdraw(poolId, amountToStake * 2);

        // Check that the user's balance has been updated correctly
        uint256 stakedAmount = masterChef.getStakedERC20Amount(poolId, user);
        assertEq(stakedAmount, 0);

        // Check total staked in the pool
        uint totalStaked = 0;
        (, , , , totalStaked) = masterChef.getPoolInfo(poolId);
        assertEq(totalStaked, 0);
    }

    // Test staking an ERC-721 NFT
    function testStakeNFT() public {
        uint256 amountToStake = 2; // Not using ERC-20 tokens for this test
        
        // Transfer the NFT to the contract (staking it)
        vm.startPrank(user);
        nftToken.setApprovalForAll(address(masterChef), true);

        // Stake the NFT
        masterChef.stake(poolNftId, amountToStake);

        // Check if the NFT is staked
        uint256[] memory stakedTokens = masterChef.getStakedNFTIds(poolNftId, user);
        assertEq(stakedTokens.length, 2);

        // Check total staked in the pool
        uint totalStaked = 0;
        (, , , , totalStaked) = masterChef.getPoolInfo(poolNftId);

        assertEq(totalStaked, 2);
    }

    // Test withdrawing an ERC-721 NFT
    function testWithdrawNFT() public {
        uint256 amountToStake = 1; // Not using ERC-20 tokens for this test

        // Transfer the NFT to the contract (staking it)
        vm.startPrank(user);
        nftToken.setApprovalForAll(address(masterChef), true);

        // Stake the NFT
        masterChef.stake(poolNftId, amountToStake);
        uint256[] memory stakedTokens = masterChef.getStakedNFTIds(poolNftId, user);
        assertEq(stakedTokens.length, 1);
        // Withdraw the NFT
        masterChef.withdraw(poolNftId, amountToStake);

        // Check if the NFT is withdrawn
        stakedTokens = masterChef.getStakedNFTIds(poolNftId, user);
        assertEq(stakedTokens.length, 0);

        // Check total staked in the pool
        uint totalStaked = 0;
        (, , , , totalStaked) = masterChef.getPoolInfo(poolNftId);
        assertEq(totalStaked, 0);

        // Ensure the NFT is back with the user
        assertEq(nftToken.ownerOf(0), user);
    }

    // // Test claiming rewards after staking an NFT
    // function testClaimRewardsForNFT() public {
    //     uint256 amountToStake = 0; // Not using ERC-20 tokens for this test

    //     // Transfer the NFT to the contract (staking it)
    //     vm.startPrank(user);
    //     nftToken.approve(address(masterChef), nftId);
    //     console.log('testClaimRewardsForNFT');
    //     // Stake the NFT
    //     masterChef.stake(poolNftId, amountToStake, nftId);

    //     // Fast-forward the block to simulate time passing
    //     vm.roll(block.number + 10);  // move ahead by 10 blocks

    //     address src;
    //     uint rewardRate = 0;
    //     uint depositFee = 0;
    //     uint totalRewards = 0;
    //     uint totalStaked = 0;
    //     (src, rewardRate, depositFee, totalRewards, totalStaked) = masterChef.getPoolInfo(poolNftId);



    //     uint256[] memory ids = masterChef.getStakedNFTIds(poolNftId, user);



    //     uint256 number = masterChef.getLatestRewardBlock(poolNftId, user);

    //     console.log('latest block number', number);
    //     uint256 stakedDuration = block.number - number;

    //     console.log('stakedDuration', stakedDuration);

    //     console.log('rewardRate', rewardRate);

    //     console.log('ids', ids.length);

    //     uint256 rewards = ids.length * rewardRate * stakedDuration;

    //     console.log('rewards', rewards);
    //     // Claim the rewards
    //     masterChef.claimRewards(poolNftId);

    //     // Check if the reward has been minted to the user
    //     uint256 rewardBalance = snowToken.balanceOf(user);
    //     assertGt(rewardBalance, 0, "User should have rewards");
    // }
}
