// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SnowToken} from "../src/SnowToken.sol";
import {SnowNFTSale} from "../src/SnowNFTSale.sol";
import {SnowNFT} from "../src/SnowNFT.sol";
import {MasterChef} from "../src/MasterChef.sol";
import {Zap} from "../src/Zap.sol";
import {IPancakeRouter02} from "../src/interfaces/IPancakeRouter02.sol";
import {IPancakeFactory} from "../src/interfaces/IPancakeFactory.sol";

contract DeployScript is Script {
    SnowToken public snow;
    SnowNFT public nft;
    SnowNFTSale public nftSale;
    MasterChef public masterChef;
    Zap public zap;

    address private router = 0xa6AD18C2aC47803E193F75c3677b14BF19B94883; // Replace with actual router address (e.g., PancakeSwap router)
    address private wETH = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38; // Replace with actual WETH token address
    address private lpToken;

    // Add PancakeSwap Factory interface address
    address private factory = 0xEE4bC42157cf65291Ba2FE839AE127e3Cc76f741; // Replace with actual PancakeSwap Factory contract address
    address owner = 0x722bb88B96DDa8CbA209D8CD2c5eD6aD1a522352;

    address usdcAddress = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy SnowToken, SnowNFT, MasterChef, and Zap contracts
        snow = deploySnowToken();
        nft = deploySnowNFT();
        nft.setPrice(1 * 1e6);

        nftSale = deploySnowNFTSale(address(nft));

        depositNFTsToSale();

        masterChef = deployMasterChef(snow);

        snow.mint(owner, 10000000 * 1e18);
        // Create the SNOW/WETH pair via the PancakeSwap factory
        lpToken = createLiquidityPair(snow, wETH);

        zap = deployZap(router, masterChef, snow, wETH, lpToken);

        // Add the LP token to MasterChef
        masterChef.addPool(lpToken, 222, 0);
        masterChef.addPool(address(snow), 16, 0);
        masterChef.addPool(address(nft), 64, 0);

        // Set proxies in the SnowToken contract (if needed)
        snow.setProxy(router, true);
        snow.setProxy(address(masterChef), true);
        snow.setProxy(address(zap), true);
        snow.setPair(lpToken, true);
        snow.setAuthorized(address(masterChef), true);
        
        masterChef.setTokenType(address(snow), 1);
        masterChef.setTokenType(lpToken, 2);
        masterChef.setTokenType(address(nft), 3);
        masterChef.setZapAddress(address(zap));

        vm.stopBroadcast();
    }

    function depositNFTsToSale() internal {
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);
        nft.mint(owner);

        nft.setApprovalForAll(address(nftSale), true);

        uint256[] memory tokenIds = new uint256[](12);
        uint256[] memory prices = new uint256[](12);

        for (uint256 i = 0; i < 12; i++) {

            tokenIds[i] = i;
            prices[i] = 1 * 10**6;  
        }

        nftSale.depositMultipleNFTs(tokenIds, prices);
    }

    function deploySnowNFTSale(address nftAddr) internal returns (SnowNFTSale) {
        // Deploy SnowNFT contract
        SnowNFTSale _snowNFTSale = new SnowNFTSale(
           usdcAddress,
           nftAddr
        );
        console.log("SnowNFT Sale deployed at:", address(_snowNFTSale));
        return _snowNFTSale;
    }

    function deploySnowNFT() internal returns (SnowNFT) {
        // Deploy SnowNFT contract
        SnowNFT _snowNFT = new SnowNFT(
            "Snow NFT",
            "SNFT",
            "https://snowbank.io/images/nft/",
            usdcAddress
        );
        console.log("SnowNFT deployed at:", address(_snowNFT));
        return _snowNFT;
    }

    function deploySnowToken() internal returns (SnowToken) {
        // Deploy SnowToken contract
        SnowToken _snow = new SnowToken();
        console.log("SnowToken deployed at:", address(_snow));
        return _snow;
    }

    function deployMasterChef(SnowToken _snowToken) internal returns (MasterChef) {
        // Deploy MasterChef contract
        MasterChef _masterChef = new MasterChef(address(_snowToken));
        console.log("MasterChef deployed at:", address(_masterChef));
        return _masterChef;
    }

    function deployZap(
        address _router,
        MasterChef _masterChef,
        SnowToken _snowToken,
        address _wethToken,
        address _snowWETHPair
    ) internal returns (Zap) {
        // Deploy Zap contract
        Zap _zap = new Zap(
            _router,
            address(_masterChef),
            address(_snowToken),
            _wethToken,
            _snowWETHPair
        );
        console.log("Zap deployed at:", address(_zap));
        return _zap;
    }

    // Function to create a liquidity pair (SNOW/WETH) via PancakeSwap factory
    function createLiquidityPair(SnowToken _snow, address _weth) internal returns (address) {
        // Approve the router to spend user tokens for adding liquidity
        _snow.approve(router, 1000000 * 1e18);
        IERC20(wETH).approve(router, 5 * 1e18);

        // Add liquidity to the PancakeSwap pair (SNOW/WETH)
        uint256 amountSnow = 1000000 * 1e18; // Example amount of SNOW tokens
        uint256 amountWeth = 5 * 1e18; // Example amount of WETH tokens

        // Add liquidity using the PancakeSwap router (use a reasonable slippage amount)
        IPancakeRouter02(router).addLiquidity(
            address(_snow),
            wETH,
            amountSnow,
            amountWeth,
            0, // Min amount of SNOW tokens (slippage tolerance can be defined here)
            0, // Min amount of WETH tokens (slippage tolerance can be defined here)
            address(this), // Address that will receive the LP tokens
            block.timestamp + 600 // Set deadline (10 minutes from now)
        );

        IPancakeFactory pancakeFactory = IPancakeFactory(factory);
        address pair = pancakeFactory.getPair(address(_snow), _weth);

        if (pair == address(0)) {
            // Pair doesn't exist, so create it
            pair = pancakeFactory.createPair(address(_snow), _weth);
            console.log("New pair created: SNOW/WETH at address:", pair);
        } else {
            console.log("Pair already exists: SNOW/WETH at address:", pair);
        }
        return pair;
    }
}
