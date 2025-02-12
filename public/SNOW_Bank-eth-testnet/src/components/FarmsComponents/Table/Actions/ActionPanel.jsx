import React, { useMemo, useEffect, useState } from "react";
import styled from "styled-components";
import { useTranslation } from "context/Localization";
import { LinkExternal, Text } from "uikit";
import getLiquidityUrlPathParts from "utils/getLiquidityUrlPathParts";
import { getScanAddressUrl } from "utils/getExplorerURL";
import {
  DepositLockDicountTag,
  NoFeesTag,
  SingleStakeTag,
  NFTStakeTag,
  CoreTag,
} from "components/Tags";
import { BASE_ADD_LIQUIDITY_URL, BASE_SWAP_URL } from "config";

import HarvestAction from "./HarvestAction";
import StakedAction from "./StakedAction";
import Apr from "../Apr";
import Multiplier from "../Multiplier";
import Liquidity from "../Liquidity";
import SnowCellLayout from "../SnowCellLayout";
import { formatAddress } from "utils/customHelpers";
import { FiExternalLink } from "react-icons/fi";

const StyledLinkExternal = styled(LinkExternal)`
  font-weight: 400;
  color: white;
  font-size: 12px;
`;

const StakeContainer = styled.div`
  align-items: center;
  display: flex;
  justify-content: space-between;

  @media screen and (min-width: 576px) {
    justify-content: flex-start;
  }
`;

const TagsContainer = styled.div`
  display: flex;
  align-items: center;

  @media screen and (max-width: 576px) {
    flex-direction: column;
    margin-top: 0;
    gap: 0.5rem;
  }
  > div {
    height: 24px;
    font-size: 14px;
    margin-right: 4px;
    border-radius: 5px;

    svg {
      width: 14px;
    }
  }
`;
const ValueWrapper = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 4px 0px;
`;

const ActionPanel = ({
  details,
  apr,
  multiplier,
  liquidity,
  userDataReady,
}) => {
  const [farm, setFarm] = useState(details);

  const { t } = useTranslation();
  const tokenOnly = farm.isTokenOnly;
  const nftOnly = farm.isNFTPool;
  const isActive = farm.multiplier !== "0X";
  const { quoteToken, token } = farm;
  const lpLabel =
    farm.lpSymbol && farm.lpSymbol.toUpperCase().replace("PANARB", "");
  const liquidityUrlPathParts = getLiquidityUrlPathParts({
    quoteTokenAddress: quoteToken.address,
    tokenAddress: token.address,
  });
  const lpAddress = farm.lpAddresses;
  const scan = useMemo(
    () => getScanAddressUrl(tokenOnly ? farm.token.address : lpAddress),
    [tokenOnly, lpAddress, farm.token.address]
  );
  const noFees = parseFloat(farm.depositFee) === 0;
  const link = useMemo(
    () =>
      tokenOnly
        ? `${BASE_SWAP_URL}?outputCurrency=${farm.token.address}`
        : `${BASE_ADD_LIQUIDITY_URL}/${liquidityUrlPathParts}`,
    [tokenOnly, liquidityUrlPathParts, farm.token.address]
  );

  useEffect(() => {
    setFarm(details);
  }, [details]);

  return (
    <div className="">
      <SnowCellLayout label={t("Get %symbol%", { symbol: lpLabel })}>
        <a
          href={nftOnly ? "/nfts" : link}
          className="box-text flex gap-1"
          target={!nftOnly && "_blank"}
          disabled={true}
        >
          {t("%symbol%", { symbol: lpLabel })}{" "}
          <FiExternalLink className="my-auto text-sm" />
        </a>
      </SnowCellLayout>

      <SnowCellLayout label="View Contract">
        <a
          href={scan}
          className="box-text flex gap-2"
          target={"_blank"}
          rel="noreferrer"
        >
          {formatAddress(farm.lpAddresses, 6)}{" "}
          <FiExternalLink className="my-auto text-sm" />
        </a>
      </SnowCellLayout>

      <SnowCellLayout label="Tags">
        <TagsContainer>
          {details?.pid === 0 && <CoreTag />}
          {noFees && <NoFeesTag />}
          {farm.withDepositLockDiscount && <DepositLockDicountTag />}
          {tokenOnly && !details?.isNFTPool && <SingleStakeTag />}
          {nftOnly && <NFTStakeTag />}
        </TagsContainer>
      </SnowCellLayout>

      <HarvestAction {...farm} userDataReady={userDataReady} />
      <StakedAction {...farm} userDataReady={userDataReady} />
    </div>
  );
};

export default ActionPanel;
