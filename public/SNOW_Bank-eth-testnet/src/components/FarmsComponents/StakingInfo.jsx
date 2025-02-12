import React, { useState, useCallback } from "react";

import { useFarmsWithBalance } from "hooks/useFarmsWithBalance";
import SNOWHarvestBalance from "./Staking/SNOWHarvestBalance";
import SNOWWalletBalance from "./Staking/SNOWWalletBalance";
import CurrentSaleTax from "./Staking/CurrentSaleTax";
import CompoundModal from "./CompoundModal";
import { useAccount } from "wagmi";
import BigNumber from "bignumber.js";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { DEFAULT_TOKEN_DECIMAL } from "config";
import Loading from "components/Loading";
import { harvestMany } from "utils/callHelpers";
import { useMasterchef } from "hooks/useContract";

export default function FarmStaking() {
  const [pendingTx, setPendingTx] = useState(false);
  const [compoundPendingTx, setCompoundPendingTx] = useState(false);
  const [open, setOpen] = useState(false);
  const [pids, setPids] = useState([]);
  const masterChefContract = useMasterchef();

  const { address } = useAccount();
  const farmsWithBalance = useFarmsWithBalance();
  const balancesWithValue = farmsWithBalance.filter((balanceType) =>
    balanceType.balance.gt(0)
  );

  const earningsSum = farmsWithBalance.reduce((accum, earning) => {
    const earningNumber = new BigNumber(earning.balance);
    if (earningNumber.eq(0)) {
      return accum;
    }
    return accum + earningNumber.div(DEFAULT_TOKEN_DECIMAL).toNumber();
  }, 0);
  const harvestAllFarms = useCallback(async () => {
    setPendingTx(true);
    try {
      let _pids = [];
      // eslint-disable-next-line no-restricted-syntax
      for (const farmWithBalance of balancesWithValue) {
        _pids.push(farmWithBalance.pid);
      }
      if (_pids.length > 0) {
        // eslint-disable-next-line no-await-in-loop
        const res = await harvestMany(masterChefContract, _pids, address);
        // const res = await onReward(false);
        if (res === false) {
          setPendingTx(false);
          return;
        }
      }
    } catch (error) {
      console.log(error);
    }
    setPendingTx(false);
  }, [address, balancesWithValue, masterChefContract]);
  function openModal() {
    let _pids = [];
    // eslint-disable-next-line no-restricted-syntax
    for (const farmWithBalance of balancesWithValue) {
      _pids.push(farmWithBalance.pid);
    }
    setPids(_pids);
    setOpen(true);
  }

  function closeModal() {
    setOpen(false);
  }
  return (
    <div className="flex-1 p-8 rounded-md snows">
      <div className="text-3xl text-end font-semibold mb-5 h-3.5">
        Farms & Staking
      </div>
      <div className=" mt-9">
        <div className="text-base font-semibold text-right">
          Current Sales Tax:
        </div>
        <div className="mb-1">
          <div className="flex justify-end">
            <CurrentSaleTax />
          </div>
          <span className="text-[11px] text-right">
            ( Sales tax burns all of the SNOW automatically. The sales tax will
            drop over the next week to 8% )
          </span>
        </div>
      </div>
      <div className="flex items-center justify-between">
        <div className="text-base pb-2 font-semibold">SNOW to Harvest:</div>
        <div className="text-sm text-gray-300">
          <SNOWHarvestBalance farmsWithBalance={balancesWithValue} />
        </div>
      </div>

      <div className="mt-5 flex flex-col md:flex-row justify-between gap-3">
        {address ? (
          <>
            <button
              id="harvest-all"
              disabled={balancesWithValue.length <= 0 || pendingTx}
              className="rounded-full w-full box-btn-stake"
              onClick={harvestAllFarms}
            >
              {pendingTx ? (
                <Loading />
              ) : (
                `Harvest all ( ${balancesWithValue.length} )`
              )}
            </button>
            <button
              id="compound-all"
              disabled={balancesWithValue.length <= 0}
              onClick={openModal}
              className="rounded-full w-full box-btn-stake"
            >
              {compoundPendingTx ? (
                <Loading />
              ) : (
                `Compound all ( ${balancesWithValue.length} )`
              )}
            </button>
          </>
        ) : (
          <ConnectButton />
        )}
      </div>
      {open && (
        <CompoundModal
          open={open}
          closeModal={closeModal}
          earnings={earningsSum}
          pid={pids}
          isAll={true}
        />
      )}
    </div>
  );
}
