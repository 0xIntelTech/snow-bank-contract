import React, { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { toReadableAmount } from "utils/customHelpers";
import ClaimComponent from "components/ClaimComponent";
import SaleComponent from "components/Presale/SaleComponent";
import useRefresh from "hooks/useRefresh";
import PreslaeABI from "config/abis/presale.json";
import { getPresaleAddress } from "utils/addressHelpers";
import multicall from "utils/multicall";
// import { CountDownComponent } from "../components/CountDown";
// import { BASE_EXPLORER } from "config";
import Banner from "components/Presale/Banner";
// import Tab from "components/Presale/Tab";
import PresaleDetails from "components/Presale/PresaleDetails";
import { useEthersProvider, useEthersSigner } from "hooks/useEthers";
import Tab from "components/Presale/Tab";
// import LogoLoading from "components/LogoLoading";
import { ref, push, query, onValue, update, get } from "firebase/database";
import { db } from "config/firebase";
import { CountDownComponent } from "components/CountDown";

export default function SnowPresale() {
  const preslaeContractAddress = getPresaleAddress();
  const { address } = useAccount();
  const { fastRefresh } = useRefresh();
  const [active, setActive] = useState(0);
  const [presaleData, setPresaleData] = useState({});
  const [ethRaised, setTotalRaisedPLS] = useState();

  useEffect(() => {
    const fetchData = async () => {
      const calls = [
        {
          address: preslaeContractAddress,
          name: "enabled",
          params: [],
        },
        {
          address: preslaeContractAddress,
          name: "sale_finalized",
          params: [],
        },
        {
          address: preslaeContractAddress,
          name: "finishedTimestamp",
          params: [],
        },
        {
          address: preslaeContractAddress,
          name: "presalePriceOfToken",
          params: [],
        },
        {
          address: preslaeContractAddress,
          name: "rate",
          params: [],
        },
        {
          address: preslaeContractAddress,
          name: "MAX_AMOUNT",
          params: [],
        },
        {
          address: preslaeContractAddress,
          name: "total_deposited",
          params: [],
        },
        {
          address: preslaeContractAddress,
          name: "NFTPrice",
          params: [],
        },
      ];

      try {
        const rawResults = await multicall(PreslaeABI, calls);
        rawResults.map((data, index) => {
          const newData =
            index <= 4
              ? {
                  [calls[index]["name"]]:
                    index >= 2 ? Number(data[0]) : data[0],
                }
              : index === 8
              ? { [calls[index]["name"]]: rawResults[index].toString() }
              : {
                  [calls[index]["name"]]: toReadableAmount(
                    rawResults[index].toString(),
                    18,
                    6
                  ),
                };

          const dbQuery = query(ref(db, "stats"));
          onValue(dbQuery, async (snapshot) => {
            const exist = snapshot.val();
            if (exist) {
              setTotalRaisedPLS(Number(exist[Object.keys(exist)[0]].pls || 0));
            }
          });
          setPresaleData((value) => ({ ...value, ...newData }));
        });
      } catch (e) {
        console.log("Fetch Farms With Balance Error:", e);
      }
    };

    fetchData();
  }, [fastRefresh]);

  useEffect(() => {
    const fetchData = async () => {
      const calls = [
        {
          address: preslaeContractAddress,
          name: "user_deposits",
          params: [address],
        },
        {
          address: preslaeContractAddress,
          name: "SNOWOwned",
          params: [address],
        },
        {
          address: preslaeContractAddress,
          name: "user_withdraw_amount",
          params: [address],
        },
        {
          address: preslaeContractAddress,
          name: "user_withdraw_timestamp",
          params: [address],
        },
        {
          address: preslaeContractAddress,
          name: "seed_investors",
          params: [address],
        },
      ];

      try {
        const rawResults = await multicall(PreslaeABI, calls);
        rawResults.map((data, index) => {
          const newData = {
            [calls[index]["name"]]:
              index >= 3
                ? index === 3
                  ? Number(rawResults[index])
                  : rawResults[index]
                : toReadableAmount(rawResults[index].toString(), 18, 6),
          };
          setPresaleData((value) => ({ ...value, ...newData }));
        });
      } catch (e) {
        console.log("Fetch Farms With Balance Error:", e.reason);
      }
    };

    if (address) {
      fetchData();
    }
  }, [address, fastRefresh]);

  return (
    <div className="min-h-[calc(100vh-200px)] max-w-[1200px] mx-3 container mt-8 sm:mt-4">
      {/* <CountDownComponent time={1704579867764} /> */}
      <Banner />

      <div className="w-full mt-3 grid grid-cols-12 gap-3">
        <div className="col-span-12 sm:col-span-6">
          <div className="rounded-lg">
            {/* <Tab active={active} setActive={setActive} /> */}
            {!presaleData?.sale_finalized ? (
              <SaleComponent saleData={presaleData} />
            ) : (
              <ClaimComponent saleData={presaleData} />
            )}
          </div>
        </div>

        <PresaleDetails saleData={presaleData} ethRaised={ethRaised} />
      </div>
    </div>
  );
}
