/* eslint-disable react/destructuring-assignment */

import React, { useEffect, useState } from "react";
import { useMatchBreakpoints } from "uikit";
import { useTranslation } from "context/Localization";
import useDelayedUnmount from "hooks/useDelayedUnmount";
import { useFarmUser } from "state/hooks";

import Apr from "./SnowApr";
import Farm from "./SnowFarm";
import Earned from "./SnowEarned";
import Details from "./Details";
import Multiplier from "./SnowMultiplier";
import Liquidity from "./SnowLiquidity";
import ActionPanel from "./Actions/ActionPanel";
import CellLayout from "./SnowCellLayout";
import { DesktopColumnSchema, MobileColumnSchema } from "constants";

const cells = {
  apr: Apr,
  farm: Farm,
  earned: Earned,
  details: Details,
  multiplier: Multiplier,
  liquidity: Liquidity,
};

export default function SnowBox(props) {
  const { details, userDataReady } = props;
  const hasStakedAmount = !!useFarmUser(details.pid).stakedBalance.toNumber();
  const [actionPanelExpanded, setActionPanelExpanded] =
    useState(hasStakedAmount);
  const shouldRenderChild = useDelayedUnmount(actionPanelExpanded, 300);
  const { t } = useTranslation();

  const toggleActionPanel = () => {
    setActionPanelExpanded(!actionPanelExpanded);
  };

  useEffect(() => {
    setActionPanelExpanded(hasStakedAmount);
  }, [hasStakedAmount]);

  const { isXl, isXs } = useMatchBreakpoints();

  const isMobile = !isXl;
  const tableSchema = isMobile ? MobileColumnSchema : DesktopColumnSchema;
  const columnNames = tableSchema.map((column) => column.name);

  return (
    <div className="flex justify-center w-full mt-2">
      <div className="sm:p-4 p-3 sm:max-w-[400px] snows max-w-full w-full">
        <div className="" onClick={toggleActionPanel}>
          {Object.keys(props).map((key) => {
            const columnIndex = columnNames.indexOf(key);
            if (columnIndex === -1) {
              return null;
            }

            switch (key) {
              case "details":
                return <div key={key}></div>;
              case "apr":
                return (
                  <div key={key}>
                    <CellLayout label={t("APR")}>
                      <Apr
                        {...props.apr}
                        hideButton={isMobile}
                        index={props.index}
                        pid={props?.details?.pid}
                      />
                    </CellLayout>
                  </div>
                );
              default:
                return (
                  <div key={key}>
                    <CellLayout label={t(tableSchema[columnIndex].label)}>
                      {React.createElement(cells[key], {
                        ...props[key],
                        userDataReady,
                        ...{ pid: props?.details?.pid },
                      })}
                    </CellLayout>
                  </div>
                );
            }
          })}
          <ActionPanel {...props} hasDiscount={props.farm.hasDiscount} />
        </div>
      </div>
    </div>
  );
}
