import React from "react";
import { getSNOWAddress, getWethAddress } from "utils/addressHelpers";
import { BASE_SWAP_URL } from "config";
import FarmStaking from "./StakingInfo";
import TotalValueLocked from "components/FarmsComponents/TotalValueLocked";

export default function FarmBanner() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 sm:my-16 gap-2">
      <div className="flex flex-col items-center justify-center w-full snows">
        <div className="flex items-center flex-col">
          <h1 className="sm:text-5xl text-3xl mt-3">Snow Bank</h1>
          <p className="my-3">
            The best place to Stake Snow Tokens & Earn Yield
          </p>
        </div>

        <div className="flex items-center flex-col w-3/4 mt-6">
          <div className="flex items-center justify-center gap-2 w-full sm:px-4">
            <button
              disabled
              className="w-full h-[40px!important]  box-btn-stake py-[8px!important]"
              href={`${BASE_SWAP_URL}?inputCurrency=${getWethAddress()}&outputCurrency=${getSNOWAddress()}`}
              target="_blank"
            >
              Buy SNOW
            </button>
            <button
              disabled
              className="w-full h-[40px!important]  box-btn-stake py-[8px!important]"
              href={`${BASE_SWAP_URL}?inputCurrency=${getWethAddress()}&outputCurrency=${getSNOWAddress()}`}
              target="_blank"
            >
              Buy BILL
            </button>
          </div>
        </div>
      </div>
      <FarmStaking />
      <TotalValueLocked />
    </div>
  );
}
