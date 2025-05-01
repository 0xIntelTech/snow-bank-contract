// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakePairV2.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ISnowToken.sol";
import "./MasterChef.sol"; // Import the MasterChef contract

contract Zap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    IPancakeRouter02 public router;
    MasterChef public masterChef;
    ISnowToken public snowToken;
    IWETH public wethToken;

    address public snowWETHPair;

    event LiquidityAdded(
        address indexed user,
        uint256 amountInETH,
        uint256 liquidity
    );

    event TokensTaxBurned(
        address indexed user,
        address fromToken,
        address toToken,
        uint256 amountTax
    );

    event TokensSwapped(
        address indexed user,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut
    );

    event Received(address sender, uint amount);

    constructor(
        address _router,
        address _masterChef,
        address _snowToken,
        address _wethToken,
        address _snowWETHPair
    ) Ownable(msg.sender) {
        router = IPancakeRouter02(_router);
        masterChef = MasterChef(_masterChef);
        snowToken = ISnowToken(_snowToken);
        wethToken = IWETH(_wethToken);
        snowWETHPair = _snowWETHPair;
    }

    function updateSettings(
        address _router,
        address _masterChef,
        address _snowToken,
        address _wethToken,
        address _snowWETHPair
    ) external onlyOwner {
        router = IPancakeRouter02(_router);
        masterChef = MasterChef(_masterChef);
        snowToken = ISnowToken(_snowToken);
        wethToken = IWETH(_wethToken);
        snowWETHPair = _snowWETHPair;
    }

    function zapIn(
        uint poolId,
        address fromToken,
        uint256 amountIn
    ) external payable nonReentrant {
        require(amountIn > 0, "Amount must be greater than 0");

        // Handle ETH or WETH as input
        if (fromToken == address(0)) {
            require(msg.value == amountIn, "Incorrect ETH amount sent");
            wethToken.deposit{value: amountIn}();
        } else {
            IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
            IERC20(fromToken).approve(address(router), amountIn);
            if (fromToken != address(wethToken)) {
                address[] memory path = new address[](2);
                path[0] = address(fromToken);
                path[1] = address(wethToken);

                uint256[] memory amounts = router.swapExactTokensForTokens(
                    amountIn,
                    0,
                    path,
                    address(this),
                    block.timestamp + 40
                );
                amountIn = amounts[amounts.length - 1];      
            }
        }

        (address src, , , , ) = masterChef.getPoolInfo(poolId);
        if (masterChef.getTokenType(src) == 2) {
            uint256 liquidity = _zapToLp(address(wethToken), amountIn);
            // Stake the LP token in the MasterChef
            IERC20(snowWETHPair).approve(address(masterChef), liquidity);
            masterChef.stakeFromZap(poolId, liquidity, msg.sender);
        } else if (masterChef.getTokenType(src) == 1) {
            // erc20            
            uint256 outputAmount = amountIn;
            if (src != address(wethToken)){
                wethToken.approve(address(router), amountIn);
                address[] memory path = new address[](2);
                path[0] = address(wethToken);
                path[1] = address(src);

                uint256[] memory amounts = router.swapExactTokensForTokens(
                    amountIn,
                    0,
                    path,
                    address(this),
                    block.timestamp + 40
                );
                outputAmount = amounts[amounts.length - 1];
            }
            IERC20(src).approve(address(masterChef), outputAmount);
            masterChef.stakeFromZap(poolId, outputAmount, msg.sender);
        } else {
            revert("the pool is not correct");
        }
    }

    function _zapToLp(
        address fromToken,
        uint256 amountIn
    ) internal returns (uint256) {
        // Swap ETH or WETH to SNOW and add liquidity
        uint256 halfAmount = amountIn / 2;
        uint256 snowAmount;
        uint256 wethAmount;

        // Declare and initialize the path array for swaps
        address[] memory path = new address[](2);

        // Swap ETH/WETH to SNOW
        if (fromToken == address(wethToken)) {
            // WETH to SNOW
            wethToken.approve(address(router), halfAmount);
            path[0] = address(wethToken);
            path[1] = address(snowToken);

            uint256[] memory amounts = router.swapExactTokensForTokens(
                halfAmount,
                0,
                path,
                address(this),
                block.timestamp + 40
            );
            wethAmount = halfAmount;
            snowAmount = amounts[amounts.length - 1];
        } else if (fromToken == address(snowToken)) {
            snowToken.approve(address(router), halfAmount);
            path[0] = address(snowToken);
            path[1] = address(wethToken);
            uint256[] memory amounts = router.swapExactTokensForTokens(
                halfAmount,
                0,
                path,
                address(this),
                block.timestamp + 40
            );
            snowAmount = halfAmount;
            wethAmount = amounts[amounts.length - 1];
        }

        // Add liquidity to Snow/WETH or Snow/ETH pool
        wethToken.approve(address(router), wethAmount);
        snowToken.approve(address(router), snowAmount);

        uint256 liquidity;

        (, , liquidity) = router.addLiquidity(
            address(snowToken),
            address(wethToken),
            snowAmount,
            wethAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        emit LiquidityAdded(msg.sender, amountIn, liquidity);

        return liquidity;
    }

    function _zapLPtowETH(address fromToken, uint256 liquidity, bool isEthOut) internal returns (uint256) {
        IERC20(fromToken).approve(address(router), liquidity);
        (uint256 amountTokenA, uint256 amountTokenB) = router.removeLiquidity(
            address(snowToken),      // Token A is SnowToken
            address(wethToken),                    // Token B is wETH
            liquidity,               // The liquidity amount you want to remove
            0,                       // Minimum amount of wETH
            0,                       // Minimum amount of SnowToken
            address(this),           // Send the tokens to this contract
            block.timestamp + 40
        );

        uint256[] memory amountOuts;

        if (isEthOut) {
            // Swap SnowToken to wETH
            amountOuts = _swapTokens(address(snowToken), address(wethToken), amountTokenA);
            return amountOuts[amountOuts.length - 1] + amountTokenB;
        } else {
            // Swap wETH to SnowToken
            amountOuts = _swapTokens(address(wethToken), address(snowToken), amountTokenB);
            return amountOuts[amountOuts.length - 1] + amountTokenA;
        }
    }

    function _swapTokens(address fromToken, address toToken, uint256 amountIn) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;

        // Approve router and perform swap
        IERC20(fromToken).approve(address(router), amountIn);
        return router.swapExactTokensForTokens(
            amountIn, 
            0, // Minimum output amount
            path, 
            address(this), 
            block.timestamp + 40
        );
    }

    function swapTokens(
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOutMin
    ) external payable nonReentrant returns (uint256) {
        require(amountIn > 0, "Amount must be greater than 0");

        bool isReceived = false;
        // Handle LP Token Type for 'fromToken'
        if (masterChef.getTokenType(fromToken) == 2) {
            uint256 outPutWeth;
            bool isEthOut = toToken == address(wethToken);
            IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);

            if (isEthOut || toToken == address(snowToken)) {
                outPutWeth = _zapLPtowETH(fromToken, amountIn, isEthOut);
                IERC20(toToken).safeTransfer(msg.sender, outPutWeth);
                emitTokensSwapped(msg.sender, fromToken, toToken, amountIn, outPutWeth);
                return outPutWeth;
            } else {
                outPutWeth = _zapLPtowETH(fromToken, amountIn, true);
                amountIn = outPutWeth;
                fromToken = address(wethToken); // Set fromToken to WETH for further swapping
                isReceived = true;
            }
        }

        // Handle WETH to ETH Swap
        if (fromToken == address(wethToken) && toToken == address(0)) {
            if (!isReceived) IERC20(wethToken).transferFrom(msg.sender, address(this), amountIn);
            return _swapWethToEth(amountIn);
        }

        // Handle ETH to WETH and other token swaps
        if (fromToken == address(0)) {
            _wrapETHToWeth(amountIn);
            if (toToken == address(wethToken)){
                IERC20(toToken).safeTransfer(msg.sender, amountIn);
                // Emit successful swap event
                emitTokensSwapped(msg.sender, fromToken, toToken, amountIn, amountIn);
                return amountIn;
            }
            fromToken = address(wethToken); // Set fromToken to WETH for further swapping            
        } else {
            if (!isReceived) {
                IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
            }
        }

        // Handle SNOW Token tax
        if (fromToken == address(snowToken)) {
            amountIn = _handleSnowTokenTax(amountIn);
        }

        // Handle LP Token Type for 'toToken'
        if (masterChef.getTokenType(toToken) == 2) {
            if (fromToken != address(snowToken) && fromToken != address(wethToken)){
                IERC20(fromToken).safeIncreaseAllowance(address(router), amountIn);
                address[] memory path = new address[](2);
                path[0] = fromToken;
                path[1] = address(wethToken);
                uint256[] memory amountOs = router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 40);
                amountIn = amountOs[amountOs.length - 1];
                fromToken = address(wethToken);
            } 
            uint256 liquidity = _zapToLp(fromToken, amountIn);
            IERC20(toToken).safeTransfer(msg.sender, liquidity);
            emitTokensSwapped(msg.sender, fromToken, toToken, amountIn, liquidity);
            return liquidity;
        }

        uint256[] memory amounts;
        IERC20(fromToken).safeIncreaseAllowance(address(router), amountIn);
        if (toToken == address(0)){
            address[] memory path = new address[](2);
            path[0] = fromToken;
            path[1] = address(wethToken);
            amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 40);
            return _swapWethToEth(amounts[amounts.length - 1]);
        } else {
            // Perform the swap via the router
            address[] memory path = _getSwapPath(fromToken, toToken);
            amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp + 40);
        }

        // Emit successful swap event
        emitTokensSwapped(msg.sender, fromToken, toToken, amountIn, amounts[amounts.length - 1]);
        return amounts[amounts.length - 1];
    }

    function _swapWethToEth(uint256 amountIn) internal returns (uint256) {
        wethToken.withdraw(amountIn);
        payable(msg.sender).transfer(amountIn); // Send ETH to the caller
        emitTokensSwapped(msg.sender, address(wethToken), address(0), amountIn, amountIn);
        return amountIn;
    }

    function _wrapETHToWeth(uint256 amountIn) internal {
        require(msg.value == amountIn, "Incorrect ETH amount sent");
        wethToken.deposit{value: amountIn}();
    }

    function _handleSnowTokenTax(uint256 amountIn) internal returns (uint256) {
        uint256 taxAmount = (amountIn * snowToken.sales_tax()) / 1000;
        uint256 amountAfterTax = amountIn - taxAmount;

        snowToken.transfer(snowToken.BURN_ADDRESS(), taxAmount); // Burn the tax

        // Emit event for tax burned
        emit TokensTaxBurned(msg.sender, address(snowToken), address(0), taxAmount);

        return amountAfterTax;
    }

    function _getSwapPath(address fromToken, address toToken) internal view returns (address[] memory path) {
        if (fromToken == address(wethToken)) {
            path = new address[](2);      
            path[0] = address(wethToken);
            path[1] = toToken;
        } else if (toToken == address(wethToken)) {
            path = new address[](2); 
            path[0] = fromToken;
            path[1] = address(wethToken);
        } else {
            path = new address[](3); 
            path[0] = fromToken;
            path[1] = address(wethToken);
            path[2] = toToken;
        }
        return path;
    }

    function emitTokensSwapped(
        address sender, 
        address fromToken, 
        address toToken, 
        uint256 amountIn, 
        uint256 amountOut
    ) internal {
        emit TokensSwapped(sender, fromToken, toToken, amountIn, amountOut);
    }

    // Withdraw any mistakenly sent ETH or tokens to the contract owner
    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
    }

    // The receive function is executed when ETH is sent to the contract
    receive() external payable {
        // Emit an event whenever ETH is received
        emit Received(msg.sender, msg.value);
    }

    // Fallback function (optional), triggered when non-ETH data is sent to the contract
    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
}
