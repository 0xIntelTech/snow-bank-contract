import React from "react";
import BigNumber from "bignumber.js";
import { DEFAULT_TOKEN_DECIMAL } from "config";

import { usePriceSNOWUsdc } from "state/hooks";
import CardValue from "./CardValue";
import CardUsdValue from "./CardUsdValue";
import { useEthersSigner } from "hooks/useEthers";

const SNOWXHarvestBalance = ({ farmsWithBalance }) => {
  const signer = useEthersSigner();
  const earningsSum = farmsWithBalance.reduce((accum, earning) => {
    const earningNumber = new BigNumber(earning.balance);
    if (earningNumber.eq(0)) {
      return accum;
    }
    return accum + earningNumber.div(DEFAULT_TOKEN_DECIMAL).toNumber();
  }, 0);
  const snowPriceUsdc = usePriceSNOWUsdc()[0];
  const earningsUsdt = new BigNumber(earningsSum)
    .multipliedBy(snowPriceUsdc)
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
      {snowPriceUsdc.gt(0) && <CardUsdValue value={earningsUsdt} />}
    </div>
  );
};

export default SNOWXHarvestBalance;
