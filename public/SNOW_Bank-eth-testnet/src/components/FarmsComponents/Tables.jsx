import React, { useRef } from "react";
import { useTable } from "uikit";
import SnowBox from "./Table/SnowBox";

export default function FarmTables(props) {
  const { data, columns, userDataReady } = props;
  const { rows } = useTable(columns, data, {
    sortable: true,
    sortColumn: "farm",
  });

  return (
    <>
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
        {rows.map((row, key) => {
          return (
            <SnowBox
              {...row.original}
              userDataReady={userDataReady}
              index={key}
              key={key}
            />
          );
        })}
      </div>
    </>
  );
}
