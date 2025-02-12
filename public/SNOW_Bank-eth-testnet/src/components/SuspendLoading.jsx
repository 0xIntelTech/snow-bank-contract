import React from "react";

export default function SuspendLoading() {
  return (
    <div className="fixed z-[99999] top-0 left-0 w-screen h-screen flex justify-center items-center bg-black/70">
      <img
        src="/assets/baseLoading.webp"
        alt="Loading..."
        className="w-[200px] h-[200px] animate-pulse  relative z-[9999] mx-auto"
      />
    </div>
  );
}
