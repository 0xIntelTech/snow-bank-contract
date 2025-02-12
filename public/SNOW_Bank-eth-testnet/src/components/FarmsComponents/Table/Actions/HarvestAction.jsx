import React, { useState, useEffect } from "react";
import { Skeleton } from "uikit";
import BigNumber from "bignumber.js";
import Balance from "components/Balance";
import { BIG_ZERO } from "utils/bigNumber";
import { getBalanceAmount } from "utils/formatBalance";
import { useAppDispatch } from "state";
import { fetchFarmUserDataAsync } from "state/farms";
import { usePriceSNOWUsdc } from "state/hooks";
import { useHarvest } from "hooks/useHarvest";
import { useTranslation } from "context/Localization";
import { Earned } from "./styles";
import { Tooltip } from "react-tooltip";
import Loading from "components/Loading";
import { notify } from "utils/toastHelper";
import { useAccount } from "wagmi";
import CompoundModal from "components/CompoundModal";
import { didUserReject } from "utils/customHelpers";
import { useMasterchef } from "hooks/useContract";
import LogoLoading from "components/LogoLoading";

const HarvestAction = ({ pid, userData, userDataReady, isNFTPool }) => {
  const [pendingCompoundTx, setCompoundPendingTx] = useState(false);
  const [pendingTx, setPendingTx] = useState(false);
  const [earnings, setEarnings] = useState(BIG_ZERO);
  const [earningsUsdt, setEarningsUsdt] = useState(0);
  const [openCompound, setOpenCompound] = useState(false);
  const [displayBalance, setDisplayBalance] = useState(
    userDataReady ? earnings.toLocaleString() : <Skeleton width={60} />
  );
  const { onReward } = useHarvest(pid);
  const { t } = useTranslation();
  const dispatch = useAppDispatch();
  const { address } = useAccount();
  const snowPrice = usePriceSNOWUsdc()[0];
  const masterChefContract = useMasterchef();

  useEffect(() => {
    const earningsBigNumber = new BigNumber(userData.earnings);
    // If user didn't connect wallet default balance will be 0
    if (!earningsBigNumber.isZero()) {
      setEarnings(getBalanceAmount(earningsBigNumber));
      setEarningsUsdt(earnings.multipliedBy(snowPrice).toNumber());
      setDisplayBalance(earnings.toFixed(3, BigNumber.ROUND_DOWN));
    }
  }, [userData.earnings, userDataReady]);

  async function handleHavest() {
    try {
      setPendingTx(true);
      const res = await onReward(false);
      console.log("harvest", res);
      if (res === false) {
        setPendingTx(false);
        return;
      }
      dispatch(fetchFarmUserDataAsync({ address, pids: [pid] }));
      setPendingTx(false);
    } catch (e) {
      if (didUserReject(e)) {
        notify("error", "User rejected transaction");
      } else {
        notify("error", e.reason);
      }
      setPendingTx(false);
    }
  }

  // async function handleCompound() {
  //   try {
  //     setCompoundPendingTx(true)
  //     await harvestMany(masterChefContract, [pid], true, address)
  //     notify('success', 'You have successfully claimed SNOW tokens')
  //     dispatch(fetchFarmUserDataAsync({ address, pids: [pid] }))
  //     setCompoundPendingTx(false)
  //   } catch (e) {
  //     if (didUserReject(e)) {
  //       notify('error', 'User rejected transaction')
  //     }
  //     setCompoundPendingTx(false)
  //   }
  // }

  function openCompoundModal() {
    console.log(pid);
    setOpenCompound(true);
  }

  function closeCompoundModal() {
    setOpenCompound(false);
  }

  return (
    <div className="flex my-2 gap-2 p-3 rounded-lg">
      <button
        disabled={earnings.eq(0) || pendingTx || !userDataReady}
        onClick={handleHavest}
        className="box-btn-harvest text-purple-400"
        data-tooltip-id="harvest-tooltip"
        data-tooltip-content={"Havest SNOW you earned."}
      >
        {pendingCompoundTx || pendingTx ? <Loading /> : t(`Harvest`)}
      </button>

      {!isNFTPool && (
        <button
          className="box-btn-harvest text-purple-400"
          data-tooltip-id="compound-tooltip"
          onClick={openCompoundModal}
          data-tooltip-content={
            "Havest SNOW you earned & restake the SNOW profit to this pool"
          }
          // disabled={earnings.eq(0) || pendingCompoundTx || !userDataReady}
        >
          {t(`Compound`)}
        </button>
      )}

      <Tooltip id="compound-tooltip" />
      <Tooltip id="harvest-tooltip" />

      {openCompound && (
        <CompoundModal
          open={openCompound}
          closeModal={closeCompoundModal}
          earnings={earnings}
          pid={[pid]}
          isAll={false}
        />
      )}

      {/* {pendingTx && <LogoLoading title="Harvesting..." />}
      {pendingCompoundTx && <Loading title="Compounding..." />} */}
    </div>
  );
};

export default HarvestAction;
