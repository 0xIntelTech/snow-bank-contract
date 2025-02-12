import React from "react";
import { roadmaps } from "config";
import "./../styles/roadmap.css";

export default function Roadmap() {
  return (
    <div className="max-w-[1200px] mx-auto container">
      <div className="mt-16">
        <p className="text-3xl text-center font-bold">Multichain Roadmap</p>
        <p className="text-center max-w-[600px] mx-auto mt-3">
          Snow Bank will be deploying on most of the top blockchains:
          Pulsechain, Avalanche, BASE,BSC, Ethereum Mainnet, Solana.
        </p>
      </div>
      <div className="space-y-8 mt-8 relative before:absolute before:inset-0 before:ml-5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-slate-300 before:to-transparent">
        {roadmaps.map((item, i) => (
          <div
            key={i}
            className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active"
          >
            <div className="flex items-center justify-center w-10 h-10 rounded-full border border-white bg-slate-300 snow_effect text-slate-500 group-[.is-active]:text-emerald-50 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2">
              <svg
                className="fill-current"
                xmlns="http://www.w3.org/2000/svg"
                width="12"
                height="10"
              >
                <path
                  fillRule="nonzero"
                  d="M10.422 1.257 4.655 7.025 2.553 4.923A.916.916 0 0 0 1.257 6.22l2.75 2.75a.916.916 0 0 0 1.296 0l6.415-6.416a.916.916 0 0 0-1.296-1.296Z"
                />
              </svg>
            </div>
            <div className="w-[calc(100%-2rem)] md:w-[calc(50%-0.5rem)] p-4 rounded snow_effect ">
              <div className="flex items-center justify-between space-x-2 mb-1">
                <div className="font-bold"></div>
                <time className="font-caveat font-medium text-white">
                  {item.title}
                </time>
              </div>
              <div className="text-white text-sm">
                <span className="font-bold">{item.content}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
