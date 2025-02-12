import React from "react";
import SNOW from "components/UI/SNOW";
import ETH from "components/UI/ETH";
import { SALE_PRICE, NFT_PRICE, MAX_PER_USER, LAUNCH_PRICE } from "config";
import { BASE_EXPLORER } from "config";
import { getPresaleAddress } from "utils/addressHelpers";
import { formatAddress } from "utils/customHelpers";
import { CountDownComponentClaim } from "components/CountDownClaim";
import PLS from "components/UI/PLS";

export default function PresaleDetails({ saleData, ethRaised }) {
  return (
    <div className="col-span-12 sm:col-span-6">
      <div className="w-full rounded-md p-4 snow_effect">
        <div className="balance_form">
          <div className="my-8">
            <div className="flex justify-between mb-4 px-1">
              <div> Total Raised ETH:</div>
              <div className="flex gap-1">
                {Number(ethRaised).toFixed(5) || "0.00"} <ETH />
              </div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div> Total Raised PLS:</div>
              <div className="flex gap-1">
                {Number(saleData?.total_deposited).toFixed(5) || "0.00"} <PLS />
              </div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div> Max SNOW Per Wallet:</div>
              <div className="flex gap-1">
                100,000 ($4,000 USD) <SNOW />
              </div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div> NFT Price:</div>
              <div className="flex gap-1">
                {saleData?.NFTPrice} <PLS />
              </div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div> Presale Price:</div>
              <div>{saleData?.presalePriceOfToken} cents</div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div> Launch Price:</div>
              <div>6 cents</div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div> Vesting Period:</div>
              <div>10 days</div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div> Vesting Percent:</div>
              <div>10% daily</div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div>Sale Ends In:</div>
              <div>
                <CountDownComponentClaim time={1704579867764} />
              </div>
            </div>
            <div className="flex justify-between mb-4 px-1">
              <div>Farming Starts In:</div>
              <div>
                <CountDownComponentClaim time={1704579867764} />
              </div>
            </div>
            {/* <div className="flex justify-between mb-4 px-1">
              <div>Sale Finished Time:</div>
              <div>
                {saleData?.finishedTimestamp
                  ? new Date(saleData?.finishedTimestamp * 1000).toDateString()
                  : "0000-00-00 00:00:00"}
              </div>
            </div> */}
            <div className="flex justify-between mb-4 px-1">
              <div> Launch Date:</div>
              <div>January 6th 2024</div>
            </div>
            {/* <div className="flex justify-between mb-4 px-1">
              <div> Presale End Date:</div>
              <div>2024-01-06</div>
            </div> */}
            <div className="flex justify-between mb-3 px-1">
              <div>Contract:</div>
              <div>
                <a
                  href={`${BASE_EXPLORER}/address/${getPresaleAddress()}`}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {formatAddress(getPresaleAddress(), 4)}
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
