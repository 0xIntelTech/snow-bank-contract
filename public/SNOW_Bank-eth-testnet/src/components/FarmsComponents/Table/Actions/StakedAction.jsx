import React, { useEffect, useState, useCallback } from "react";
import {
  useModal,
  IconButton,
  AddIcon,
  MinusIcon,
  Skeleton,
  Text,
} from "uikit";
import { useLocation } from "react-router-dom";
import { BigNumber } from "bignumber.js";
import Balance from "components/Balance";
import { useFarmUser, useLpTokenPrice } from "state/hooks";
import { fetchFarmUserDataAsync } from "state/farms";
import { useTranslation } from "context/Localization";
import { useApprove } from "hooks/useApprove";
import { BASE_ADD_LIQUIDITY_URL } from "config";
import { useAppDispatch } from "state";
import getLiquidityUrlPathParts from "utils/getLiquidityUrlPathParts";
import {
  getBalanceAmount,
  getBalanceNumber,
  getFullDisplayBalance,
} from "utils/formatBalance";
import useStake from "hooks/useStake";
import useUnstake from "hooks/useUnstake";
import DepositModal from "../../DepositModal";
import WithdrawModal from "../../WithdrawModal";
import { ActionContainer, ActionTitles, ActionContent, Earned } from "./styles";
import { useAccount } from "wagmi";
import { Tooltip } from "react-tooltip";
import {
  getErc20Contract,
  getErc721Contract,
  getMasterchefContract,
} from "utils/contractHelpers";
import { useEthersSigner } from "hooks/useEthers";
import { usePriceSNOWUsdc } from "state/hooks";
import { toReadableAmount } from "utils/customHelpers";
import ZapInModal from "components/ZapInModal";

