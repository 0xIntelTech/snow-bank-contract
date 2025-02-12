/* eslint-disable react/no-unused-prop-types */

import React from "react";
import styled from "styled-components";
import { Skeleton } from "uikit";
import { HelpIcon, Text } from "uikit";
import { Tooltip } from "react-tooltip";

const Amount = styled.span`
  color: #59b32a;
  display: flex;
  align-items: center;
  font-size: 12px;
`;

const Earned = ({ earnings, userDataReady, pid }) => {
  if (userDataReady) {
    return (
      <div className="flex gap-3">
        <HelpIcon
          className="cursor-help"
          data-tooltip-id={"Earned" + pid}
          data-tooltip-content="The SNOWs you made & can harvest in this Pool."
        />
        <Tooltip id={"Earned" + pid} />
        <Amount earned={earnings}>{earnings.toLocaleString()}</Amount>
      </div>
    );
  }
  return (
    <Amount earned={0}>
      <Skeleton width={60} />
    </Amount>
  );
};

export default Earned;
