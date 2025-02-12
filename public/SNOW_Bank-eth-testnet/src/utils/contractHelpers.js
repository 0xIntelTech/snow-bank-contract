import { ethers } from "ethers";
// Addresses
import {
  getSNOWAddress,
  getMasterChefAddress,
  getMulticallAddress,
  getZapAddress,
  getOracleAddress,
  getFactoryAddress,
  getRouterAddress,
  getNFTAddress,
  getPresaleAddress,
  getPresaleForkAddress,
} from "utils/addressHelpers";

// ABI
import erc20Abi from "config/abis/erc20.json";
import lpTokenAbi from "config/abis/lpToken.json";
import snowAbi from "config/abis/snow.json";
import masterChef from "config/abis/masterchef.json";
import MultiCallAbi from "config/abis/Multicall.json";
import zapABI from "config/abis/zap.json";
import oracleABI from "config/abis/oracle.json";
import routerABI from "config/abis/router.json";
import factoryABI from "config/abis/factory.json";
import nftABI from "config/abis/nft.json";
import PresaleABI from "config/abis/presale.json";
import PresaleForkABI from "config/abis/presaleFork.json";

import { DEFAULT_GAS_PRICE } from "config";
// import { getSettings, getGasPriceInWei } from './settings'

export const getDefaultGasPrice = () => {
  return DEFAULT_GAS_PRICE;
};

const getContract = (abi, address, provider) => {
  return new ethers.Contract(address, abi, provider);
};

export const getErc20Contract = (address, provider) => {
  return getContract(erc20Abi, address, provider);
};
export const getErc721Contract = (address, provider) => {
  return getContract(nftABI, address, provider);
};

export const getLpContract = (address, provider) => {
  return getContract(lpTokenAbi, address, provider);
};
export const getSNOWContract = (provider, chainId) => {
  return getContract(snowAbi, getSNOWAddress(), provider);
};
export const getMasterchefContract = (provider, chainId) => {
  return getContract(masterChef, getMasterChefAddress(), provider);
};
export const getMulticallContract = (provider, chainId) => {
  return getContract(MultiCallAbi, getMulticallAddress(), provider);
};
export const getZapContract = (provider, chainId) => {
  return getContract(zapABI, getZapAddress(), provider);
};
export const getOracleContract = (provider, chainId) => {
  return getContract(oracleABI, getOracleAddress(), provider);
};
export const getFactoryContract = (provider, chainId) => {
  return getContract(factoryABI, getFactoryAddress(), provider);
};
export const getRouterContract = (provider, chainId) => {
  return getContract(routerABI, getRouterAddress(), provider);
};
export const getNFTContract = (provider) => {
  return getContract(nftABI, getNFTAddress(), provider);
};
export const getPresaleContract = (provider) => {
  return getContract(PresaleABI, getPresaleAddress(), provider);
};
export const getPresaleForkContract = (provider) => {
  return getContract(PresaleForkABI, getPresaleForkAddress(), provider);
};
