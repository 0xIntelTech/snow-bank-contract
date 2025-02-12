import React, { useState, useEffect } from "react";
import { useAccount, useBalance } from "wagmi";
import {
  toReadableAmount,
  fromReadableAmount,
  didUserReject,
} from "utils/customHelpers";
import useRefresh from "hooks/useRefresh";
import PreslaeABI from "config/abis/presale.json";
import multicall from "utils/multicall";
import NFTBanner from "components/Presale/NFTBanner";
import LogoLoading from "components/LogoLoading";
import NFTCard from "components/Presale/NFTCard";
import NFTCardLoading from "components/Presale/NFTCardLoading";
import Loading from "components/Loading";
import ReactPaginate from "react-paginate";
import { getPresaleAddress } from "utils/addressHelpers";
import { AiOutlineLoading3Quarters } from "react-icons/ai";
import { usePresaleContract } from "hooks/useContract";
import { notify } from "utils/toastHelper";
import { getNFTContract } from "utils/contractHelpers";
import { useEthersProvider } from "hooks/useEthers";

export default function NFTPresale() {
  const presaleContractAddress = getPresaleAddress();
  const provider = useEthersProvider();
  const NFTContract = getNFTContract(provider);
  const saleArray = Array.from({ length: 10 });
  const [pendingTx, setPendingTx] = useState(true);
  const { address } = useAccount();
  const { fastRefresh } = useRefresh();
  const [active, setActive] = useState(true);
  const [presaleData, setPresaleData] = useState({});
  const [NFTs, setNFTs] = useState([]);
  const [page, setPage] = useState(1);
  const [maxPage, setMaxPage] = useState(41);

  const handlePageClick = (e) => {
    setPage(1 + e.selected * 10);
  };

  useEffect(() => {
    const fetchData = async () => {
      const calls = [
        {
          address: presaleContractAddress,
          name: "enabled",
          params: [],
        },
        {
          address: presaleContractAddress,
          name: "sale_finalized",
          params: [],
        },
        {
          address: presaleContractAddress,
          name: "NFTPrice",
          params: [],
        },
      ];

      try {
        const rawResults = await multicall(PreslaeABI, calls);
        rawResults.map((data, index) => {
          const newData =
            index <= 5
              ? {
                  [calls[index]["name"]]:
                    index >= 2 ? Number(data[0]) : data[0],
                }
              : index === 9
              ? { [calls[index]["name"]]: rawResults[index].toString() }
              : {
                  [calls[index]["name"]]: toReadableAmount(
                    rawResults[index].toString(),
                    18,
                    6
                  ),
                };

          setPresaleData((value) => ({ ...value, ...newData }));
        });
      } catch (e) {
        console.log("Fetch Farms With Balance Error:", e);
      }
    };

    fetchData();
  }, [fastRefresh]);

  useEffect(() => {
    async function fetchNFTs() {
      let nfts = [];
      try {
        nfts = address ? await NFTContract.walletOfOwner(address) : [];
        setNFTs(nfts);
      } catch (error) {
        console.log(error);
      }
    }

    if (NFTContract) {
      fetchNFTs();
    }
  }, [active]);

  useEffect(() => {
    async function fetchNFTs() {
      try {
        let nfts = await NFTContract.walletOfOwner(address);
        setNFTs(nfts || []);
        setPendingTx(false);
      } catch (error) {
        console.log(error);
        setPendingTx(false);
      }
    }

    if (NFTContract && address) {
      fetchNFTs();
      setPendingTx(true);
    } else {
      setPendingTx(true);
    }
  }, [active, address]);

  return (
    <div className="container max-w-[1200px] mx-3 sm:px-0 mt-8 sm:mt-4">
      <NFTBanner />

      <div className="my-4 flex gap-3">
        <button
          onClick={() => {
            setPendingTx(true);
            setActive(true);
          }}
          className={`snow_effect px-3 py-2 hover:bg-primary/40 transition ease-in-out ${
            active ? "bg-[#058ee7!important]" : ""
          }`}
        >
          Listed NFTs
        </button>
        <button
          onClick={() => {
            setPendingTx(true);
            setActive(false);
          }}
          className={`snow_effect px-3 py-2 hover:bg-primary/40 transition ease-in-out  ${
            !active ? "bg-[#058ee7!important]" : ""
          }`}
        >
          My NFTs
        </button>
      </div>

      {active ? (
        <div className={`relative`}>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 mt- 6 mx-auto mb-8">
            {saleArray.map((_, index) => {
              if (index + page <= maxPage)
                return (
                  <NFTCard
                    tokenId={index + page}
                    key={index}
                    presaleData={presaleData}
                    index={index}
                    active={active}
                  />
                );
            })}
          </div>
          <ReactPaginate
            breakLabel="..."
            nextLabel=">"
            onPageChange={handlePageClick}
            pageRangeDisplayed={2}
            marginPagesDisplayed={1}
            pageCount={5}
            previousLabel="<"
            renderOnZeroPageCount={null}
            className="pagination"
          />
        </div>
      ) : (
        <>
          {pendingTx ? (
            <div className="flex justify-center my-32 sm:my-[200px]">
              <AiOutlineLoading3Quarters className="text-3xl font-bold animate-spin" />
            </div>
          ) : (
            <div>
              {NFTs?.length > 0 ? (
                NFTs.map((id, index) => {
                  return (
                    <NFTCard
                      tokenId={index + 1}
                      key={index}
                      presaleData={presaleData}
                      index={index}
                      active={active}
                      myNFTID={id}
                    />
                  );
                })
              ) : (
                <div className="w-full flex justify-center items-center flex-col">
                  <p className="my-6 text-lg text-center w-full">
                    You don't have any NFT(s).
                  </p>
                  <button
                    className="snow_effect mx-auto py-2 px-3"
                    onClick={(e) => setActive(true)}
                  >
                    Buy Now
                  </button>
                </div>
              )}
            </div>
          )}
        </>
      )}
    </div>
  );
}
