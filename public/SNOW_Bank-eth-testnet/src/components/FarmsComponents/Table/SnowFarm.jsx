import React from "react";
import { useFarmUser } from "state/hooks";
import { useTranslation } from "context/Localization";
import { Text } from "uikit";
import { getBalanceNumber } from "utils/formatBalance";
import DepositFee from "./DepositFee";
import { RiEdgeNewFill } from "react-icons/ri";

const Farm = ({
  isTokenOnly,
  token,
  quoteToken,
  label,
  pid,
  depositFee,
  hasDiscount,
}) => {
  const { stakedBalance } = useFarmUser(pid);
  const { t } = useTranslation();
  const rawStakedBalance = getBalanceNumber(stakedBalance);

  const handleRenderFarming = () => {
    if (rawStakedBalance) {
      return (
        <Text color="secondary" fontSize="12px">
          {t("Farming")}
        </Text>
      );
    }

    return null;
  };

  return (
    <div className="w-full">
      <div className="flex justify-center">
        {isTokenOnly ? (
          <div className="w-32 flex justify-end">
            <img src={token.logo} alt="" className="token" />
          </div>
        ) : (
          <div className="flex justify-end w-32">
            <img src={quoteToken.logo} alt="" className="token" />
            <img src="/assets/tokens/snow.png" alt="" className="token -ml-8" />
          </div>
        )}

        <RiEdgeNewFill className="text-white lg:mx-4 sm:mx-3 mx-6 my-auto text-2xl duration-200" />

        <div className="w-32">
          <img src="/assets/tokens/snow.png" alt="" className="token" />
        </div>
      </div>

      <div className="mt-4">
        {handleRenderFarming()}
        <p className="font-semibold text-sm lg:text-lg">{label}</p>

        <div className="flex justify-between mt-2">
          <div className="lg:text-[12px] text-[10px] text-gray-300">
            Deposit fee:
          </div>
          <div className="text-[12px]">
            <DepositFee
              depositFee={depositFee}
              isTokenOnly={isTokenOnly}
              hasDiscount={hasDiscount}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Farm;
