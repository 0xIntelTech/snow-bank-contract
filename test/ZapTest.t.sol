// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPancakeRouter02} from "../src/interfaces/IPancakeRouter02.sol";
import {IPancakeFactory} from "../src/interfaces/IPancakeFactory.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import "../src/Zap.sol"; // Import the Zap contract
import "../src/MasterChef.sol"; // Import the MasterChef contract
import "../src/SnowToken.sol"; // Import the SnowToken contract

contract ERC20Mock is ERC20 {
    error ERC20WithdrawFailed(address recipient, uint256 value);

    constructor(uint256 initialSupply) ERC20("MockToken", "MTK") {
        _mint(msg.sender, initialSupply); // Mint initial supply to the sender
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function deposit() payable external {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint value) public {
        if (msg.sender == address(this)) {
            revert ERC20InvalidReceiver(msg.sender);
        }

        _burn(msg.sender, value);

        (bool _success,) = payable(msg.sender).call{value: value}("");
        if (!_success) {
            revert ERC20WithdrawFailed(msg.sender, value);
        }
    }
}

contract ZapTest is Test {
    using SafeERC20 for IERC20;

    Zap public zap;
    MasterChef public masterChef;
    SnowToken public snowToken;
    IWETH wethToken;
    address public user;
    address public user1;
    address public owner;
    uint256 public poolId;
    uint256 public poolId2;
    address public constant BURN_ADDRESS = address(0xdead);
    // Add PancakeSwap Factory interface address
    address private factory = 0xEE4bC42157cf65291Ba2FE839AE127e3Cc76f741; // Replace with actual PancakeSwap Factory contract address
    address private router = 0xa6AD18C2aC47803E193F75c3677b14BF19B94883; // Replace with actual router address (e.g., PancakeSwap router)
    address private wETH = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38; // Replace with actual WETH token address
    address private pair = address(0);
    address scUSDAddress = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;

    event LiquidityAdded(
        address indexed user,
        uint256 amountInETH,
        uint256 liquidity
    );
    event TokensSwapped(
        address indexed user,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut
    );

    function setUp() public {
        // Set up the owner and user addresses
        owner = address(this);
        user = address(0x123);
        vm.deal(user, 3000 * 1e18);
        vm.deal(owner, 3000 * 1e18);
        // Deploy MockERC20 for SNOW token and MockWETH token
        wethToken = IWETH(wETH);
        // wETH = address(wethToken);

        snowToken = new SnowToken();

        // Deploy the MasterChef contract
        masterChef = new MasterChef(address(snowToken));

        // Fund the user with SNOW and WETH
        snowToken.mint(user, 2000 * 1e18);

        vm.startPrank(user);
        wethToken.deposit{value: 1000 * 1e18}();
        vm.stopPrank();

        snowToken.mint(owner, 2000 * 1e18);

        vm.startPrank(owner);
        wethToken.deposit{value: 1000 * 1e18}();
        vm.stopPrank();

        // Approve the router to spend user tokens for adding liquidity
        IERC20(address(snowToken)).approve(router, 1000 * 1e18);
        IERC20(wETH).approve(router, 1000 * 1e18);

        // Add liquidity to the PancakeSwap pair (SNOW/WETH)
        uint256 amountSnow = 500 * 1e18; // Example amount of SNOW tokens
        uint256 amountWeth = 500 * 1e18; // Example amount of WETH tokens

        // Add liquidity using the PancakeSwap router (use a reasonable slippage amount)
        IPancakeRouter02(router).addLiquidity(
            address(snowToken),
            wETH,
            amountSnow,
            amountWeth,
            0, // Min amount of SNOW tokens (slippage tolerance can be defined here)
            0, // Min amount of WETH tokens (slippage tolerance can be defined here)
            user, // Address that will receive the LP tokens
            block.timestamp + 600 // Set deadline (10 minutes from now)
        );

        IPancakeFactory pancakeFactory = IPancakeFactory(factory);
        pair = pancakeFactory.getPair(address(snowToken), wETH);

        if (pair == address(0)) {
            // Pair doesn't exist, so create it
            pair = pancakeFactory.createPair(address(snowToken), wETH);
            console.log("New pair created: SNOW/WETH at address:", pair);
        } else {
            console.log("Pair already exists: SNOW/WETH at address:", pair);
        }

        // Deploy the Zap contract with the addresses of the required tokens
        zap = new Zap(
            router,
            address(masterChef),
            address(snowToken),
            wETH,
            pair
        );

        snowToken.setPair(pair, true);
        snowToken.setProxy(address(zap), true);
        snowToken.setProxy(router, true);
        snowToken.setProxy(address(masterChef), true);
        snowToken.setAuthorized(address(masterChef), true);

        masterChef.setTokenType(address(snowToken), 1);
        masterChef.setTokenType(pair, 2);
        masterChef.setZapAddress(address(zap));

         // Create a pool in MasterChef for staking
        poolId = 1;
        masterChef.addPool(address(pair), 10, 0); // Add pool with rewardRate=1e18 and no deposit fee

        poolId2 = 2;
        masterChef.addPool(address(snowToken), 10, 0); // Add pool with rewardRate=1e18 and no deposit fee
    }

    function testZapIn() public {
        uint256 amountInETH = 1 * 1e18;

        // User calls zapIn to convert ETH/WETH and add liquidity
        vm.startPrank(user);
        IERC20(wETH).approve(address(zap), amountInETH);
        zap.zapIn{value: amountInETH}(poolId2, address(0), amountInETH); // Swap ETH and add liquidity (false for ETH)
        vm.stopPrank();

        // Check if LP tokens are staked in the MasterChef contract
        uint256 stakedAmount = masterChef.getStakedERC20Amount(poolId2, user);
        console.log('stakedAmount', stakedAmount);
        assertGt(stakedAmount, 0, "Staked amount should be greater than 0");

        // // Check if liquidity was added
        // uint256 balance = IERC20(address(snowToken)).balanceOf(user);
        // assertGt(balance, 0, "User should have SNOW token balance");
    }


    function testSwapScUSD() public {
        uint256 amountIn = 1 * 1e18;
        uint256 snowBalanceBefore= IERC20(scUSDAddress).balanceOf(user);
        uint256 wethBalanceBefore = IERC20(wETH).balanceOf(user);
        uint256 beforebalance = user.balance;
        // User calls swapTokens to swap WETH to SNOW
        vm.startPrank(user);
        IERC20(wETH).approve(address(zap), amountIn);
        zap.swapTokens(wETH, scUSDAddress, amountIn, 0);
        vm.stopPrank();

        // Check if the WETH balance was decreased and SNOW balance increased
        uint256 wethBalanceAfter = IERC20(wETH).balanceOf(user);
        uint256 snowBalanceAfter = IERC20(scUSDAddress).balanceOf(user);

        console.log('scUSDAddress', snowBalanceBefore, snowBalanceAfter);

        vm.startPrank(user);
        IERC20(scUSDAddress).approve(address(zap), snowBalanceAfter);
        zap.swapTokens(scUSDAddress, wETH, snowBalanceAfter, 0);
        vm.stopPrank();

        uint256 wethBalanceAfter1 = IERC20(wETH).balanceOf(user);
        uint256 snowBalanceAfter1 = IERC20(scUSDAddress).balanceOf(user); 

        console.log('scUSDAddress', snowBalanceAfter, snowBalanceAfter1);

        assertGt(
            wethBalanceAfter1,
            wethBalanceAfter,
            "ETH balance should increase"
        );
        //assertGt(snowBalanceAfter, snowBalanceBefore, "SNOW balance should increase");
    }

    function testSwapTokens() public {
        uint256 amountIn = 5 * 1e18;
        uint256 snowBalanceBefore= snowToken.balanceOf(user);
        uint256 wethBalanceBefore = IERC20(wETH).balanceOf(user);
        uint256 beforebalance = user.balance;
        // User calls swapTokens to swap WETH to SNOW
        vm.startPrank(user);
        IERC20(wETH).approve(address(zap), amountIn);
        zap.swapTokens(wETH, address(0), amountIn, 0);
        vm.stopPrank();

        // Check if the WETH balance was decreased and SNOW balance increased
        uint256 wethBalanceAfter = IERC20(wETH).balanceOf(user);
        uint256 snowBalanceAfter = snowToken.balanceOf(user);
        uint256 afterbalance = user.balance;
        console.log('testSwapTokens', beforebalance, afterbalance);
        assertGt(
            afterbalance,
            beforebalance,
            "ETH balance should increase"
        );
        //assertGt(snowBalanceAfter, snowBalanceBefore, "SNOW balance should increase");
    }

    function testSwapEthToWeth() public {
        uint256 amountIn = 1 * 1e18;
        uint256 wethBalanceBefore = IERC20(wETH).balanceOf(user);
        uint256 beforebalance = user.balance;
        // User calls swapTokens to swap WETH to SNOW
        vm.startPrank(user);
        zap.swapTokens{value: amountIn}(address(0), wETH, amountIn, 0);
        vm.stopPrank();

        // Check if the WETH balance was decreased and SNOW balance increased
        uint256 wethBalanceAfter = IERC20(wETH).balanceOf(user);
        uint256 afterbalance = user.balance;
        console.log('testSwapTokens', beforebalance, afterbalance);
        assertGt(
            wethBalanceAfter,
            wethBalanceBefore,
            "ETH balance should increase"
        );
        //assertGt(snowBalanceAfter, snowBalanceBefore, "SNOW balance should increase");
    }

    function testSwapSnowToken() public {
        uint256 amountIn = 1 * 1e18;
        uint256 snowBalanceBefore = snowToken.balanceOf(user);
        uint256 wethBalanceBefore = IERC20(wETH).balanceOf(user);
        // User calls swapTokens to swap WETH to SNOW
        vm.startPrank(user);
        snowToken.approve(address(zap), amountIn);
        zap.swapTokens(address(snowToken), address(wethToken), amountIn, 0);
        vm.stopPrank();

        // Check if the WETH balance was decreased and SNOW balance increased
        uint256 wethBalanceAfter = IERC20(wETH).balanceOf(user);
        uint256 snowBalanceAfter = snowToken.balanceOf(user);
        uint256 burnBalanceAfter = snowToken.balanceOf(BURN_ADDRESS);

        console.log("Burn Balance", burnBalanceAfter);

        assertGt(
            snowBalanceBefore,
            snowBalanceAfter,
            "Snow balance should decrease"
        );

        assertGt(
            wethBalanceAfter,
            wethBalanceBefore,
            "WETH balance should decrease"
        );

        assertGt(burnBalanceAfter, 0, "Burn balance should increase");
    }

    function testSwapLpToTokens() public {
        uint256 amountIn = 1 * 1e18;

        vm.deal(user, 1000 * 1e18);

        uint256 beforebalance = IERC20(pair).balanceOf(user);

        vm.startPrank(user);
        snowToken.approve(address(zap), amountIn);
        zap.swapTokens(
            address(snowToken),
            address(pair),
            amountIn,
            0
        ); // Swap ETH to SNOW
        vm.stopPrank();

        uint256 afterbalance = IERC20(pair).balanceOf(user);
        uint256 snowb1 = snowToken.balanceOf(user);
        vm.startPrank(user);
        IERC20(pair).approve(address(zap), afterbalance);

        // (uint256 amountTokenA, uint256 amountTokenB) = IPancakeRouter02(router).removeLiquidity(
        //     address(snowToken),      // Token A is SnowToken
        //     address(wethToken),                    // Token B is wETH
        //     afterbalance,               // The liquidity amount you want to remove
        //     0,                       // Minimum amount of wETH
        //     0,                       // Minimum amount of SnowToken
        //     address(this),           // Send the tokens to this contract
        //     block.timestamp + 40
        // );
        // console.log('removeLiquidity', amountTokenA, amountTokenB);
        zap.swapTokens(
            address(pair),
            address(scUSDAddress),
            afterbalance,
            0
        ); // Swap ETH to SNOW
        vm.stopPrank();

        uint256 snowb2 = snowToken.balanceOf(user);
        uint256 afterbalance1 = IERC20(pair).balanceOf(user);
        console.log('testSwapTokensToLp difference', afterbalance - afterbalance1);
        console.log('testSwapTokensToLp snow difference', snowb2 - snowb1);

        assertGt(afterbalance, beforebalance, "Balance should increase");
    }

    function testSwapTokensToLp() public {
        uint256 amountIn = 1 * 1e18;

        vm.deal(user, 1000 * 1e18);

        uint256 beforebalance = IERC20(pair).balanceOf(user);

        vm.startPrank(user);
        wethToken.approve(address(zap), amountIn);
        zap.swapTokens(address(wethToken), scUSDAddress, amountIn, 0);

        uint256 usdbalance = IERC20(scUSDAddress).balanceOf(user);    
        IERC20(scUSDAddress).approve(address(zap), usdbalance);
        zap.swapTokens(
            scUSDAddress,
            address(pair),
            usdbalance,
            0
        ); // Swap ETH to SNOW
        vm.stopPrank();

        uint256 usdcAfterbalance = IERC20(scUSDAddress).balanceOf(user);
        uint256 afterbalance = IERC20(pair).balanceOf(user);
        console.log('testSwapTokensToLp difference', afterbalance - beforebalance);

        assertEq(usdcAfterbalance, 0, "Balance should 0");
    }

    // function testSwapTokensETHToWETH() public {
    //     uint256 amountIn = 1 * 1e18;

    //     vm.deal(user, 1000 * 1e18);
    //     // User calls swapTokens to swap ETH to SNOW
    //     uint256 wethTokenBalanceBefore = wethToken.balanceOf(user);

    //     vm.startPrank(user);
    //     zap.swapTokens{value: amountIn}(
    //         address(0),
    //         address(wethToken),
    //         amountIn,
    //         0
    //     ); // Swap ETH to SNOW
    //     vm.stopPrank();

    //     // Check if ETH was swapped correctly and SNOW balance increased
    //     uint256 wethTokenBalance = wethToken.balanceOf(user);
    //     console.log('testSwapTokensETHToWETH difference', wethTokenBalance - wethTokenBalanceBefore);
    //     assertGt(wethTokenBalance, wethTokenBalanceBefore, "Weth balance should increase");
    // }

    // function testNormalSwap() public {
    //     user1 = address(0x1);
    //     wethToken.mint(user1, 100 * 1e18);
    //     snowToken.mint(user1, 1000 * 1e18);
    //     vm.startPrank(user1);

    //     address[] memory path = new address[](2);
    //     path[0] = address(snowToken);
    //     path[1] = address(wETH);

    //     uint256 snowBalanceBefore = snowToken.balanceOf(user1);
    //     uint256 burnBalanceBefore = snowToken.balanceOf(BURN_ADDRESS);

    //     IPancakeRouter02(router).swapExactTokensForTokens(
    //             10 * 1e18,
    //             0,
    //             path,
    //             user1,
    //             block.timestamp + 40
    //     );

    //     uint256 snowBalanceAfter = snowToken.balanceOf(user1);
    //     uint256 burnBalanceAfter = snowToken.balanceOf(BURN_ADDRESS);
    //     assertLt(snowBalanceAfter, snowBalanceBefore, "SNOW balance should decrease");
    //     assertLt(burnBalanceAfter, burnBalanceBefore, "SNOW balance should increase");
    //     vm.stopPrank();
    // }

    // function testWithdraw() public {
    //     uint256 amountToWithdraw = 10 * 1e18;

    //     // Withdraw ETH or SNOW from the contract owner
    //     zap.withdraw(address(snowToken), amountToWithdraw);
    //     uint256 ownerBalance = snowToken.balanceOf(owner);
    //     assertEq(
    //         ownerBalance,
    //         amountToWithdraw,
    //         "Owner should receive the withdrawn amount"
    //     );
    // }
}
