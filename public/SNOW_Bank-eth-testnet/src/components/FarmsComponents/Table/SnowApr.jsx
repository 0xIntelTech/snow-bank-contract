/* eslint-disable react/no-unused-prop-types */

import React from "react";
import styled from "styled-components";
import ApyButton from "./ApyButton";
import { BASE_ADD_LIQUIDITY_URL } from "config";
import getLiquidityUrlPathParts from "utils/getLiquidityUrlPathParts";
import { HelpIcon, Text } from "uikit";
import { Tooltip } from "react-tooltip";

const Container = styled.div`
  display: flex;
  align-items: center;

  button {
    width: 20px;
    svg {
      path {
        fill: #0d0d0d;
      }
    }
  }
`;

const Apr = ({
  value,
  lpLabel,
  tokenAddress,
  quoteTokenAddress,
  snowPrice,
  originalValue,
  hideButton = false,
  pid
}) => {
  // const liquidityUrlPathParts = getLiquidityUrlPathParts({
  //   quoteTokenAddress,
  //   tokenAddress,
  // });
  // const addLiquidityUrl = `${BASE_ADD_LIQUIDITY_URL}/${liquidityUrlPathParts}`;
  // const addLiquidityUrl = `${BASE_ADD_LIQUIDITY_URL}`;

  return originalValue !== 0 ? (
    <div className="flex gap-3">
      <HelpIcon
        className="cursor-help"
        data-tooltip-id={"APR" + pid}
        data-tooltip-content="Annual Percentage Rate for SNOW farming"
      />
      <Tooltip id={"APR" + pid} />
      <div className="box-text">{value || "0.00"} %</div>
      {/* {!hideButton && (
          <ApyButton
            lpLabel={lpLabel}
            snowPrice={snowPrice}
            apr={originalValue}
            addLiquidityUrl={addLiquidityUrl}
          />
        )} */}
    </div>
  ) : (
    <div className="flex gap-3">
      <HelpIcon
        className="cursor-help"
        data-tooltip-id={"APR" + pid}
        data-tooltip-content="Annual Percentage Rate for SNOW farming"
      />
      <Tooltip id={"APR" + pid} />
      <div className="box-text">{originalValue || "0.00"} %</div>
    </div>
  );
};

export default Apr;
