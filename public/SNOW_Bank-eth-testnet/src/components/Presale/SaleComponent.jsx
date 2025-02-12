import React, { useState } from "react";
import {
  didUserReject,
  fromReadableAmount,
  toReadableAmount,
} from "utils/customHelpers";
import { useAccount, useNetwork } from "wagmi";
import { notify } from "utils/toastHelper";
import { usePresaleContract } from "hooks/useContract";
import LogoLoading from "../LogoLoading";
import SNOW from "components/UI/SNOW";
import ETH from "components/UI/ETH";
import { useEffect } from "react";
import { useEthersSigner } from "hooks/useEthers";
import { TREASURY } from "config";
import {
  ref,
  push,
  query,
  onValue,
  update,
  get,
  equalTo,
  orderByChild,
} from "firebase/database";
import { db } from "config/firebase";
import { ethers } from "ethers";
import { MAX_PER_USER } from "config";
import PLS from "components/UI/PLS";

export default function SaleComponent({ saleData }) {
  const presaleContract = usePresaleContract();
  const { chain } = useNetwork();
  const { address } = useAccount();
  const [ethPrice, setEthPrice] = useState(2100);
  const [pendingTx, setPendingTx] = useState(false);
  const [ethAmount, setEthAmount] = useState("");
  const [amount, setAmount] = useState("");
  const [snowAmount, setSnowAmount] = useState("");
  const [balance, setBalance] = useState(0);
  const signer = useEthersSigner();
  const [withdrow, setWithdraw] = useState(0);
  const [deposits, setDeposits] = useState(0);

  const getBalance = async () => {
    const data = await signer.getBalance();
    const readableData = toReadableAmount(data.toString(), 18);
    setBalance(Number(readableData));
  };

  const handleChangePLS = (value) => {
    setAmount(value);
    setEthAmount(value);
    const ethSnowAmount = Number(
      ((value * ethPrice) / (saleData?.presalePriceOfToken / 100)).toFixed(8)
    );
    setSnowAmount(ethSnowAmount);
  };

  const handleChangeSnow = (value) => {
    setSnowAmount(value);
    const ethBuyAmount = Number(
      ((value * (saleData?.presalePriceOfToken / 100)) / ethPrice).toFixed(8)
    );
    setEthAmount(ethBuyAmount);
  };

  const getPLSPrice = async () => {
    const priceData = await fetch(
      "https://min-api.cryptocompare.com/data/price?fsym=PLS&tsyms=USD"
    );
    const res = await priceData.json();
    if (res && res.USD) {
      const price = res.USD;
      setEthPrice(Number(price));
    }
  };

  const handleBuySnow = async () => {
    if (!address) {
      notify("error", "Please connect your wallet");
      return;
    }

    // if (!saleData?.enabled) {
    //   notify("error", "Presale is not started yet");
    //   return;
    // }

    if (saleData?.sale_finalized) {
      notify("error", "Presale is ended");
      return;
    }

    if (ethPrice === 0) {
      notify("error", "PLS price fetch failed.");
      return;
    }

    if (!ethAmount) {
      notify("error", "Please input the correct amount to buy.");
      return;
    }

    if (ethAmount >= Number(balance)) {
      notify("error", "You dont't have enough balance to buy.");
      return;
    }

    if (snowAmount > MAX_PER_USER) {
      notify("error", "Exceed max SNOW Amount.");
      return;
    }

    try {
      setPendingTx(true);
      const tx = await presaleContract.buySNOW({
        from: address,
        value: fromReadableAmount(Number(ethAmount).toFixed(8)),
      });

      await tx.wait();
      setPendingTx(false);

      notify("success", `You bought ${snowAmount} SNOW successfully`);

      // const dbRef = ref(db, "/transactions");
      // push(dbRef, {
      //   address: address,
      //   amount: ethAmount,
      //   withdrow: snowAmount,
      // })
      //   .then(() => {
      //     const dbQuery = query(ref(db, "/stats"));

      //     get(dbQuery).then((snapshot) => {
      //       const exist = snapshot.val();
      //       if (exist) {
      //         const dbRef = ref(db, `/stats/${Object.keys(exist)[0]}`);
      //         update(dbRef, {
      //           eth: exist[Object.keys(exist)[0]].pls + Number(ethAmount),
      //         });
      //       }
      //     });
      //   })
      //   .catch((error) => {
      //     console.error("Error saving transaction:", error);
      //   });
      getBalance();
      getDeposits(address);
    } catch (error) {
      setPendingTx(false);
      if (didUserReject(error)) {
        notify("warning", "User Rejected transaction");
        return;
      } else {
        notify("warning", error.reason);
        return;
      }
    }
  };

  const getDeposits = (address) => {
    const dbQuery = query(
      ref(db, "transactions"),
      orderByChild("address"),
      equalTo(address)
    );

    onValue(dbQuery, async (snapshot) => {
      const exist = snapshot.val();
      if (exist) {
        let snowAmount = 0;
        let depositAmont = 0;
        Object.keys(exist).map((id) => {
          snowAmount += Number(exist[id].withdrow);
          depositAmont += Number(exist[id].amount);
        });
        setWithdraw(snowAmount);
        setDeposits(depositAmont);
      }
    });
  };

  useEffect(() => {
    getPLSPrice();
    if (signer) {
      getBalance();
      getDeposits(address);
    }
  }, [signer, chain, address]);

  return (
    <>
      <div className="w-full snow_effect px-4 py-4">
        <div className="balance_form">
          <div className="mt-8 mb-6">
            <div className="flex justify-between mb-3 px-1">
              <div>Snow Price:</div>
              <div>
                <p className="flex gap-1">
                  <span className="font-semibold">
                    {saleData?.presalePriceOfToken} cents
                  </span>
                </p>
              </div>
            </div>
            <div className="flex justify-between mb-3 px-1">
              <div> Bought:</div>
              <div className="flex gap-1">
                {saleData?.SNOWOwned
                  ? Number(saleData?.SNOWOwned).toFixed(2)
                  : "0.00"}{" "}
                <SNOW width={15} height={15} />
              </div>
            </div>
            <div className="flex justify-between mb-3 px-1">
              <div> Deposited ETH:</div>
              <div className="flex gap-1">
                {deposits ? Number(deposits).toFixed(5) : "0.00"}{" "}
                <ETH width={15} height={15} />
              </div>
            </div>
            <div className="flex justify-between mb-3 px-1">
              <div> Deposited PLS:</div>
              <div className="flex gap-1">
                {saleData?.user_deposits
                  ? Number(saleData?.user_deposits).toFixed(5)
                  : "0.00"}{" "}
                <PLS width={15} height={15} />
              </div>
            </div>
            <div className="flex justify-between mb-3 px-1">
              <div>Balance:</div>
              <div className="flex gap-1">
                {Number(balance).toFixed(5) === "NaN"
                  ? "0.00"
                  : Number(balance).toFixed(5)}
                <PLS width={15} height={15} />
              </div>
            </div>
          </div>
          <div className="flex gap-3 mb-2">
            <div className="flex gap-1 bg-primary/20 rounded-md border-secondary hover:border-white border duration-300 w-full relative">
              <img
                src="/assets/tokens/snow.png"
                className={`w-[38px] h-[38px] my-auto ml-1`}
              />

              <input
                className="w-full py-3.5 bg-transparent text-sm px-2 hover:outline-none focus-visible:outline-none focus-visible:border-white/70"
                type="number"
                placeholder="Input SNOW amount"
                value={snowAmount}
                onChange={(e) => handleChangeSnow(e.target.value)}
              />
              <button
                className="bg-secondary shadow shadow-black hover:bg-secondary/90 hover:shadow-xl duration-200 absolute right-1 top-1/2 -translate-y-1/2 p-1 px-2 rounded-lg text-sm h-8"
                onClick={() => {
                  setEthAmount((100000 * 0.04) / ethPrice);
                  setSnowAmount(100000);
                }}
              >
                max
              </button>
            </div>
            <div className="flex gap-1 bg-primary/20 rounded-md border-secondary hover:border-white border duration-300 w-full relative">
              <img
                src="/assets/tokens/pls.svg"
                className={`w-[38px] h-[38px] my-auto ml-1`}
              />
              <input
                className="py-3.5 bg-transparent text-sm w-full px-2 hover:outline-none focus-visible:outline-none  focus-visible:border-white/70"
                type="number"
                placeholder="Input PLS amount"
                value={ethAmount}
                onChange={(e) => handleChangePLS(e.target.value)}
              />
              <button
                className="bg-secondary shadow shadow-black  hover:bg-secondary/90 hover:shadow-xl duration-200 absolute right-1 top-1/2 -translate-y-1/2 p-1 px-2 rounded-lg text-sm h-8"
                onClick={() => {
                  setEthAmount((100000 * 0.04) / ethPrice);
                  setSnowAmount(100000);
                }}
              >
                max
              </button>
            </div>
          </div>

          <input
            className="accent-[#204253] flex-auto w-full border-transparent mb-3 bg-primary/20"
            type="range"
            w-full="true"
            min="0"
            max={MAX_PER_USER}
            step="1"
            value={snowAmount}
            onChange={(e) => {
              handleChangeSnow(e.target.value);
            }}
            list="tickmarks1"
          />

          <div className="bg-primary/20 rounded-lg p-3 mb-3 text-sm">
            <div className="flex gap-2 justify-between mt-1">
              <p className="text-sm">SNOW</p>
              <div className="flex gap-1">
                <SNOW /> {snowAmount ? snowAmount : "0.00"}
              </div>
            </div>
            <div className="flex gap-2 justify-between mt-1">
              <p className="text-sm">PLS</p>
              <div className="flex gap-1">
                <PLS /> {ethAmount ? ethAmount : "0.00"}
              </div>
            </div>
            <div className="flex gap-2 justify-between mt-1">
              <p className="text-sm">PLS Price:</p>
              <div className="flex gap-1">$ ~{ethPrice}</div>
            </div>
            <hr className="mt-1 border-white/30 border-[0.5px]" />
            <div className="flex gap-2 justify-between mt-1">
              <p className="text-sm">USD Amount</p>
              <div className="flex gap-1">
                {ethAmount ? (
                  <>
                    {ethPrice} * {ethAmount.toFixed(4)} = $ ~
                    {(ethPrice * ethAmount).toFixed(2)}
                  </>
                ) : (
                  <>$ ~</>
                )}
              </div>
            </div>
          </div>
        </div>

        <button
          className="main_btn w-full mt-6 mb-2"
          onClick={() => handleBuySnow()}
          disabled={
            !saleData?.enabled ||
            saleData?.sale_finalized ||
            100000 <= Number(saleData?.SNOWOwned) + Number(amount)
          }
        >
          {!saleData?.enabled
            ? "Presale is not started yet"
            : saleData?.sale_finalized
            ? "Presale has ended"
            : 100000 <= Number(saleData?.SNOWOwned) + Number(amount)
            ? "Exceed Maximum Amount"
            : "BUY SNOW"}
        </button>
      </div>
      {pendingTx && <LogoLoading />}
    </>
  );
}
