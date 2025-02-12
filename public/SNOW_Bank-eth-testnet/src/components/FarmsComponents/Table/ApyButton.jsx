import React from "react";
import { IconButton, useModal, CalculateIcon } from "uikit";
import ApyCalculatorModal from "./ApyCalculatorModal";
import { useTranslation } from "context/Localization";

const ApyButton = ({ lpLabel, snowPrice, apr, addLiquidityUrl }) => {
  const { t } = useTranslation();
  const [onPresentApyModal] = useModal(
    <ApyCalculatorModal
      linkLabel={t("Get %symbol%", { symbol: lpLabel })}
      tokenPrice={snowPrice.toNumber()}
      apr={apr}
      linkHref={addLiquidityUrl}
      isFarm
    />
  );

  const handleClickButton = (event) => {
    event.stopPropagation();
    onPresentApyModal();
  };

  return (
    <IconButton onClick={handleClickButton} variant="text" scale="sm" ml="4px">
      <CalculateIcon width="18px" style={{ color: "white" }} />
    </IconButton>
  );
};

export default ApyButton;
