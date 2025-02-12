import React from "react";
import { useTotalSupply } from "hooks/useTokenBalance";
import { usePriceSNOWUsdc, useTotalValue } from "state/hooks";
import CardValue from "./Staking/CardValue";
import { convertCurrency, toReadableAmount } from "utils/customHelpers";
import { useContractRead, erc20ABI } from "wagmi";
import { getSNOWAddress, getWethAddress } from "utils/addressHelpers";
import snowABI from "config/abis/snow.json";

export default function TotalValueLocked() {
  const tvlData = useTotalValue();
  const tvl = tvlData
    ? tvlData.toLocaleString("en-US", { maximumFractionDigits: 1 })
    : 0;
  const liquidity = usePriceSNOWUsdc()[1];
  const marketCap = usePriceSNOWUsdc()[2];

  const totalSupply = useTotalSupply();
  // 0xeAA13b4f85A98E6CcaF65606361BD590e98DE2Cb
  const tokenABalanceRead = useContractRead({
    address: getSNOWAddress(),
    abi: snowABI,
    functionName: "balanceOf",
    args: ["0x000000000000000000000000000000000000dead"],
    chainId: 359,
  });
  // const snowBalanceRead = useContractRead({
  //   address: getSNOWAddress(),
  //   abi: snowABI,
  //   functionName: "balanceOf",
  //   args: ["0xeAA13b4f85A98E6CcaF65606361BD590e98DE2Cb"],
  //   chainId: 359,
  // });

  // const snowBalanceReadMasterChef = useContractRead({
  //   address: getSNOWAddress(),
  //   abi: erc20ABI,
  //   functionName: "balanceOf",
  //   args: ["0xeAA13b4f85A98E6CcaF65606361BD590e98DE2Cb"],
  //   chainId: 359,
  // });

  const totalMinted =
    totalSupply - toReadableAmount(tokenABalanceRead?.data, 18);

  return (
    <div className="flex-1 p-8 rounded-md snows">
      <div className="text-3xl text-right mb-5">Snow Bank Stats</div>

      <div className="text-base text-right font-semibold">Total Staked</div>
      <div className="mb-5">
        {tvlData !== null ? (
          <div
            color="#fff"
            className="text-[40px] font-semibold text-right pb-3"
          >
            {`$${tvl}`}
          </div>
        ) : (
          <div />
        )}
      </div>
      <div className="flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <p className="font-semibold">Liquidity</p>
          <div className="h-30 ">
            {liquidity > 0 ? (
              <span className="text-[20px] font-semibold">
                $ {convertCurrency(liquidity)}
              </span>
            ) : (
              <div />
            )}
          </div>
        </div>
        <div className="flex items-center justify-between">
          <p className="font-semibold">Market Cap</p>
          <div className="h-30 ">
            {marketCap > 0 ? (
              <span className="text-[20px] font-semibold">
                $ {convertCurrency(marketCap)}
              </span>
            ) : (
              <div />
            )}
          </div>
        </div>
        <div className="flex items-center justify-between">
          <p className="font-semibold">Total Burned</p>
          <div>
            {toReadableAmount(tokenABalanceRead?.data, 18) && (
              <CardValue
                fontSize="20px"
                decimals={1}
                value={Number(toReadableAmount(tokenABalanceRead?.data, 18))}
                color="#fffff"
              />
            )}
          </div>
        </div>
        <div className="flex items-center justify-between">
          <p className="font-semibold">Circulating Supply</p>
          <div>
            {totalSupply && (
              <CardValue
                fontSize="20px"
                value={totalMinted}
                decimals={1}
                color="#fffff"
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
