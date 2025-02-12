import { ConnectButton } from "@rainbow-me/rainbowkit";
import contractAddresses from "constants/addresses";
import { FaAngleDown } from "react-icons/fa";
import { usePriceSNOWUsdc } from "state/hooks";
export const WalletConnect = () => {
  const priceData = usePriceSNOWUsdc();
  return (
    <ConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        authenticationStatus,
        mounted,
      }) => {
        // Note: If your app doesn't use authentication, you
        // can remove all 'authenticationStatus' checks
        const ready = mounted && authenticationStatus !== "loading";
        const connected =
          ready &&
          account &&
          chain &&
          (!authenticationStatus || authenticationStatus === "authenticated");
        return (
          <div
            {...(!ready && {
              "aria-hidden": true,
              style: {
                opacity: 0,
                pointerEvents: "none",
                userSelect: "none",
              },
            })}
          >
            {(() => {
              if (!connected) {
                return (
                  <button
                    onClick={openConnectModal}
                    type="button"
                    className="main_btn px-5 sm:m-0 transition ease-in-out"
                  >
                    Connect Wallet
                  </button>
                );
              }
              if (chain.unsupported) {
                return (
                  <button
                    onClick={openChainModal}
                    type="button"
                    className="m-2 main_btn py-1.5  sm:m-0  bg-[red!important]  transition ease-in-out text-[white!important] flex justify-center items-center gap-1 px-4 rounded-full"
                  >
                    Wrong network
                    <FaAngleDown className="text-xl" />
                  </button>
                );
              }
              return (
                <div className="flex items-center">
                  <a
                    href={`https://dexscreener.com/pulsechain/${contractAddresses.snowWplslp}`}
                    target="_blank"
                    className="hidden sm:flex items-center text-white"
                    rel="noreferrer"
                  >
                    <img
                      src="/logo32.png"
                      alt="logo"
                      className="w-[33.5px] h-[33.5px] mx-1"
                    />
                    $ {Number(priceData[0]) ? `${priceData[0].toString()}` : ""}
                  </a>
                  <button
                    onClick={openChainModal}
                    className="inline-flex justify-center snow_effect_chain items-center rounded-full  transition ease-in-out text-black text-xl mr-1"
                  >
                    {chain.iconUrl ? (
                      <img
                        alt={chain.name ?? "Chain icon"}
                        src={chain.iconUrl}
                        className="h-[30px!important] w-[30px!important]"
                      />
                    ) : (
                      <img
                        alt={chain.name ?? "Chain icon"}
                        src="/chain.svg"
                        className="h-[30px!important] w-[30px!important]"
                      />
                    )}
                  </button>
                  <div className="hidden sm:inline-block text-sm font-light">
                    {Number(account.balanceFormatted).toFixed(4)}{" "}
                    <span className="text-[10px]">&nbsp;( PLS )</span>{" "}
                  </div>
                  <button
                    onClick={openAccountModal}
                    className="m-2 sm:m-0 main_btn px-5 py-1transition py-1.5 ease-in-out flex justify-center items-center gap-1"
                    type="button"
                  >
                    {account.displayName}
                    <FaAngleDown className="text-xl" />
                  </button>
                </div>
              );
            })()}
          </div>
        );
      }}
    </ConnectButton.Custom>
  );
};
