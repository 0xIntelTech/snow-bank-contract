import React from "react";
import styled from "styled-components";
import { HelpIcon, Skeleton } from "uikit";
import { Tooltip } from "react-tooltip";

const Container = styled.div`
  display: flex;
  align-items: center;
`;

const Multiplier = ({ multiplier }) => {
  const displayMultiplier = multiplier ? (
    multiplier.toLowerCase()
  ) : (
    <Skeleton width={30} />
  );
  return (
    <Container>
      <div className="text-symbol w-[36px] lg:text-right lg:mr-4 text-left mr-0">{displayMultiplier}</div>
      <HelpIcon
        data-tooltip-id="liquidity-tooltip"
        data-tooltip-content="The Multiplier represents the 
        proportion of SNOW rewards each farm receives"
      />
      <Tooltip id="liquidity-tooltip" />
    </Container>
  );
};

export default Multiplier;
