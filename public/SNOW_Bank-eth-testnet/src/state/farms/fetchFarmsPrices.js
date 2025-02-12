import BigNumber from "bignumber.js";
import { BIG_ONE, BIG_TEN, BIG_ZERO } from "utils/bigNumber";
import { filterFarmsByQuoteToken } from "utils/farmsPriceHelpers";
import { snowWethFarmPid, wplsUsdcFarmPid } from "config";

const getFarmFromTokenSymbol = (farms, tokenSymbol, preferredQuoteTokens) => {
  const farmsWithTokenSymbol = farms.filter(
    (farm) => farm.token.symbol === tokenSymbol
  );
  const filteredFarm = filterFarmsByQuoteToken(
    farmsWithTokenSymbol,
    preferredQuoteTokens
  );
  return filteredFarm;
};

const getFarmBaseTokenPrice = (
  farm,
  quoteTokenFarm,
  wplsPriceUsdt,
  snowPriceUsdc
) => {
  const hasTokenPriceVsQuote = Boolean(farm.tokenPriceVsQuote);
  if (["USDC", "MIM", "DAI"].includes(farm.quoteToken.symbol)) {
    return hasTokenPriceVsQuote
      ? new BigNumber(farm.tokenPriceVsQuote)
      : BIG_ZERO;
  }
  if (farm.quoteToken.symbol === "WPLS") {
    return hasTokenPriceVsQuote
      ? wplsPriceUsdt.times(farm.tokenPriceVsQuote)
      : BIG_ZERO;
  }
  if (farm.quoteToken.symbol === "SNOW") {
    return hasTokenPriceVsQuote
      ? snowPriceUsdc.times(farm.tokenPriceVsQuote)
      : BIG_ZERO;
  }

  // We can only calculate profits without a quoteTokenFarm for USDC/WPLS farms
  if (!quoteTokenFarm) {
    return BIG_ZERO;
  }

  // Possible alternative farm quoteTokens:
  // UST (i.e. MIR-UST), pBTC (i.e. PNT-pBTC), BTCB (i.e. bBADGER-BTCB), PLS (i.e. SUSHI-PLS)
  // If the farm's quote token isn't USDC or wWPLS, we then use the quote token, of the original farm's quote token
  // i.e. for farm PNT - pBTC we use the pBTC farm's quote token - WPLS, (pBTC - WPLS)
  // from the WPLS - pBTC price, we can calculate the PNT - USDC price
  if (quoteTokenFarm.quoteToken.symbol === "WPLS") {
    const quoteTokenInUsdc = wplsPriceUsdt.times(
      quoteTokenFarm.tokenPriceVsQuote
    );
    return hasTokenPriceVsQuote && quoteTokenInUsdc
      ? new BigNumber(farm.tokenPriceVsQuote).times(quoteTokenInUsdc)
      : BIG_ZERO;
  }

  if (["USDC", "MIM", "DAI"].includes(quoteTokenFarm.quoteToken.symbol)) {
    const quoteTokenInUsdc = quoteTokenFarm.tokenPriceVsQuote;
    return hasTokenPriceVsQuote && quoteTokenInUsdc
      ? new BigNumber(farm.tokenPriceVsQuote).times(quoteTokenInUsdc)
      : BIG_ZERO;
  }

  // Catch in case token does not have immediate or once-removed WMATIC/USDC quoteToken
  return BIG_ZERO;
};

const getFarmQuoteTokenPrice = (
  farm,
  quoteTokenFarm,
  wplsPriceUsdt,
  snowPriceUsdc
) => {
  if (["USDC", "MIM", "DAI"].includes(farm.quoteToken.symbol)) {
    return BIG_ONE;
  }
  if (farm.quoteToken.symbol === "SNOW") {
    return snowPriceUsdc;
  }
  if (farm.quoteToken.symbol === "WPLS") {
    return wplsPriceUsdt;
  }
  if (!quoteTokenFarm) {
    return BIG_ZERO;
  }

  if (quoteTokenFarm.quoteToken.symbol === "WPLS") {
    return quoteTokenFarm.tokenPriceVsQuote
      ? wplsPriceUsdt.times(quoteTokenFarm.tokenPriceVsQuote)
      : BIG_ZERO;
  }

  return BIG_ZERO;
};

const fetchFarmsPrices = async (farms) => {
  const wplsUsdtFarm = farms.find((farm) => farm.pid === wplsUsdcFarmPid);
  const wplsPriceUsdt =
    wplsUsdtFarm.tokenPriceVsQuote > 0
      ? BIG_ONE.div(wplsUsdtFarm.tokenPriceVsQuote).times(BIG_TEN.pow(new BigNumber(12)))
      : BIG_ZERO;

  const snowUsdtFarm = farms.find((farm) => farm.pid === snowWethFarmPid);
  const snowPriceUsdc =
    snowUsdtFarm.tokenPriceVsQuote > 0
      ? new BigNumber(snowUsdtFarm.tokenPriceVsQuote).times(wplsPriceUsdt)
      : BIG_ZERO;

  const farmsWithPrices = farms.map((farm) => {
    const quoteTokenFarm = getFarmFromTokenSymbol(
      farms,
      farm.quoteToken.symbol
    );
    const baseTokenPrice = getFarmBaseTokenPrice(
      farm,
      quoteTokenFarm,
      wplsPriceUsdt,
      snowPriceUsdc
    );
    const quoteTokenPrice = getFarmQuoteTokenPrice(
      farm,
      quoteTokenFarm,
      wplsPriceUsdt,
      snowPriceUsdc
    );

    const token = { ...farm.token, usdcPrice: baseTokenPrice.toJSON() };
    const quoteToken = {
      ...farm.quoteToken,
      usdcPrice: quoteTokenPrice.toJSON(),
    };
    return { ...farm, token, quoteToken };
  });

  return farmsWithPrices;
};

export default fetchFarmsPrices;
