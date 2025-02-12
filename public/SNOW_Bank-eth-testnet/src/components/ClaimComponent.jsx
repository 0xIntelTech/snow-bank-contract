import React, { useEffect, useState } from "react";
import { notify } from "utils/toastHelper";
import { didUserReject, toReadableAmount } from "utils/customHelpers";
import { getPresaleContract } from "utils/contractHelpers";
import { useAccount } from "wagmi";
import { useEthersSigner } from "hooks/useEthers";
import { CountDownComponentClaim } from "./CountDownClaim";
import SNOW from "./UI/SNOW";
import LogoLoading from "./LogoLoading";

export default function ClaimComponent({ saleData }) {
  const { address } = useAccount();
  const signer = useEthersSigner();
  const presaleContract = getPresaleContract(signer);
  const [pendingTx, setPendingTx] = useState(false);

  const handleClaim = async () => {
    if (!Boolean(saleData.sale_finalized)) {
      notify("error", "Presale is not ended yet");
      return;
    }

    try {
      setPendingTx(true);
      const tx = await presaleContract.withdrawSNOW({
        from: address,
      });
      await tx.wait();
      notify("success", "You claimed tokens successfully");
      window.localStorage.setItem("lastClaimedTime", Date.now());
      setPendingTx(false);
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

  return (
    <>
      <div className="claim_card relative snow_effect py-4 px-4">
        <div className="py-8">
          <div className="flex justify-between mb-3 px-1">
            <div> Your Claimed SNOW:</div>
            <div className="flex gap-1">
              {saleData?.user_withdraw_amount || "0.00"} &nbsp;
              <SNOW />
            </div>
          </div>
          <div className="flex justify-between mb-3 px-1">
            <div>Vested SNOW:</div>
            <div className="flex gap-1">
              {saleData?.SNOWOwned - saleData?.user_withdraw_amount || "0.00"}
              &nbsp; <SNOW />
            </div>
          </div>
          <div className="flex justify-between mb-3 px-1">
            <div>Claimable Amount:</div>
            <div className="flex gap-1">
              {saleData?.seed_investors && saleData?.seed_investors[0] ? (
                <>
                  {" "}
                  {saleData?.SNOWOwned - saleData?.user_withdraw_amount >= 0
                    ? saleData?.SNOWOwned * 0.2
                    : 0.0 || "0.00"}
                </>
              ) : (
                <>
                  {" "}
                  {saleData?.SNOWOwned - saleData?.user_withdraw_amount >= 0
                    ? saleData?.SNOWOwned * 0.1
                    : 0.0 || "0.00"}
                </>
              )}
              &nbsp; <SNOW />
            </div>
          </div>
          <div className="flex justify-between mb-3 px-1">
            <div> Next Claim in:</div>
            <div>
              {Boolean(saleData?.sale_finalized) ? (
                <>
                  {Boolean(saleData?.sale_finalized) &&
                  saleData?.user_withdraw_timestamp === 0 ? (
                    <>
                      <CountDownComponentClaim
                        time={(Number(saleData.finishedTimestamp) + 3600 * 24) * 1000}
                        key={saleData.finishedTimestamp}
                      />
                    </>
                  ) : (
                    <>
                      <CountDownComponentClaim
                        time={
                          (Number(saleData.user_withdraw_timestamp) + 3600 * 24) *
                          1000
                        }
                        key={saleData.user_withdraw_timestamp}
                      />
                    </>
                  )}
                </>
              ) : (
                "0000-00-00 00:00:00"
              )}
            </div>
          </div>
        </div>

        <button
          className="main_btn w-full"
          onClick={() => handleClaim()}
          disabled={!Boolean(saleData?.sale_finalized) ? "disabled" : ""}
        >
          {!Boolean(saleData?.sale_finalized)
            ? "Preslae is not ended yet"
            : Number(saleData?.getAmountToWithdraw)
            ? "You don't have any tokens to claim"
            : "ClAIM SNOW"}
        </button>
      </div>
      {pendingTx && <LogoLoading />}
    </>
  );
}
