// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SnowNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    string private _baseTokenURI;
    string public baseExtension = ".png";
    
    // Address of the usdc token contract
    IERC20 public usdc;

    // Event for minting
    event Minted(address indexed owner, uint256 indexed tokenId, string tokenURI);
    // Event for burning
    event Burned(address indexed owner, uint256 indexed tokenId);

    // Event for successful purchase
    event Purchased(address indexed buyer, uint256 indexed tokenId);

    // Price of 1 NFT in usdc (1 $)
    uint256 public price = 1 * 10 ** 6; // Assuming usdc has 18 decimals (like USDT)

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address usdcAddress // usdc token contract address
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseTokenURI;
        usdc = IERC20(usdcAddress);
    }

    function setPrice(uint256 _price) external onlyOwner {
         price = _price;
    }

    function setPayToken(address usdcAddress) external onlyOwner {
         usdc = IERC20(usdcAddress);
    }

    // Token URI
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    // Base URI for token metadata (override if needed)
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Mint function for the NFT (only owner can call it)
    function mint(address to) external onlyOwner {
        uint256 tokenId = _tokenIdCounter;
        _mint(to, tokenId);

        // Optional: Store unique token metadata URI for each NFT.
        string memory tokenURI = string(abi.encodePacked(Strings.toString(tokenId), baseExtension));
        _setTokenURI(tokenId, tokenURI);

        _tokenIdCounter++;
        emit Minted(to, tokenId, tokenURI);
    }

    // Set the base URI (only owner can change it)
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // Allow NFT owner to burn their own token
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        _burn(tokenId);
        emit Burned(msg.sender, tokenId);
    }

    // Buy function: user pays 1 usdc to receive an NFT
    function buy() external {
        // Transfer 1 usdc from the buyer to the contract
        require(usdc.transferFrom(msg.sender, address(this), price), "Payment failed");

        // Mint an NFT to the buyer
        uint256 tokenId = _tokenIdCounter;
        _mint(msg.sender, tokenId);

        // Set the token URI
        string memory tokenURI = string(abi.encodePacked(Strings.toString(tokenId), baseExtension));
        _setTokenURI(tokenId, tokenURI);

        _tokenIdCounter++;

        emit Minted(msg.sender, tokenId, tokenURI);
        emit Purchased(msg.sender, tokenId);
    }

    function totalSupply() external view returns (uint256){
        return _tokenIdCounter;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        uint256 balance = balanceOf(owner);
        require(index < balance, "Index out of bounds");
        
        uint256 tokenId;
        uint256 counter = 0;
        
        // Iterate through all tokens to find the one owned by the `owner` at the `index`
        for (uint256 i = 0; i < _tokenIdCounter; i++) {
            if (ownerOf(i) == owner) {
                if (counter == index) {
                    tokenId = i;
                    break;
                }
                counter++;
            }
        }

        return tokenId;
    }

    // Withdraw usdc balance to owner (after collecting payments)
    function withdraw() external onlyOwner {
        uint256 balance = usdc.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");
        require(usdc.transfer(owner(), balance), "Transfer failed");
    }
}
