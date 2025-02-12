import React from "react";
import styled from "styled-components";
import { useTranslation } from "context/Localization";
import { HelpIcon, Text } from "uikit";
import { Tooltip } from "react-tooltip";

const Liquidity = ({ liquidity, pid }) => {

  const displayLiquidity =
    liquidity && liquidity.gt(0)
      ? `$${Number(liquidity).toLocaleString(undefined, {
          maximumFractionDigits: 3,
        })}`
      : `$${Number(0).toLocaleString(undefined, {
          maximumFractionDigits: 3,
        })}`;

  return (
    <div className="flex gap-3">
      <HelpIcon
        className="cursor-help z-50 relative"
        data-tooltip-id={"liquidity" + pid}
        data-tooltip-content="Total value of the funds in this farm’s liquidity pool"
      />
      <Tooltip id={"liquidity" + pid} />
      <p className="box-text">{displayLiquidity}</p>
    </div>
  );
};

export default Liquidity;
