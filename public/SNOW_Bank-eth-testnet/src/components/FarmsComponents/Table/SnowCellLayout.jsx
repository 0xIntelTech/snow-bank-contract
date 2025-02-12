import React from "react";

const SnowCellLayout = ({ label = "", children }) => {
  return (
    <div className="py-2 border-white/10 border-b-[0.1px] flex justify-between">
      <div className="lg:text-[12px] text-gray-300">
        {label && label}
      </div>
      {children}
    </div>
  );
};

export default SnowCellLayout;
