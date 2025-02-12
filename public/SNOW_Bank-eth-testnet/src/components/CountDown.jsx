import React from "react";
import Countdown from "react-countdown";

export function CountDownComponent({ setEnded }) {
  const renderer = ({ completed, formatted }) => {
    const { days, hours, minutes, seconds } = formatted;

    if (completed) {
      setEnded(true);
      return <></>;
    } else {
      return (
        <>
          <div className="mb-8 flex gap-2 lg:gap-8 mt-3">
            <span className="shadow p-6 text-3xl  lg:text-4xl font-bold text-white snow_effect backdrop-blur-sm shadow-black rounded-2xl w-[55px] h-[55px] lg:w-[75px] lg:h-[75px] flex justify-center items-center">
              {days}
            </span>
            <span className="flex items-center font-extrabold text-5xl text-white">
              :
            </span>
            <span className="shadow p-6 text-3xl  lg:text-4xl font-bold text-white snow_effect backdrop-blur-sm shadow-black rounded-2xl w-[55px] h-[55px] lg:w-[75px] lg:h-[75px] flex justify-center items-center">
              {hours}
            </span>
            <span className="flex items-center font-extrabold text-5xl text-white">
              :
            </span>
            <span className="shadow p-6 text-3xl  lg:text-4xl font-bold text-white snow_effect backdrop-blur-sm shadow-black rounded-2xl w-[55px] h-[55px] lg:w-[75px] lg:h-[75px] flex justify-center items-center">
              {minutes}
            </span>
            <span className="flex items-center font-extrabold text-5xl text-white">
              :
            </span>
            <span className="shadow p-6 text-3xl  lg:text-4xl font-bold text-white snow_effect backdrop-blur-sm shadow-black rounded-2xl w-[55px] h-[55px] lg:w-[75px] lg:h-[75px] flex justify-center items-center">
              {seconds}
            </span>
          </div>
        </>
      );
    }
  };

  return (
    <div className="flex justify-center">
      <Countdown date={1704579867764} renderer={renderer} autoStart />
    </div>
  );
}
