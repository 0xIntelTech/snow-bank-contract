// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ISnowNFT.sol";

contract SnowNFTSale is Ownable {
    using Address for address;

    // Struct to store NFT deposit information
    struct NFTDeposit {
        address owner;
        uint256 price; // Price of the NFT in usdc (ERC20 token)
    }

    // Mapping from token ID to NFT deposit info
    mapping(uint256 => NFTDeposit) public nftDeposits;

    // Array to store token IDs of NFTs currently for sale
    uint256[] public nftsOnSale;

    // Address of the usdc token contract
    IERC20 public usdc;

    // The address of the SnowNFT contract
    ISnowNFT public snowNFT;

    // Event for depositing NFT
    event NFTDeposited(address indexed owner, uint256 indexed tokenId, uint256 price);
    
    // Event for purchasing NFT
    event NFTPurchased(address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(address usdcAddress, address snowNFTAddress) Ownable(msg.sender) {
        usdc = IERC20(usdcAddress);
        snowNFT = ISnowNFT(snowNFTAddress);
    }

    function setPayTokenAdddress(address usdcAddress) external onlyOwner {
        usdc = IERC20(usdcAddress);
    }

    function setSnowNFTAddress(address snowNFTAddress) external onlyOwner {
        snowNFT = ISnowNFT(snowNFTAddress);
    }

    // Deposit multiple NFTs to the sale contract with custom prices
    function depositMultipleNFTs(uint256[] calldata tokenIds, uint256[] calldata prices) external {
        require(tokenIds.length == prices.length, "Arrays must have the same length");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            depositNFT(tokenIds[i], prices[i]);
        }
    }

    // Deposit a SnowNFT to the sale contract with a custom price
    function depositNFT(uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be greater than 0");

        // Check if the sender owns the NFT
        require(snowNFT.ownerOf(tokenId) == msg.sender, "You must own the NFT to deposit it");

        // Check if the sender has approved the contract to transfer the NFT
        require(snowNFT.isApprovedForAll(msg.sender, address(this)) || snowNFT.getApproved(tokenId) == address(this), "Contract not approved to transfer NFT");

        // Transfer the NFT to the contract
        snowNFT.safeTransferFrom(msg.sender, address(this), tokenId);

        // Update the deposit information
        nftDeposits[tokenId] = NFTDeposit({
            owner: msg.sender,
            price: price
        });

        // Add tokenId to the list of NFTs for sale
        nftsOnSale.push(tokenId);

        emit NFTDeposited(msg.sender, tokenId, price);
    }

    // Purchase multiple SnowNFTs from the sale contract
    function buyMultipleNFTs(uint256[] calldata tokenIds) external {
        uint256 totalPrice = 0;

        // Calculate total price for the NFTs
        for (uint256 i = 0; i < tokenIds.length; i++) {
            NFTDeposit memory deposit = nftDeposits[tokenIds[i]];
            require(deposit.owner != msg.sender, "Cannot buy your own NFT");
            totalPrice += deposit.price;
        }

        // Transfer total price from the buyer to the contract
        require(usdc.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");

        // Transfer NFTs to the buyer and mark them as sold
        for (uint256 i = 0; i < tokenIds.length; i++) {
            NFTDeposit memory deposit = nftDeposits[tokenIds[i]];

            // Transfer the NFT to the buyer
            snowNFT.safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            // Transfer the payment to the seller
            require(usdc.transfer(deposit.owner, deposit.price), "Payment to seller failed");

            // Remove the NFT from the sale list
            _removeNFTFromSaleList(tokenIds[i]);

            emit NFTPurchased(msg.sender, tokenIds[i], deposit.price);
        }
    }

    // Function to get all NFTs currently for sale
    function getNFTsOnSale() external view returns (uint256[] memory) {
        return nftsOnSale;
    }

    // Withdraw USDC balance to the owner (optional, in case of overpayment)
    function withdraw() external onlyOwner {
        uint256 balance = usdc.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");
        require(usdc.transfer(owner(), balance), "Transfer failed");
    }

    // Internal function to remove a token ID from the sale list
    function _removeNFTFromSaleList(uint256 tokenId) internal {
        // Find the index of the tokenId in the sale list
        uint256 index = 0;
        for (uint256 i = 0; i < nftsOnSale.length; i++) {
            if (nftsOnSale[i] == tokenId) {
                index = i;
                break;
            }
        }

        // Swap the last element with the element to be removed
        nftsOnSale[index] = nftsOnSale[nftsOnSale.length - 1];

        // Remove the last element from the array
        nftsOnSale.pop();
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
