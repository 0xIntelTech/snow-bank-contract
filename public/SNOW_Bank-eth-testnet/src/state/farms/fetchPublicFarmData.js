import BigNumber from "bignumber.js";
import masterchefABI from "config/abis/masterchef.json";
import erc20 from "config/abis/erc20.json";
import { getMasterChefAddress } from "utils/addressHelpers";
import { BIG_TEN, BIG_ZERO } from "utils/bigNumber";
import multicall from "utils/multicall";
import nftABI from "config/abis/nft.json";
import { getMasterchefContract } from "utils/contractHelpers";
import httpProvider from "utils/providerHelpers";
import { toReadableAmount } from "utils/customHelpers";

const fetchPublicFarmData = async (farm) => {
  const { pid, lpAddresses, token, quoteToken, isNFTPool } = farm;
  const lpAddress = lpAddresses;
  const calls = [
    // Balance of token in the LP contract
    {
      address: token.address,
      name: "balanceOf",
      params: [farm.isTokenOnly ? getMasterChefAddress() : lpAddress],
    },
    // Balance of quote token on LP contract
    {
      address: quoteToken.address,
      name: "balanceOf",
      params: [farm.isTokenOnly ? getMasterChefAddress() : lpAddress],
    },
    // Balance of LP tokens in the master chef contract
    {
      address: lpAddress,
      name: "balanceOf",
      params: [getMasterChefAddress()],
    },
    // Total supply of LP tokens
    {
      address: lpAddress,
      name: "totalSupply",
    },
  ];

  const [tokenBalanceLP, quoteTokenBalanceLP, lpTokenBalanceMC, lpTotalSupply] =
    await multicall(isNFTPool ? nftABI : erc20, calls);
  let tokenAmountTotal;
  let quoteTokenAmountTotal = BIG_ZERO;
  let lpTotalInQuoteToken = BIG_ZERO;
  let tokenPriceVsQuote = BIG_ZERO;
  const tokenDecimals = 18;
  const quoteTokenDecimals = 18;

  if (farm.isNFTPool) {
    const masterChef = getMasterchefContract(httpProvider);
    tokenAmountTotal = new BigNumber(lpTokenBalanceMC);
    const amountPerNFT = await masterChef.getAmountPerNFT();
    if (new BigNumber(tokenBalanceLP).comparedTo(0) > 0) {
      tokenPriceVsQuote = new BigNumber(Number(toReadableAmount(amountPerNFT)));
    }
    lpTotalInQuoteToken = new BigNumber(Number(toReadableAmount(amountPerNFT))).times(
      tokenBalanceLP
    );
  } else if (!farm.isNFTPool && farm.isTokenOnly) {
    tokenAmountTotal = new BigNumber(lpTokenBalanceMC).div(
      BIG_TEN.pow(token.decimals)
    );
    const tokenBalance = new BigNumber(tokenBalanceLP).div(
      BIG_TEN.pow(token.decimals)
    );
    const quoteTokenBalance = new BigNumber(quoteTokenBalanceLP).div(
      BIG_TEN.pow(token.decimals)
    );
    const stables = ["USDC", "MIM", "DAI"];
    if (
      stables.includes(farm.token.symbol) &&
      stables.includes(farm.quoteToken.symbol)
    ) {
      tokenPriceVsQuote = new BigNumber(1);
    } else if (new BigNumber(tokenBalanceLP).comparedTo(0) > 0) {
      tokenPriceVsQuote = quoteTokenBalance.div(new BigNumber(tokenBalance));
    }
    lpTotalInQuoteToken = tokenAmountTotal.times(tokenPriceVsQuote);
  } else {
    // Ratio in % of LP tokens that are staked in the MC, vs the total number in circulation
    const lpTokenRatio = new BigNumber(lpTokenBalanceMC).div(
      new BigNumber(lpTotalSupply)
    );

    // Raw amount of token in the LP, including those not staked
    const tokenAmountMC = new BigNumber(tokenBalanceLP).div(
      BIG_TEN.pow(tokenDecimals)
    );
    tokenAmountTotal = tokenAmountMC.times(lpTokenRatio);

    const quoteTokenAmountMC = new BigNumber(quoteTokenBalanceLP).div(
      BIG_TEN.pow(quoteTokenDecimals)
    );
    quoteTokenAmountTotal = quoteTokenAmountMC.times(lpTokenRatio);

    if (new BigNumber(quoteTokenBalanceLP).comparedTo(0) > 0) {
      // Total value in staking in quote token value
      lpTotalInQuoteToken = new BigNumber(quoteTokenBalanceLP)
        .div(new BigNumber(10).pow(quoteTokenDecimals))
        .times(new BigNumber(2))
        .times(lpTokenRatio);
    }

    if (tokenAmountMC.comparedTo(0) > 0) {
      tokenPriceVsQuote = quoteTokenAmountMC.div(tokenAmountMC);
    } else if (new BigNumber(tokenBalanceLP).comparedTo(0) > 0) {
      tokenPriceVsQuote = new BigNumber(quoteTokenBalanceLP).div(
        new BigNumber(tokenBalanceLP)
      );
    }
  }

  const hasPid = pid || pid === 0;

  // Only make masterchef calls if farm has pid
  const [info, totalAllocPoint] = hasPid
    ? await multicall(masterchefABI, [
        {
          address: getMasterChefAddress(),
          name: "poolInfo",
          params: [pid],
        },
        {
          address: getMasterChefAddress(),
          name: "totalAllocPoint",
        },
      ])
    : [null, null];

  const allocPoint = info.allocPoint
    ? new BigNumber(info.allocPoint?._hex)
    : BIG_ZERO;
  const depositFee = info.depositFeeBP
    ? new BigNumber(info.depositFeeBP)
    : BIG_ZERO;
  const poolWeight = totalAllocPoint
    ? allocPoint.div(new BigNumber(totalAllocPoint))
    : BIG_ZERO;

  // TODO Remove on production
  // if(farm.pid === 0) tokenPriceVsQuote = BIG_ONE
  const publicData = {
    tokenBalanceLP: new BigNumber(tokenBalanceLP).toJSON(),
    quoteTokenBalanceLP: new BigNumber(quoteTokenBalanceLP).toJSON(),
    tokenAmountTotal: tokenAmountTotal.toJSON(),
    quoteTokenAmountTotal: quoteTokenAmountTotal.toJSON(),
    lpTokenBalanceMC: new BigNumber(lpTokenBalanceMC).toJSON(),
    lpTotalSupply: new BigNumber(lpTotalSupply).toJSON(),
    lpTotalInQuoteToken: lpTotalInQuoteToken.toJSON(),
    tokenPriceVsQuote: tokenPriceVsQuote.toJSON(),
    poolWeight: poolWeight.toJSON(),
    multiplier: `${allocPoint.div(10).toString()}X`,
    depositFee: depositFee.div(100).toString(),
    withDepositLockDiscount: info.withDepositLockDiscount,
  };

  return publicData;
};

export default fetchPublicFarmData;
