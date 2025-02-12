import React, { useState, useEffect } from "react";
import Countdown from "react-countdown";

export function CountDownComponentClaim({ time }) {
  const [timeKey, setTimeKey] = useState(time);

  useEffect(() => {
    setTimeKey(time);
  }, [time]);

  const renderer = ({ completed, formatted }) => {
    const { days, hours, minutes, seconds } = formatted;

    if (completed) {
      return <>now</>;
    } else {
      return (
        <p>
          {days}:{hours}:{minutes}:{seconds}
        </p>
      );
    }
  };

  return <Countdown date={time} renderer={renderer} autoStart key={timeKey} />;
}
