import React, { useState, useEffect } from "react";
import TokenDisplay from "components/TokenDisplay";
import farms from "config/farms";
import Modal from "react-modal";
import { ArrowForwardIcon } from "uikit";
import { useTranslation } from "context/Localization";
import { useAccount } from "wagmi";
import { notify } from "utils/toastHelper";
import { useCompound } from "hooks/useCompound";
import { useAppDispatch } from "state";
import { fetchFarmUserDataAsync } from "state/farms";
import { getFarmFromPid } from "utils/farmHelpers";
import { didUserReject } from "utils/customHelpers";
import tokens from "config/tokens";
import { getCounts } from "utils/limitHelper";
import LogoLoading from "./LogoLoading";
import Loading from "components/Loading";

const customStyles = {
  content: {
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)",
    background: "#1F212A",
    color: "white",
    border: "none",
  },
};

export default function CompoundModal({
  open,
  closeModal,
  earnings,
  pid,
  isAll,
}) {
  const { t } = useTranslation();
  const [targetToken, setTargetToken] = useState(
    !isAll ? getFarmFromPid(pid[0]) : getFarmFromPid(0)
  );
  const [pendingZapTx, setZapPendingTx] = useState(false);
  const [currentCounts, setCurrentCounts] = useState(3);
  const { address } = useAccount();
  const { onCompound } = useCompound(pid[0]);

  const getCurrentCounts = async (address) => {
    const currentDate = new Date().toLocaleDateString();
    const res = await getCounts(address);
    if (res.lastCalled !== currentDate) {
      setCurrentCounts(3);
    } else {
      setCurrentCounts(3 - res.counts);
    }
  };

  useEffect(() => {
    if (address) {
      getCurrentCounts(address);
    }
  }, [address]);

  const dispatch = useAppDispatch();

  async function handleDeposit() {
    setZapPendingTx(true);
    try {
      await onCompound(pid);
      dispatch(fetchFarmUserDataAsync({ account: address, pids: pid }));
      closeModal();
      setZapPendingTx(false);
    } catch (e) {
      if (didUserReject(e)) {
        notify("error", "User rejected transaction");
      } else {
        notify("error", e.reason);
      }
      setZapPendingTx(false);
    }
  }

  const handleChangeToken = (e, type) => {
    setTargetToken(farms[Number(e)]);
  };

  return (
    <>
      <Modal
        isOpen={open}
        onRequestClose={closeModal}
        style={customStyles}
        ariaHideApp={false}
      >
        <div className="min-w-[350px] max-w-[500px] w-full p-6 rounded-lg snow_effect">
          <div className="flex justify-around items-center">
            <img
              src={tokens.snow.logo}
              alt="token"
              className="rounded-full w-[60px] h-[60px] lg:w-[65px] lg:h-[65px] mb-3"
            />
            <ArrowForwardIcon />
            <TokenDisplay token={targetToken} modal={true} />
          </div>
          {isAll ? (
            <>
              <p className="text-center text-gray-400 text-sm py-2">
                Select target pool.
              </p>
              <div className="bg-secondary-700 rounded-full p-2 flex mb-2">
                <select
                  name="tokenA"
                  className="bg-transparent focus-visible:outline-none w-full cursor-pointer"
                  onChange={(e) => handleChangeToken(e.target.value)}
                >
                  {farms.map((item, key) => {
                    if (item.lpSymbol === "WPLS-SNOW")
                      return (
                        <option
                          key={key}
                          className="bg-secondary-700"
                          value={key}
                        >
                          {item?.lpSymbol}
                        </option>
                      );
                  })}
                </select>
              </div>
            </>
          ) : (
            <></>
          )}

          <p className="text-center text-lg pt-4">
            Compound{" "}
            <span className="font-semibold text-green-500 mx-1">
              {tokens.snow.symbol}
            </span>
            into{" "}
            <span className="font-semibold text-green-500 mx-1">
              {targetToken?.lpSymbol}
            </span>{" "}
            Pool
          </p>
          <p className="text-center my-2">
            Available: {Number(earnings.toString()).toFixed(3)} SNOW
          </p>
          <div className="flex gap-3 pt-4">
            <button
              className="box-btn-harvest hover:bg-red-400"
              onClick={closeModal}
            >
              Cancel
            </button>

            <button
              onClick={handleDeposit}
              className="box-btn-harvest flex justify-center items-center"
              disabled={
                Number(earnings) === 0 || pendingZapTx || currentCounts === 0
              }
            >
              {pendingZapTx ? <Loading /> : t("Compound")}
            </button>
          </div>

          {currentCounts === 0 ? (
            <p className="mt-2 text-red-600">
              You can not compound or harvest over 3 time(s) a day
            </p>
          ) : (
            <p className="mt-2">{`You are able to compound or harvest ${currentCounts} time(s) today.`}</p>
          )}
        </div>
      </Modal>
      {/* {pendingZapTx && <LogoLoading title="Compounding..." />} */}
    </>
  );
}
