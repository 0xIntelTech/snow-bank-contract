import React from "react";
import { HelpIcon, Skeleton } from "uikit";
import { Tooltip } from "react-tooltip";

const Multiplier = ({ multiplier, pid }) => {
  const displayMultiplier = multiplier ? (
    multiplier.toLowerCase()
  ) : (
    <Skeleton width={30} />
  );
  return (
    <div className="flex gap-3">
      <HelpIcon
        data-tooltip-id={"multiplier" + pid}
        data-tooltip-content="The Multiplier represents the 
        proportion of SNOW rewards each farm receives"
      />
      <Tooltip id={"multiplier" + pid} />
      <div className="box-text text-purple-400">{displayMultiplier}</div>
    </div>
  );
};

export default Multiplier;
