import React from "react";

export default function TokenDisplay(props) {
  if (props.token?.isTokenOnly) {
    return (
      <img
        src={props.token?.logoA}
        alt="token"
        className="rounded-full w-[60px] h-[60px] lg:w-[65px] lg:h-[65px]"
      />
    );
  } else {
    return (
      <div className="h-[60px] w-[60px] lg:h-[65px] lg:w-[65px] relative mb-3">
        <img
          src={props.token?.logoA}
          alt="token"
          className="rounded-full w-[60px] h-[60px] lg:w-[65px] lg:h-[65px] absolute left-1/2 -translate-x-[80%]"
        />
        <img
          src={props.token?.logoB}
          alt="token"
          className="rounded-full w-[60px] h-[60px] lg:w-[65px] lg:h-[65px] absolute left-1/2 -translate-x-[30%]"
        />
      </div>
    );
  }
}
