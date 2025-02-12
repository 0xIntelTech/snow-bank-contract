import React from "react";
import useTokenBalance from "hooks/useTokenBalance";
import { getSNOWAddress } from "utils/addressHelpers";
import { toReadableAmount } from "utils/customHelpers";
import { BigNumber } from "bignumber.js";
import CardValue from "./CardValue";
import CardUsdValue from "./CardUsdValue";
import { useEthersSigner } from "hooks/useEthers";
import { usePriceSNOWUsdc } from "state/hooks";

const SNOWWalletBalance = () => {
  const signer = useEthersSigner();
  const { balance } = useTokenBalance(getSNOWAddress());
  const snowPriceUsdc = usePriceSNOWUsdc()[0];
  const usdBalance = new BigNumber(
    toReadableAmount(balance.toString(), 18)
  ).multipliedBy(snowPriceUsdc);

  if (!signer) {
    return (
      <div color="textDisabled" style={{ lineHeight: "54px" }}>
        Locked
      </div>
    );
  }

  return (
    <>
      <CardValue
        value={toReadableAmount(balance.toString(), 18)}
        color="#fff"
        lineHeight="36px"
      />
      <br />
      <CardUsdValue value={usdBalance.toNumber()} />
    </>
  );
};

export default SNOWWalletBalance;
