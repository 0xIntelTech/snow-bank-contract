import { useCallback } from "react";
import { compound } from "utils/callHelpers";
import { useMasterchef } from "./useContract";
import { useAccount } from "wagmi";

export const useCompound = (farmPid) => {
  const { address } = useAccount();
  const masterChefContract = useMasterchef();

  const handleCompound = useCallback(async () => {
    return await compound(masterChefContract, farmPid, address);
  }, [address, farmPid, masterChefContract]);

  return { onCompound: handleCompound };
};
