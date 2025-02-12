import React from "react";

export default function NFTCardLoading({ active }) {
  return (
    <>
      <div className="w-full max-w-[400px] max-h-[400px] p-6 rounded-lg snow_effect">
        <div className="mx-auto h-[177px] w-[177px] bg-white/5 rounded-md animate-pulse"></div>
        <div className="flex justify-between px-2 animate-pulse">
          <p>NFT ID: </p>
          <p>~</p>
        </div>
        <div className="flex justify-between px-2 animate-pulse">
          <p>Price: </p>
          <p>~ ETH</p>
        </div>
        {active && (
          <button className="main_btn mx-auto mt-4 py-[9px!important] animate-pulse">
            Buy Now
          </button>
        )}
      </div>
    </>
  );
}
