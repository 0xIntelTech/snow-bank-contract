import React, { useState, useEffect } from "react";
import TokenDisplay from "./TokenDisplay";
import { getZapAddress } from "utils/addressHelpers";
import farms from "config/farms";
import { useZapForFarm } from "hooks/useZap";
import Modal from "react-modal";
import tokens from "config/tokens";
import { ethers } from "ethers";
import { useEthersSigner } from "hooks/useEthers";
import { useAccount } from "wagmi";
import { getSNOWContract } from "utils/contractHelpers";
import { useHarvest } from "hooks/useHarvest";
import { notify } from "utils/toastHelper";
import { harvestMany } from "utils/callHelpers";
import { useMasterchef } from "hooks/useContract";
import { useAppDispatch } from "state";
import { fetchFarmUserDataAsync } from "state/farms";
import { getFarmFromPid } from "utils/farmHelpers";
import { didUserReject } from "utils/customHelpers";
import { sleep } from "utils/customHelpers";
import { getCounts } from "utils/limitHelper";
import Loading from "components/Loading";
import LogoLoading from "components/LogoLoading";

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
    background: "black",
  },
};

export default function CompoundModal({
  open,
  closeModal,
  earnings,
  pid,
  isAll,
}) {
  const [targetToken, setTargetToken] = useState(
    !isAll ? getFarmFromPid(pid[0]) : getFarmFromPid(0)
  );
  const [pendingZapTx, setZapPendingTx] = useState(false);
  const [allowance, setAllowance] = useState(0);
  const [isApproving, setIsApproving] = useState(false);
  const [isCheckingAllowance, setIsCheckingAllowance] = useState(false);

  const { address } = useAccount();
  const zapAddress = getZapAddress();
  const signer = useEthersSigner();
  const snowXContract = getSNOWContract(signer);
  const { onReward } = useHarvest(pid[0]);
  const { onZapForFarm } = useZapForFarm();
  const masterChefContract = useMasterchef();

  const [currentCounts, setCurrentCounts] = useState(3);

  const dispatch = useAppDispatch();

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

  const getAllowance = async () => {
    setIsCheckingAllowance(true);
    const allowance = await snowXContract.allowance(address, zapAddress, {
      from: address,
    });
    setAllowance(allowance.toString());
    setIsCheckingAllowance(false);
  };

  async function handleApprove() {
    try {
      setIsApproving(true);
      const allowance = await snowXContract.allowance(address, zapAddress, {
        from: address,
      });
      if (
        Number(ethers.utils.formatUnits(allowance, "ether")) <
        Number(earnings.toString())
      ) {
        const tx = await snowXContract.approve(
          zapAddress,
          ethers.constants.MaxUint256,
          {
            from: address,
          }
        );
        await tx.wait();
      }
      setIsApproving(false);
      getAllowance();
    } catch (e) {
      console.log(e);
      if (didUserReject(e)) {
        notify("error", "User rejected transaction");
      } else {
        notify("error", e.reason);
      }
      setIsApproving(false);
    }
  }

  async function handleDeposit() {
    setZapPendingTx(true);
    try {
      if (isAll) {
        console.log("harvest all...", pid);
        // const res = await harvestMany(masterChefContract, pid, false, address);
        const res = await onReward(false);
        if (res === false) {
          setZapPendingTx(false);
          return;
        }
      } else {
        console.log("harvest single...", pid);
        const res = await onReward(false);
        if (res === false) {
          setZapPendingTx(false);
          return;
        }
      }
      await sleep(2000);
      await onZapForFarm(
        tokens.snow.address,
        false,
        ethers.utils.parseEther(earnings.toString() || "1"),
        targetToken.lpAddresses,
        targetToken.pid
      );
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

  useEffect(() => {
    getAllowance();
  }, []);

  return (
    <><Modal
      isOpen={open}
      onRequestClose={closeModal}
      style={customStyles}
      ariaHideApp={false}
    >
      <div className="min-w-[350px] max-w-[500px] w-full p-6 rounded-lg">
        <div className="flex justify-around items-center">
          <TokenDisplay token={tokens.snow} modal={true} />
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
                className="focus-visible:outline-none w-full cursor-pointer bg-primary rounded-full p-3"
                onChange={(e) => handleChangeToken(e.target.value)}
              >
                {farms.map((item, key) => {
                  if (item.lpSymbol === "WETH-SNOW")
                    return (
                      <option
                        key={key}
                        className="bg-secondary-700 px-3"
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
            className="border border-gray-600 w-full rounded-lg hover:scale-105 transition ease-in-out p-[8px]"
            onClick={closeModal}
          >
            Cancel
          </button>
          {isCheckingAllowance ? (
            <button className="border flex justify-center disabled:opacity-50 disabled:hover:scale-100 border-secondary-700 w-full rounded-lg hover:scale-105 transition ease-in-out p-[8px] bg-secondary-700">
              <Loading /> Loading...
            </button>
          ) : Number(ethers.utils.formatUnits(allowance, "ether")) === 0 ? (
            <button
              onClick={handleApprove}
              disabled={isApproving}
              className="border disabled:opacity-50 disabled:hover:scale-100 border-secondary-700 w-full rounded-lg hover:scale-105 transition ease-in-out p-[8px] bg-secondary-700"
            >
              Approve
            </button>
          ) : (
            <button
              onClick={handleDeposit}
              className="border disabled:opacity-50 disabled:hover:scale-100 border-secondary-700 w-full rounded-lg hover:scale-105 transition ease-in-out p-[8px] bg-secondary-700"
              disabled={
                Number(earnings) === 0 || pendingZapTx || currentCounts === 0
              }
            >
              Compound
            </button>
          )}
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
      {isApproving &&
        <LogoLoading title="Approving..." />}
      {pendingZapTx && <LogoLoading title="Compounding..." />}
    </>

  );
}
