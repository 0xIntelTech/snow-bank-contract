import React from "react";

export default function LogoLoading({ title = "Loading..." }) {
  return (
    <div className="fixed z-[99999] top-0 left-0 w-screen h-screen flex justify-center items-center bg-black/70">
      <div className="snow_effect rounded-lg p-12">
        <img
          src="/assets/baseLoading.webp"
          alt="Loading..."
          className="w-[200px] h-[200px] bounce_animation relative z-[9999] mx-auto"
        />
        <p className="text-center">{title}</p>
      </div>
    </div>
  );
}
