import React from "react";
import BigNumber from "bignumber.js";
import { DEFAULT_TOKEN_DECIMAL } from "config";

import { usePriceWILDXUsdc } from "state/hooks";
import CardValue from "./CardValue";
import CardUsdValue from "./CardUsdValue";
import { useEthersSigner } from "hooks/useEthers";

const WILDXHarvestBalance = ({ farmsWithBalance }) => {
  const signer = useEthersSigner();
  const earningsSum = farmsWithBalance.reduce((accum, earning) => {
    const earningNumber = new BigNumber(earning.balance);
    if (earningNumber.eq(0)) {
      return accum;
    }
    return accum + earningNumber.div(DEFAULT_TOKEN_DECIMAL).toNumber();
  }, 0);
  const wildPriceUsdc = usePriceWILDXUsdc()[0];
  const earningsUsdt = new BigNumber(earningsSum)
    .multipliedBy(wildPriceUsdc)
    .toNumber();

  if (!signer) {
    return (
      <div color="textDisabled" style={{ lineHeight: "76px" }}>
        Locked
      </div>
    );
  }

  return (
    <div>
      <CardValue value={earningsSum} lineHeight="1.5" color="#fff" />
      {wildPriceUsdc.gt(0) && <CardUsdValue value={earningsUsdt} />}
    </div>
  );
};

export default WILDXHarvestBalance;
