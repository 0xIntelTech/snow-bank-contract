// ref_010625: github.com/0xLancerLab/snow_bank_masterchef.git
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./node_modules/@openzeppelin/contracts/utils/Address.sol";
import "./node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ISnowLib.sol";

// contract SNOWNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
contract SnowNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------- */
    /* GLOBALS - house
    /* -------------------------------------------------------- */
    string public tVERSION = '0.4';
    bool private FIRST_ = true;
    address public ADDR_CONF; // set via CONF_setConfig
    ISnowConfig private CONF; // set via CONF_setConfig

    string private TOK_SYMB = string(abi.encodePacked("tSNFT", tVERSION));
    string private TOK_NAME = string(abi.encodePacked("tSNOW NFT_", tVERSION));
    string private constant INIT_BASE_URI = "https://snowbank.io/images/nft/";

    /* -------------------------------------------------------- */
    /* GLOBALS - legacy
    /* -------------------------------------------------------- */
    string public baseURI; // ex: "https://snowbank.io/images/nfts/" _ w/ token: https://snowbank.io/images/nfts/01.png
    string public baseExtension = ".png"; // w/ token id: "01.png"
    bool public paused = false;
    address public DAI = address(0xefD766cCb38EaF1dfd701853BFCe31359239F305); // weDAI (ie. dai from ethereum)
    // address public devAddress; // house: moved to CONF
    // address public treasuryAddress; // house: moved to CONF
    uint256 public NFTPrice = 300 * 10 ** 18;

    mapping(uint256 => bool) public minted;
    // mapping(address => bool) public whitelisted; // house: legacy dead code
    mapping(uint256 => address) public ownerOfToken;
    // mapping(address => uint256) public maxMintAmountPerUser; // house: legacy dead code

    event Received(address, uint);

    // constructor(
    //     string memory _name,
    //     string memory _symbol,
    //     string memory _initBaseURI,
    //     address _devAddress,
    //     address _treasuryAddress
    // ) ERC721(_name, _symbol) Ownable(msg.sender) {
    //     setBaseURI(_initBaseURI);
    //     devAddress = _devAddress;
    //     treasuryAddress = _treasuryAddress;
    // }
    constructor() ERC721(TOK_NAME, TOK_SYMB) Ownable(msg.sender) {
        baseURI = INIT_BASE_URI;
    }

    /* -------------------------------------------------------- */
    /* MODIFIERS - house
    /* -------------------------------------------------------- */
    modifier onlyKeeper() {
        require(msg.sender == CONF.KEEPER(), "!keeper :p");
        _;
    }
    modifier onlyChef() { 
        require(msg.sender == CONF.KEEPER() || msg.sender == CONF.ADDR_CHEF(), " not chef :p");
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
    /* legacy
    /* -------------------------------------------------------- */
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function buyNFT(uint256 _tokenId) external payable nonReentrant {
        require(!paused);
        require(minted[_tokenId] == false, "This tokenId is already minted.");
        require(
            IERC20(DAI).balanceOf(msg.sender) >= NFTPrice,
            "You don't have sufficient balance to purchase NFT"
        );
        IERC20(DAI).safeTransferFrom(msg.sender, CONF.ADDR_DEV_EOA(), NFTPrice / 10);
        IERC20(DAI).safeTransferFrom(msg.sender, CONF.ADDR_TREAS_EOA(), NFTPrice.mul(900).div(1000));
        ownerOfToken[_tokenId] = msg.sender;
        minted[_tokenId] = true;
        _safeMint(msg.sender, _tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        ownerOfToken[tokenId] = to;
        super._transfer(from, to, tokenId);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyKeeper {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyKeeper {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyKeeper {
        paused = _state;
    }

    function withdraw() external onlyKeeper {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdrawExtraToken(address _token) external onlyKeeper {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // function setDevAddress(address _devAddress) public {
    //     require(msg.sender == devAddress, "You are not the cto");
    //     devAddress = _devAddress;
    // }

    // function setTreasuryAddress(address _treasuryAddress) public {
    //     require(msg.sender == _treasuryAddress, "You are not the ceo");
    //     treasuryAddress = _treasuryAddress;
    // }

    function setDAIAddress(address _DAI) public onlyConfig {
        require(_DAI != address(0), "Invalid Address");
        DAI = address(_DAI);
    }

    function setNFTPrice(uint256 _newPrice) public onlyConfig {
        require(_newPrice > 0, "Invalid price");
        NFTPrice = _newPrice.mul(1e18);
    }
}
