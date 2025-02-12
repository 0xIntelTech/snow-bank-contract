import React, { useEffect, useState } from "react";
import { useAccount } from "wagmi";
import { useNFTContract } from "hooks/useContract";
import NFTCard from "components/Presale/NFTCard";
import { notify } from "utils/toastHelper";
import useRefresh from "hooks/useRefresh";
import { didUserReject } from "utils/customHelpers";
import { useEthersSigner } from "hooks/useEthers";
import RecentBuys from "components/RecentBuys";
import LogoLoading from "components/LogoLoading";

export default function Zap() {
  const { address } = useAccount();
  const [nfts, setNfts] = useState(0);
  const [myTokenIds, setMyTokenIds] = useState([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [stats, setStats] = useState(true);
  const nftContract = useNFTContract();
  const { fastRefresh } = useRefresh();
  const signer = useEthersSigner();

  const getAvailableNFTs = async () => {
    const availableNFTs = await nftContract.getMaximumAmountCanMint(address);
    const myNFTs = await nftContract.balanceOf(address);
    if (Number(myNFTs) > 0) {
      const tokenIds = await nftContract.walletOfOwner(address);
      setMyTokenIds(tokenIds);
    }

    setNfts(Number(availableNFTs));
  };

  const claimNFT = async () => {
    if (nfts < 1) return;
    try {
      setIsProcessing(true);
      const tx = await nftContract.mint();
      await tx.wait();
      setIsProcessing(false);
      notify("success", "you have successfully claimed an NFT");
      await getAvailableNFTs();
    } catch (e) {
      if (didUserReject(e)) {
        notify("error", "User Rejected Transaction");
      } else {
        console.log(e);
        notify("error", e.reason);
      }
      setIsProcessing(false);
    }
  };

  useEffect(() => {
    if (signer && address) getAvailableNFTs();
  }, [fastRefresh, signer, address]);


  const NFTClaim = () => {
    if (!address) {
      return <p className="text-center text-blacks">
        Please connect wallet.
      </p>
    }

    if (nfts === 0) {
      return <p className="text-center text-blacks">
        You don't have any NFT(s) to claim.
      </p>
    }

    if (nfts) {
      return <p className="text-center text-blacks">
        You have {nfts} NFT(s) to claim.
      </p>
    }
  }

  return (
    <div className="container">
      <div className="flex my-6 py-1 bg-secondary w-fit mx-auto rounded-full">
        <button
          onClick={() => setStats(true)}
          className="text-center w-32 py-2 px-4 rounded-l-full border-[#243753e8] transition ease-in-out"
        >
          My NFTs
        </button>
      </div>

      {!stats ? (
        <RecentBuys last={12} />
      ) : (
        <>
          <div className={`grid ${myTokenIds.length >= 3 ? 'md:grid-cols-3' : myTokenIds.length == 0 ? 'md:grid-cols-1' : 'md:grid-cols-' + myTokenIds.length} grid-cols-1 gap-4 mt-16 max-w-[800px] mx-auto`}>
            {myTokenIds && myTokenIds.length > 0 ? (
              myTokenIds.map((tokenId, index) => (
                <NFTCard key={index} tokenId={tokenId} />
              ))
            ) : (
              <div className="w-full max-w-[250px] max-h-[300px] p-4 rounded-lg bg-secondary mx-auto">
                <img
                  src={"/assets/stickers/NFT.webp"}
                  alt="token"
                  className="w-full py-2 border-opacity-30"
                />
              </div>
            )}
          </div>

          <div className="flex justify-center items-center pb-16 m-2 mt-12">
            <button
              className="main_btn rounded-xl w-full max-w-sm flex justify-center px-6 py-3 hover:scale-105 transition ease-in-out mt-9"
              disabled={!address && !nfts}
              onClick={() => claimNFT()}
            >
              {NFTClaim()}
            </button>
          </div>
        </>
      )}
      {isProcessing &&
        <LogoLoading title="Claiming NFT..." />}
    </div>
  );
}
