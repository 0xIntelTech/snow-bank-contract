import React, { useEffect, useCallback, useMemo, useState } from "react";
import { Modal } from "uikit";
import BigNumber from "bignumber.js";
import ModalActions from "./ModalActions";
import ModalInput from "./ModalInput";
import { useTranslation } from "context/Localization";
import { getFullDisplayBalance } from "utils/formatBalance";
import LogoLoading from "components/LogoLoading";

const DepositModal = ({
  max,
  isNFTPool,
  isNFTALL,
  setIsNFTALL,
  onConfirm,
  onDismiss,
  tokenName = "",
  addLiquidityUrl,
  decimals = 18,
  depositFee,
}) => {
  const [val, setVal] = useState("");
  const [valNumber, setValueNumber] = useState(new BigNumber(0));

  const [lockPeriod, setLockPeriod] = useState(0);
  const [pendingTx, setPendingTx] = useState(false);
  const { t } = useTranslation();
  const fullBalance = useMemo(() => {
    return isNFTPool ? max : getFullDisplayBalance(max);
  }, [max]);

  const fullBalanceNumber = new BigNumber(fullBalance);

  const handleChange = useCallback(
    (e) => {
      if (e.currentTarget.validity.valid) {
        setVal(e.currentTarget.value.replace(/,/g, "."));
        setValueNumber(new BigNumber(e.currentTarget.value.replace(/,/g, ".")))
      }
    },
    [setVal]
  );

  const handleSelectMax = () => {
    if (isNFTPool) {
      setIsNFTALL(true)
      setVal(fullBalance);
      setValueNumber(fullBalance)
    } else {
      setVal(fullBalance);
      setValueNumber(new BigNumber(fullBalance))
    }
  };

  useEffect(() => {
    setIsNFTALL(false)
  }, [])
  return (
    <>
      <Modal title={t("Stake tokens")} onDismiss={onDismiss} className="snow_effect">
        <ModalInput
          value={val}
          onSelectMax={handleSelectMax}
          onChange={handleChange}
          max={fullBalance}
          isNFTPool={isNFTPool}
          symbol={tokenName}
          addLiquidityUrl={addLiquidityUrl}
          inputTitle={t("Stake")}
          decimals={decimals}
        />
        <ModalActions>
          <button
            variant="secondary"
            onClick={onDismiss}
            width="100%"
            disabled={pendingTx}
            className="box-btn-stake w-full hover:bg-red-400"
          >
            {t("Cancel")}
          </button>
          <button
            className="box-btn-stake w-full"
            width="100%"
            disabled={
              pendingTx ||
              !valNumber.isFinite() ||
              (!isNFTPool && valNumber.eq(0)) ||
              (!isNFTPool && valNumber.gt(fullBalanceNumber))
            }
            onClick={async () => {
              setPendingTx(true);
              await onConfirm(val, lockPeriod);
              setIsNFTALL(false);
              setPendingTx(false);
              onDismiss();
            }}
          >
            {t("Confirm")}
          </button>
        </ModalActions>
      </Modal>
      {
        pendingTx && <LogoLoading title="Pending Confirmation..." />
      }</>
  );
};

export default DepositModal;
