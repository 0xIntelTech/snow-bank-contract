import contractAddresses from "constants/addresses";
import tokens from "config/tokens";

export const getRouterAddress = () => {
  return contractAddresses.router;
};
export const getFactoryAddress = () => {
  return contractAddresses.factory;
};

export const getSNOWAddress = () => {
  return tokens.snow.address;
};
export const getMasterChefAddress = () => {
  return contractAddresses.masterChef;
};
export const getMulticallAddress = () => {
  return contractAddresses.multiCall;
};
export const getWethAddress = () => {
  return tokens.wpls.address;
};
export const getNFTAddress = () => {
  return contractAddresses.nft;
};
export const getPresaleAddress = () => {
  return contractAddresses.presaleContract;
};
export const getZapAddress = () => {
  return contractAddresses.zap;
};
export const getOracleAddress = () => {
  return contractAddresses.oracle;
};
export const getPresaleForkAddress = () => {
  return contractAddresses.presaleFork;
};
export const getBILLAddress = () => {
  return tokens.bill.address;
};
