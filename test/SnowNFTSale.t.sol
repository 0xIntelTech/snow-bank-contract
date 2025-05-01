// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SnowNFTSale.sol"; // Import the NFTSale contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Mock/MockSnowNFT.sol";
import "./Mock/ERC20Mock.sol";

// Define the test contract
contract NFTSaleTest is Test {
    // Declare state variables for the contracts
    SnowNFTSale public nftSale;
    MockSnowNFT public mockSnowNFT;
    IERC20 public scUSD;
    address public owner;
    address public user;

    uint256 public tokenId1;
    uint256 public tokenId2;

    function setUp() public {
        // Set up addresses for testing
        owner = address(1);
        user = address(2);

        vm.startPrank(owner);
        // Deploy the mock contracts
        mockSnowNFT = new MockSnowNFT();
        
        // Deploy the scUSD ERC20 token (using an existing contract or mock one)
        scUSD = IERC20(address(new ERC20Mock(1 * 10 ** 6)));
        
        // Deploy the NFTSale contract
        nftSale = new SnowNFTSale(address(scUSD), address(mockSnowNFT));
        
        // Mint two NFTs for the owner
        tokenId1 = mockSnowNFT.mint(owner);
        tokenId2 = mockSnowNFT.mint(owner);
        vm.stopPrank();
    }

    function testDepositNFT() public {
        // The owner deposits NFT1 with a price
        uint256 price = 1 * 10 ** 6; // 1 scUSD
        vm.startPrank(owner); // Simulate the owner interacting with the contract
        mockSnowNFT.approve(address(nftSale), tokenId1); // Approve NFT for transfer
        nftSale.depositNFT(tokenId1, price); // Deposit NFT
        vm.stopPrank();

        // Check if the NFT is in the deposit list
        uint256[] memory nftsForSale = nftSale.getNFTsOnSale();
        assertEq(nftsForSale.length, 1, "NFTs on sale should be 1");
        assertEq(nftsForSale[0], tokenId1, "Token ID should match the deposited NFT");

        // Verify deposit info
        (address downer, uint256 dprice) = nftSale.nftDeposits(tokenId1);
        assertEq(downer, owner, "Owner should be the correct address");
        assertEq(dprice, price, "Price should match the deposit price");
    }

    function testNonOwnerDeposit() public {
        uint256 price = 1 * 10 ** 6; // 1 scUSD
        uint256 tokenId = mockSnowNFT.mint(user); // Mint NFT to the user

        vm.startPrank(user); // Simulate the user interacting with the contract
        mockSnowNFT.approve(address(nftSale), tokenId); // Approve the NFT for transfer
        vm.expectRevert("You must own the NFT to deposit it");
        nftSale.depositNFT(tokenId, price); // This should fail as user is not the owner
        vm.stopPrank();
    }

    function testBuyNFT() public {
        // Deposit NFTs first
        uint256 price1 = 1 * 10 ** 6;
        uint256 price2 = 2 * 10 ** 6;
        vm.startPrank(owner); 
        mockSnowNFT.approve(address(nftSale), tokenId1);
        nftSale.depositNFT(tokenId1, price1); 
        mockSnowNFT.approve(address(nftSale), tokenId2);
        nftSale.depositNFT(tokenId2, price2);
        vm.stopPrank();

        // Simulate the user buying NFTs
        vm.startPrank(user);
        
        // Transfer 3 scUSD to the user and approve it for the sale
        ERC20Mock(address(scUSD)).mint(user, 3 * 10 ** 6); // Mint 3 scUSD to user
        scUSD.approve(address(nftSale), 3 * 10 ** 6); // Approve the sale contract

        uint256[] memory tokensToBuy = new uint256[](2);
        tokensToBuy[0] = tokenId1;
        tokensToBuy[1] = tokenId2;

        nftSale.buyMultipleNFTs(tokensToBuy); // User buys both NFTs

        vm.stopPrank();

        // Verify the NFTs are transferred to the user
        assertEq(mockSnowNFT.ownerOf(tokenId1), user, "NFT1 should be owned by the buyer");
        assertEq(mockSnowNFT.ownerOf(tokenId2), user, "NFT2 should be owned by the buyer");
    }

    function testInsufficientFundsBuyNFT() public {
        // Deposit NFTs first
        uint256 price1 = 1 * 10 ** 6;
        uint256 price2 = 2 * 10 ** 6;
        vm.startPrank(owner); 
        mockSnowNFT.approve(address(nftSale), tokenId1);
        nftSale.depositNFT(tokenId1, price1); 
        mockSnowNFT.approve(address(nftSale), tokenId2);
        nftSale.depositNFT(tokenId2, price2);
        vm.stopPrank();

        // Simulate the user trying to buy NFTs without enough funds
        vm.startPrank(user);
        
        // Transfer only 2 scUSD to the user and approve it for the sale
        ERC20Mock(address(scUSD)).mint(user, 2 * 10 ** 6); // Mint 2 scUSD to user
        scUSD.approve(address(nftSale), 2 * 10 ** 6); // Approve the sale contract

        uint256[] memory tokensToBuy = new uint256[](2);
        tokensToBuy[0] = tokenId1;
        tokensToBuy[1] = tokenId2;

        vm.expectRevert("Payment failed");
        nftSale.buyMultipleNFTs(tokensToBuy); // This should fail due to insufficient funds

        vm.stopPrank();
    }

    function testWithdraw() public {
        // Deposit an NFT and have it for sale
        uint256 price = 1 * 10 ** 6;
        vm.startPrank(owner);
        mockSnowNFT.approve(address(nftSale), tokenId1);
        nftSale.depositNFT(tokenId1, price);
        vm.stopPrank();

        // User buys the NFT
        vm.startPrank(user);
        ERC20Mock(address(scUSD)).mint(user, 1 * 10 ** 6); // Mint 1 scUSD to user
        scUSD.approve(address(nftSale), 1 * 10 ** 6); // Approve the sale contract
        uint256[] memory tokensToBuy = new uint256[](1);
        tokensToBuy[0] = tokenId1;
        nftSale.buyMultipleNFTs(tokensToBuy);
        vm.stopPrank();

        // Withdraw the collected funds to the owner
        vm.startPrank(owner);
        nftSale.withdraw();
        vm.stopPrank();
    }

    function testReentrancyProtection() public {
        // Deploy a malicious contract to test reentrancy
        address malicious = address(new MaliciousContract(nftSale, scUSD, tokenId1));
        vm.startPrank(owner);
        mockSnowNFT.approve(address(nftSale), tokenId1);
        nftSale.depositNFT(tokenId1, 1 * 10 ** 6);
        vm.stopPrank();

        // Try buying the NFT through the malicious contract
        vm.startPrank(malicious);
        ERC20Mock(address(scUSD)).mint(malicious, 1 * 10 ** 6);
        scUSD.approve(address(nftSale), 1 * 10 ** 6);
        uint256[] memory tokensToBuy = new uint256[](1);
        tokensToBuy[0] = tokenId1;
        vm.expectRevert("Payment failed");
        nftSale.buyMultipleNFTs(tokensToBuy);
        vm.stopPrank();
    }
}

contract MaliciousContract {
    SnowNFTSale public nftSale;
    IERC20 public scUSD;
    uint256 public tokenId;
    
    constructor(SnowNFTSale _nftSale, IERC20 _scUSD, uint256 _tokenId) {
        nftSale = _nftSale;
        scUSD = _scUSD;
        tokenId = _tokenId;
    }
    
    // This contract would exploit reentrancy if there was no protection
    function buy() external {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        nftSale.buyMultipleNFTs(tokenIds);
    }
}
