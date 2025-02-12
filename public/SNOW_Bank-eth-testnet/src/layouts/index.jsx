import LogoLoading from "components/LogoLoading";
import React from "react";
import Footer from "./Footer";
import Header from "./Header";

export default function Layout({ children }) {
  return (
    <>
      <div className="snow"></div>
      <div className="w-full min-h-[calc(100vh)] py-[90px] relative px-1">
        <Header />
        <div className="flex w-full h-full justify-center pb-6">{children}</div>
        <Footer />
      </div>
      <div className="bg-gradient"></div>
    </>
  );
}
