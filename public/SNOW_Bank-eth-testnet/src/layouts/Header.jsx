import React, { useEffect, useState } from "react";
import { Fade as Hamburger } from "hamburger-react";
import { routes } from "config";
import { WalletConnect } from "components/UI/ConnectButton";
import { Link, useLocation } from "react-router-dom";
import { DOCS_URL } from "config";

export default function Header() {
  const [isMobile, setMobile] = useState(false);
  const [scrollHeader, setScrollHeader] = useState(false);
  const location = useLocation();

  useEffect(() => {
    window.addEventListener("scroll", () => {
      if (window.scrollY > 5) {
        setScrollHeader(true);
      } else {
        setScrollHeader(false);
      }
    });
  }, []);

  return (
    <div
      className={`w-full top-0 fixed left-1/2 -translate-x-1/2 px-3 z-50 duration-200 ${
        scrollHeader ? "bg-secondary py-3" : "py-4"
      }`}
    >
      <div className="container mx-auto relative">
        <div className="flex justify-between">
          <div className="logo relative items-center flex">
            <a
              href="/"
              className="absolute -top-1 left-0 h-[65px] w-[72px] hidden sm:inline-block"
            >
              <img src="/logo.png" className="h-[70px] w-[75px]" alt="" />
            </a>
            <div
              className="text-white ml-2 block sm:hidden my-auto"
              onClick={() => setMobile(!isMobile)}
            >
              <Hamburger toggled={isMobile} />
            </div>
          </div>
          <div className="hidden lg:flex absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
            <ul className="nav_list gap-3">
              {routes.map((link, key) => (
                <li
                  className={`list_item py-2 px-3 text-white text-[12px!important]  ${
                    location.pathname === link.url ? "snow_effect_nav" : ""
                  }`}
                  key={key}
                >
                  <Link to={link.url}>{link.name}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="sm:hidden"></div>
          <div className="nav_action">
            <WalletConnect />
            <div
              className="text-white ml-2 hidden sm:block lg:hidden"
              onClick={() => setMobile(!isMobile)}
            >
              <Hamburger />
            </div>
          </div>
        </div>
      </div>
      {isMobile === true ? (
        <div className="w-full bg-white/5 backdrop-blur-2xl mt-2 rounded-md shadow shadow-black mr-auto ml-auto">
          <div className="nav_bar mobile_navbar">
            <ul className="nav_list">
              {routes.map((link, key) => (
                <li
                  className={`list_item cursor-pointer ${
                    location.pathname === link.url ? "active" : ""
                  }`}
                  key={key}
                >
                  <Link to={link.url} onClick={() => setMobile(false)}>
                    {link.name}
                  </Link>
                </li>
              ))}
              <li className={`list_item cursor-pointer`}>
                <Link
                  to={DOCS_URL}
                  target="_blank"
                  className={`p-3`}
                  rel="noopener noreferrer"
                >
                  Docs
                </Link>
              </li>
            </ul>
          </div>
        </div>
      ) : (
        ""
      )}
    </div>
  );
}
