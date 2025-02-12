import React from "react";

export default function Tab({ setActive, active }) {
  return (
    <div className="flex rounded-md gap-3">
      <div
        className={`w-full py-3 text-center cursor-pointer rounded-md transition ease-in-out bg-secondary hover:bg-white hover:text-black ${
          active === 0 ? "bg-[white!important] text-black" : ""
        }`}
        onClick={() => setActive(0)}
      >
        Sale
      </div>
      <div
        className={`w-full py-3 text-center cursor-pointer rounded-md transition ease-in-out bg-secondary  hover:bg-white hover:text-black ${
          active === 1 ? " bg-[white!important] text-black" : ""
        }`}
        onClick={() => setActive(1)}
      >
        Claim
      </div>
    </div>
  );
}
