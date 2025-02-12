import React, { useState, useEffect } from "react";
import { useAccount, useBalance } from "wagmi";
import { toReadableAmount, didUserReject } from "utils/customHelpers";
import { getPresaleAddress } from "utils/addressHelpers";
import { usePresaleContract, useNFTContract } from "hooks/useContract";
import LogoLoading from "components/LogoLoading";
import { notify } from "utils/toastHelper";
import { FaCheck } from "react-icons/fa";

export default function NFTCard({
  tokenId,
  index,
  presaleData,
  active,
  myNFTID,
}) {
  const preslaeContractAddress = getPresaleAddress();
  const presaleContract = usePresaleContract();
  const nftContract = useNFTContract();
  const { address } = useAccount();
  const { data } = useBalance({
    address: address,
  });
  const [pendingTx, setPendingTx] = useState(false);
  const [delay, setDelay] = useState(true);
  const [isSold, setIsSold] = useState(false);

  const NFTPrice =
    presaleData?.NFTPrice &&
    toReadableAmount(presaleData?.NFTPrice.toString(), 18);

  const handleBuyNFT = async () => {
    if (!presaleData?.NFTPrice) {
      return;
    }

    if (!presaleData?.enabled) {
      notify("error", "Presale is not started yet");
      return;
    }
    if (presaleData?.sale_finalized) {
      notify("error", "Presale is ended");
      return;
    }
    if (
      Number(data?.formatted) <=
      Number(toReadableAmount(presaleData?.NFTPrice?.toFixed(0), 18, 5))
    ) {
      notify("warning", "Insufficient Balance");
      return;
    }
    try {
      setPendingTx(true);
      const tx = await presaleContract.buyNFT(tokenId, {
        from: address,
        value: presaleData?.NFTPrice?.toFixed(0),
      });
      await tx.wait();
      setPendingTx(false);
      notify("success", `You bought SNOW NFT successfully`);
      checkIsSold();
    } catch (error) {
      setPendingTx(false);
      if (didUserReject(error)) {
        notify("warning", "User Rejected transaction");
        return;
      } else {
        notify("warning", error.reason);
        return;
      }
    }
  };

  const handleImageError = (event) => {
    event.target.src = "/assets/stickers/NFT.webp";
  };

  const checkIsSold = async () => {
    if (address) {
      const owner = await nftContract.ownerOf(tokenId);
      if (owner !== preslaeContractAddress) {
        setIsSold(true);
      } else {
        setIsSold(false);
      }
    } else {
      setIsSold(false);
    }
  };

  useEffect(() => {
    checkIsSold();
    setTimeout(() => {
      setDelay(false);
    }, 1000);
  }, [tokenId]);

  if (active) {
    return (
      <>
        <div
          key={tokenId}
          className={`w-full sm:min-h-[337px] min-h-[250px] sm:p-6 p-2 rounded-lg snow_effect flex flex-col justify-between`}
        >
          <div>
            {delay ? (
              <div className="mx-auto h-[177px] sm:h-[190px] w-full bg-white/5 rounded-md animate-pulse"></div>
            ) : (
              <img
                key={tokenId}
                src={`https://snowbank.io/NFTs/sn${tokenId}.png`}
                onError={handleImageError}
                alt="NFT"
                className="w-full border-opacity-30 h-[177px] sm:h-[190px] object-cover"
              />
            )}
          </div>

          <div>
            <div className="flex justify-between px-2">
              <p>NFT ID: </p>
              <p>{tokenId}</p>
            </div>
            <div className="flex justify-between px-2">
              <p>Price: </p>
              <p>{NFTPrice} PLS</p>
            </div>
            {isSold ? (
              <button
                key={tokenId}
                disabled={true}
                className="main_btn mx-auto mt-4 py-[9px!important] opacity-50 text-green-400 flex items-center"
              >
                <FaCheck className="text-green-400 text-xl mr-1 my-auto mt-1" />{" "}
                Sold
              </button>
            ) : (
              <button
                key={tokenId}
                onClick={handleBuyNFT}
                className="main_btn mx-auto mt-4 py-[9px!important]"
              >
                Buy Now
              </button>
            )}
          </div>
        </div>
        {pendingTx && <LogoLoading />}
      </>
    );
  } else {
    return (
      <div
        className={`w-full max-w-[400px] min-h-[227px] mx-auto my-3 p-6 rounded-lg snow_effect flex flex-col justify-between`}
      >
        <div>
          {delay ? (
            <div className="mx-auto w-full  h-[300px] sm:h-[400px] bg-white/5 rounded-md animate-pulse"></div>
          ) : (
            <img
              src={`https://snowbank.io/NFTs/sn${myNFTID}.png`}
              onError={handleImageError}
              alt="NFT"
              className="w-full border-opacity-30 h-[300px] sm:h-[400px] object-cover"
            />
          )}
        </div>
      </div>
    );
  }
}
