import { useMemo } from "react";
import { useEthersProvider, useEthersSigner } from "hooks/useEthers";
import {
  getErc20Contract,
  getErc721Contract,
  getSNOWContract,
  getMasterchefContract,
  getZapContract,
  getRouterContract,
  getFactoryContract,
  getNFTContract,
  getPresaleContract
} from "utils/contractHelpers";
import { useNetwork } from "wagmi";
import { CHAIN_ID } from "config";
/**
 * Helper hooks to get specific contracts (by ABI)
 */

export const useERC20 = (address) => {
  const signer = useEthersSigner();
  return useMemo(() => getErc20Contract(address, signer), [address, signer]);
};
export const useERC721 = (address) => {
  const signer = useEthersSigner();
  return useMemo(() => getErc721Contract(address, signer), [address, signer]);
};

export const useSNOW = () => {
  const provider = useEthersProvider();
  const { chain } = useNetwork();
  return useMemo(
    () =>
      chain && chain.id === CHAIN_ID && getSNOWContract(provider, chain?.id),
    [provider, chain]
  );
};

export const useMasterchef = () => {
  const signer = useEthersSigner();
  const { chain } = useNetwork();
  return useMemo(
    () =>
      chain &&
      chain.id === CHAIN_ID &&
      getMasterchefContract(signer, chain?.id),
    [signer, chain]
  );
};

export const useZapContract = () => {
  const signer = useEthersSigner();
  const { chain } = useNetwork();
  return useMemo(
    () => chain && chain.id === CHAIN_ID && getZapContract(signer, chain?.id),
    [signer, chain]
  );
};

export const useFactoryContract = () => {
  const provider = useEthersProvider();
  const { chain } = useNetwork();
  return useMemo(
    () =>
      chain && chain.id === CHAIN_ID && getFactoryContract(provider, chain?.id),
    [provider, chain]
  );
};

export const useRouterContract = () => {
  const signer = useEthersSigner();
  const { chain } = useNetwork();
  return useMemo(
    () =>
      chain && chain.id === CHAIN_ID && getRouterContract(signer, chain?.id),
    [signer, chain]
  );
};

export const useNFTContract = () => {
  const signer = useEthersSigner();
  const provider = useEthersProvider();
  const { chain } = useNetwork();
  return useMemo(
    () => chain && chain.id === CHAIN_ID && getNFTContract(signer ? signer : provider),
    [signer, chain]
  );
};

export const usePresaleContract = () => {
  const signer = useEthersSigner();
  const { chain } = useNetwork();
  return useMemo(
    () => chain && chain.id === CHAIN_ID && getPresaleContract(signer),
    [signer, chain]
  );
};
