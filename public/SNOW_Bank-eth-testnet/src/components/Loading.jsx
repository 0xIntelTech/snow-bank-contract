import React from "react";
import { AiOutlineLoading3Quarters } from "react-icons/ai";

export default function Loading({ title = "", size = "sm" }) {
  return (
    <div className="flex justify-center items-center">
      <AiOutlineLoading3Quarters className={`text-${size} text-white animate-spin my-auto mx-1`}/>
      {title}
    </div>
  );
}
