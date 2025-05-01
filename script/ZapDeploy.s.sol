// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SnowToken} from "../src/SnowToken.sol";
import {SnowNFT} from "../src/SnowNFT.sol";
import {MasterChef} from "../src/MasterChef.sol";
import {Zap} from "../src/Zap.sol";
import {IPancakeRouter02} from "../src/interfaces/IPancakeRouter02.sol";
import {IPancakeFactory} from "../src/interfaces/IPancakeFactory.sol";

contract ZapDeployScript is Script {
    SnowToken public snow;
    SnowNFT public nft;
    MasterChef public masterChef;
    Zap public zap;

    address private router = 0xa6AD18C2aC47803E193F75c3677b14BF19B94883; // Replace with actual router address (e.g., PancakeSwap router)
    address private wETH = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38; // Replace with actual WETH token address
    address private lpToken = 0xcfF56258CCF9510BF16e6aD848fb058a7489186c;
    address private snowAddress = 0x1Fb00B65437509fe93D24712E0627820f4d06995;
    address private SnowNFTAddress = 0x5d74f1A4518864D6c04124ca076B040DA014513A;
    address private masterChefAddress = 0x6611a0723151889Abb3378dE8AB9cEdf372E04D8;
    address private factory = 0xEE4bC42157cf65291Ba2FE839AE127e3Cc76f741; // Replace with actual PancakeSwap Factory contract address
    address owner = 0xcaEC86D0D56a828Dc44f1d308Bf2200518d16c78;
    
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // Deploy SnowToken, SnowNFT, MasterChef, and Zap contracts
        snow = SnowToken(snowAddress);
        nft = SnowNFT(SnowNFTAddress);
        masterChef = MasterChef(masterChefAddress);
        zap = deployZap(router, masterChef, snow, wETH, lpToken);
        snow.setProxy(address(zap), true);
        masterChef.setZapAddress(address(zap));

        vm.stopBroadcast();
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
}