const StakedAction = ({
  isTokenOnly,
  isNFTPool,
  pid,
  lpSymbol,
  lpAddresses,
  quoteToken,
  token,
  userDataReady,
  withDepositLockDiscount,
  depositFee,
  userData,
}) => {
  const [amountPerNFT, setAmountPerNFT] = useState();
  const [isNFTALL, setIsNFTALL] = useState(false);
  const { t } = useTranslation();
  const { address } = useAccount();
  const signer = useEthersSigner();
  const [requestedApproval, setRequestedApproval] = useState(false);
  const {
    allowance,
    tokenBalance: tokenBalanceAsString,
    stakedBalance: stakedBalanceAsString,
  } = useFarmUser(pid);
  const snowPrice = usePriceSNOWUsdc()[0];
  const [open, setOpen] = useState(false);

  const masterChefContract = getMasterchefContract(signer);

  const decimals = isTokenOnly ? token.decimals : 18;
  const tokenBalance = new BigNumber(tokenBalanceAsString).times(
    new BigNumber(10).pow(18 - decimals)
  );
  const stakedBalance = new BigNumber(stakedBalanceAsString).times(
    new BigNumber(10).pow(18 - decimals)
  );
  const { onStake } = useStake(pid, isNFTPool);
  const { onUnstake } = useUnstake(pid, isNFTPool);
  const location = useLocation();
  const lpPrice = useLpTokenPrice(lpSymbol);

  const isApproved = isNFTPool
    ? address && allowance[0]
    : address && allowance && allowance.isGreaterThan(0);

  const lpAddress = isTokenOnly ? token.address : lpAddresses;
  const liquidityUrlPathParts = getLiquidityUrlPathParts({
    quoteTokenAddress: quoteToken.address,
    tokenAddress: token.address,
  });
  const addLiquidityUrl = `${BASE_ADD_LIQUIDITY_URL}/${liquidityUrlPathParts}`;

  const handleStake = async (amount, daysToLock) => {
    try {
      if (!isApproved) await handleApprove();
      console.log("amount...", amount);
      await onStake(amount, isNFTALL);
      dispatch(fetchFarmUserDataAsync({ account: address, pids: [pid] }));
    } catch (e) {
      console.log(e);
    }
  };

  const handleUnstake = async (amount) => {
    try {
      console.log("is unstaking...");
      await onUnstake(amount, isNFTALL);
      dispatch(fetchFarmUserDataAsync({ account: address, pids: [pid] }));
    } catch (e) {
      console.log(e);
    }
  };

  const displayBalance = useCallback(() => {
    if (isNFTPool) {
      return stakedBalance.toString();
    } else {
      const stakedBalanceBigNumber = getBalanceAmount(stakedBalance);
      if (stakedBalanceBigNumber.gt(0) && stakedBalanceBigNumber.lt(0.0001)) {
        return getFullDisplayBalance(stakedBalance, 18, 4).toLocaleString();
      }
      return stakedBalanceBigNumber.toFixed(4, BigNumber.ROUND_DOWN);
    }
  }, [stakedBalance]);

  const _depositFee = depositFee;

  const [onPresentDeposit] = useModal(
    <DepositModal
      pid={pid}
      isNFTPool={isNFTPool}
      isNFTALL={isNFTALL}
      setIsNFTALL={setIsNFTALL}
      account={address}
      max={tokenBalance}
      onConfirm={handleStake}
      tokenName={lpSymbol}
      addLiquidityUrl={BASE_ADD_LIQUIDITY_URL}
      withDepositLockDiscount={withDepositLockDiscount}
      depositFee={_depositFee}
      unlockTime={userData.unlockTime}
    />
  );
  const [onPresentWithdraw] = useModal(
    <WithdrawModal
      isNFTPool={isNFTPool}
      isNFTALL={isNFTALL}
      setIsNFTALL={setIsNFTALL}
      max={stakedBalance}
      onConfirm={handleUnstake}
      tokenName={lpSymbol}
    />
  );
  const lpContract = isNFTPool
    ? getErc721Contract(lpAddress, signer)
    : getErc20Contract(lpAddress, signer);
  const dispatch = useAppDispatch();
  const { onApprove } = useApprove(lpContract, isNFTPool);

  function openModal() {
    console.log(pid);
    setOpen(true);
  }

  function closeModal() {
    setOpen(false);
  }

  const handleApprove = useCallback(async () => {
    try {
      setRequestedApproval(true);
      await onApprove();
      dispatch(fetchFarmUserDataAsync({ account: address, pids: [pid] }));

      setRequestedApproval(false);
    } catch (e) {
      console.log(e);
    }
  }, [onApprove, dispatch, address, pid]);

  const getAmountPerNFT = async () => {
    const _amountPerNFT = await masterChefContract.getAmountPerNFT();
    setAmountPerNFT(toReadableAmount(_amountPerNFT.toString()));
  };

  useEffect(() => {
    if (signer) {
      getAmountPerNFT();
    }
  }, [signer]);

  // if (!address) {
  //   return (
  //     <ActionContainer>
  //       <ActionTitles>
  //         <Text color="white" fontSize="20px">
  //           {t("Start Farming")}
  //         </Text>
  //       </ActionTitles>
  //       <ActionContent>Unlock</ActionContent>
  //     </ActionContainer>
  //   );
  // }

  // if (!userDataReady) {
  //   return (
  //     <div className="flex flex-row md:flex-col justify-between md:justify-center items-center gap-4 p-2 lg:p-4 w-full">
  //       <div className="flex justify-center font-semibold text-xl w-full">
  //         {t("Start Farming")}
  //       </div>
  //       <div className="flex w-full justify-center">
  //         <Skeleton width={180} marginBottom={28} marginTop={14} />
  //       </div>
  //     </div>
  //   );
  // }

  if (stakedBalance.gt(0)) {
    return (
      <>
        <div className="px-3 w-full">
          {open && <ZapInModal open={open} closeModal={closeModal} pid={pid} />}
          {!isNFTPool && (
            <button
              className="box-btn-stake"
              data-tooltip-id="zap-tooltip"
              data-tooltip-content="Stake to this pool from your wallet"
              disabled={!userDataReady}
              onClick={openModal}
            >
              {t("Zap in")}
            </button>
          )}
        </div>

        <div className="flex flex-row items-center justify-between md:justify-end gap-5 p-2 lg:p-4 w-full">
          <div className="flex flex-col gap-1 justify-between md:min-w-[200px]">
            <div className="text-lg font-semibold">
              {lpSymbol}
              &nbsp;
              {t("Staked")}
            </div>
            <Earned>{displayBalance()}</Earned>
            {stakedBalance.gt(0) && lpPrice.gt(0) && (
              <Balance
                fontSize="15px"
                color="white"
                decimals={2}
                value={
                  isNFTPool
                    ? stakedBalance
                        .times(new BigNumber(amountPerNFT))
                        .times(snowPrice)
                    : getBalanceNumber(lpPrice.times(stakedBalance))
                }
                unit=" USD"
                prefix="~"
              />
            )}
          </div>
          <div className="flex flex-row items-center">
            <IconButton
              variant="secondary"
              data-tooltip-id="unstake-tooltip"
              data-tooltip-content="Unstake Pool"
              onClick={() => {
                setIsNFTALL(false);
                onPresentWithdraw();
              }}
              mr="6px"
            >
              <MinusIcon color="primary" width="14px" />
            </IconButton>
            <IconButton
              variant="secondary"
              data-tooltip-id="stake-tooltip"
              data-tooltip-content="Stake pool"
              onClick={() => {
                setIsNFTALL(false);
                onPresentDeposit();
              }}
              disabled={["history", "archived"].some((item) =>
                location.pathname.includes(item)
              )}
            >
              <AddIcon color="primary" width="14px" />
            </IconButton>
            <Tooltip id="unstake-tooltip" />
            <Tooltip id="stake-tooltip" />
          </div>
        </div>
      </>
    );
  }

  return (
    <div className="flex gap-2 px-3">
      <button
        onClick={onPresentDeposit}
        disabled={["history", "archived"].some((item) =>
          location.pathname.includes(item)
        )}
        className="box-btn-stake"
      >
        {t("Stake")}
      </button>

      {!isNFTPool && (
        <button
          className="box-btn-stake"
          data-tooltip-id="zap-tooltip"
          data-tooltip-content="Stake to this pool from your wallet"
          disabled={!userDataReady}
          onClick={openModal}
        >
          {t("Zap in")}
        </button>
      )}

      {open && <ZapInModal open={open} closeModal={closeModal} pid={pid} />}
    </div>
  );
};

export default StakedAction;
