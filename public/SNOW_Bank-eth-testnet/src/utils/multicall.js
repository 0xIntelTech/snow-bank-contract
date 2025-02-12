import { Interface } from "@ethersproject/abi";
import { getMulticallContract } from "utils/contractHelpers";
import httpProvider from "./providerHelpers";
// Addresses
const multicall = async (abi, calls) => {
  try {
    const multi = getMulticallContract(httpProvider);
    const itf = new Interface(abi);
    const calldata = calls.map((call) => [
      call.address.toLowerCase(),
      itf.encodeFunctionData(call.name, call.params),
    ]);
    const { returnData } = await multi.callStatic.aggregate(calldata);
    const res = returnData.map((call, i) =>
      itf.decodeFunctionResult(calls[i].name, call)
    );

    return res;
  } catch (error) {
    console.log("multicall:", error)
    throw new Error(error);
  }
};

export default multicall;
