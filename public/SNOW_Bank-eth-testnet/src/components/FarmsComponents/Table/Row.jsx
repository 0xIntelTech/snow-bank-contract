/* eslint-disable react/destructuring-assignment */

import React, { useEffect, useState } from "react";
import styled from "styled-components";
import { useMatchBreakpoints } from "uikit";
import { useTranslation } from "context/Localization";
import useDelayedUnmount from "hooks/useDelayedUnmount";
import { useFarmUser } from "state/hooks";

import Apr from "./Apr";
import Farm from "./Farm";
import Earned from "./Earned";
import Details from "./Details";
import Multiplier from "./Multiplier";
import Liquidity from "./Liquidity";
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

const CellInner = styled.div`
  padding: 24px 0px;
  display: flex;
  width: 100%;
  align-items: center;
  padding-right: 8px;

  @media screen and (min-width: 1080px) {
    padding-right: 32px;
  }
`;

const EarnedMobileCell = styled.td`
  padding: 16px 0 24px 16px;
`;

const AprMobileCell = styled.td`
  padding-top: 16px;
  padding-bottom: 24px;
`;

const FarmMobileCell = styled.td`
  padding-top: 24px;
`;

const Row = (props) => {
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

  const handleRenderRow = () => {
    if (!isXs) {
      return (
        <tr className="tr" onClick={toggleActionPanel}>
          {Object.keys(props).map((key) => {
            const columnIndex = columnNames.indexOf(key);
            if (columnIndex === -1) {
              return null;
            }

            switch (key) {
              case "details":
                return (
                  <td key={key}>
                    <CellInner>
                      <CellLayout>
                        <Details actionPanelToggled={actionPanelExpanded} />
                      </CellLayout>
                    </CellInner>
                  </td>
                );
              case "apr":
                return (
                  <td key={key}>
                    <CellInner>
                      <CellLayout label={t("APR")}>
                        <Apr
                          {...props.apr}
                          hideButton={isMobile}
                          index={props.index}
                        />
                      </CellLayout>
                    </CellInner>
                  </td>
                );
              default:
                return (
                  <td key={key}>
                    <CellInner>
                      <CellLayout label={t(tableSchema[columnIndex].label)}>
                        {React.createElement(cells[key], {
                          ...props[key],
                          userDataReady,
                        })}
                      </CellLayout>
                    </CellInner>
                  </td>
                );
            }
          })}
        </tr>
      );
    }
    return (
      <tr className="tr" onClick={toggleActionPanel}>
        <td>
          <div>
            <FarmMobileCell>
              <CellLayout>
                <Farm {...props.farm} />
              </CellLayout>
            </FarmMobileCell>
          </div>
        </td>
        <td>
          <div>
            <AprMobileCell>
              <CellLayout label={t("APR (daily)")}>
                <Apr {...props.apr} hideButton index={props.index} />
              </CellLayout>
            </AprMobileCell>
          </div>
        </td>
        <td>
          <div>
            <EarnedMobileCell>
              <CellLayout label={t("Earned")}>
                <Earned {...props.earned} userDataReady={userDataReady} />
              </CellLayout>
            </EarnedMobileCell>
          </div>
        </td>
        <td>
          <CellInner>
            <CellLayout>
              <Details actionPanelToggled={actionPanelExpanded} />
            </CellLayout>
          </CellInner>
        </td>
      </tr>
    );
  };

  return (
    <>
      {handleRenderRow()}
      {shouldRenderChild && (
        <tr>
          <td colSpan={6}>
            <ActionPanel {...props} hasDiscount={props.farm.hasDiscount} />
          </td>
        </tr>
      )}
    </>
  );
};

export default Row;
