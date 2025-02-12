import { useEffect, useState } from "react";
import BigNumber from "bignumber.js";
import {
  getErc20Contract,
  getSNOWContract,
  getMasterchefContract,
} from "utils/contractHelpers";
import { BIG_ZERO } from "utils/bigNumber";
import useRefresh from "./useRefresh";
import useLastUpdated from "./useLastUpdated";
import { useEthersProvider } from "./useEthers";
import { useAccount, useNetwork } from "wagmi";
import { CHAIN_ID } from "config";
import { toReadableAmount } from "utils/customHelpers";
const FetchStatus = {
  NOT_FETCHED: "not-fetched",
  SUCCESS: "success",
  FAILED: "failed",
};

const useTokenBalance = (tokenAddress) => {
  const { NOT_FETCHED, SUCCESS, FAILED } = FetchStatus;
  const [balanceState, setBalanceState] = useState({
    balance: BIG_ZERO,
    fetchStatus: NOT_FETCHED,
  });
  const { address } = useAccount();
  const { fastRefresh } = useRefresh();
  const provider = useEthersProvider();
  useEffect(() => {
    const fetchBalance = async () => {
      try {
        const contract = getErc20Contract(tokenAddress, provider);
        const res = await contract.balanceOf(address);
        setBalanceState({ balance: res, fetchStatus: SUCCESS });
      } catch (e) {
        console.log(e);
        setBalanceState((prev) => ({
          ...prev,
          fetchStatus: FAILED,
        }));
      }
    };

    if (address && provider) {
      fetchBalance();
    }
  }, [address, tokenAddress, fastRefresh, SUCCESS, FAILED, provider]);

  return balanceState;
};

export const useTotalSupply = () => {
  const { fastRefresh } = useRefresh();
  const [totalSupply, setTotalSupply] = useState(0);
  const { chain } = useNetwork();
  const provider = useEthersProvider();
  useEffect(() => {
    async function fetchTotalSupply() {
      const snowContract = getSNOWContract(
        provider,
        chain ? chain.id : CHAIN_ID
      );
      const supply = await snowContract.totalSupply();
      setTotalSupply(toReadableAmount(supply));
    }
    fetchTotalSupply();
  }, [fastRefresh]);

  return totalSupply;
};

export const useSNOWPerSecond = () => {
  const { fastRefresh } = useRefresh();
  const [snowPerSecond, setSnowPerSecond] = useState(BIG_ZERO);
  const { chain } = useNetwork();
  const provider = useEthersProvider();

  useEffect(() => {
    async function fetchSnowPerSecond() {
      try {
        const masterChefContract = getMasterchefContract(provider);
        const perSecond = await masterChefContract.SnowPerSecond();
        setSnowPerSecond(toReadableAmount(perSecond, 18, 5));
      } catch (e) {
        console.log(e.reason);
      }
    }
    if (provider) fetchSnowPerSecond();
  }, [fastRefresh, provider]);

  return snowPerSecond;
};

export const useBurnedBalance = (tokenAddress) => {
  const [balance, setBalance] = useState(BIG_ZERO);
  const { fastRefresh } = useRefresh();
  const provider = useEthersProvider();

  useEffect(() => {
    const fetchBalance = async () => {
      const contract = getErc20Contract(tokenAddress, provider);
      const res = await contract.balanceOf(
        "0x0000000000000000000000000000000000000000dEaD"
      );
      setBalance(new BigNumber(res));
    };

    fetchBalance();
  }, [tokenAddress, fastRefresh]);

  return balance;
};

export const useSNOWBurnedBalance = () => {
  const [balance, setBalance] = useState(BIG_ZERO);
  const { fastRefresh } = useRefresh();
  const { chain } = useNetwork();
  const provider = useEthersProvider();
  useEffect(() => {
    const fetchBalance = async () => {
      const snowContract = getSNOWContract(
        provider,
        chain ? chain.id : CHAIN_ID
      );
      const res = await snowContract.totalFees();
      setBalance(new BigNumber(res).div(new BigNumber(3))); // 1/3 of total fees are burning
    };

    fetchBalance();
  }, [fastRefresh]);

  return balance;
};

export const useGetPLSBalance = () => {
  const [balance, setBalance] = useState(BIG_ZERO);
  const { address } = useAccount();
  const { lastUpdated, setLastUpdated } = useLastUpdated();
  const provider = useEthersProvider();

  useEffect(() => {
    const fetchBalance = async () => {
      const walletBalance = await provider.getBalance(address);
      setBalance(new BigNumber(walletBalance));
    };

    if (address) {
      fetchBalance();
    }
  }, [address, provider, lastUpdated, setBalance]);

  return { balance, refresh: setLastUpdated };
};

export default useTokenBalance;
