
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockSnowNFT is ERC721 {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MockSnowNFT", "MSNFT") {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _mint(to, tokenId);
        return tokenId;
    }
}