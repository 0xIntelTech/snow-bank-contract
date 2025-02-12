/* eslint-disable react-hooks/exhaustive-deps */
import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import router_abi from "config/abis/router";
import factory_abi from "config/abis/factory";
import { getFactoryAddress, getRouterAddress } from "utils/addressHelpers";
import { useEthersProvider, useEthersSigner } from "hooks/useEthers";

export const ContractContext = React.createContext(null);

export const ContractContextProvideer = (props) => {
  const router_address = getRouterAddress();
  const factory_address = getFactoryAddress();

  const provider = useEthersProvider();
  const signer = useEthersSigner();

  const [routerSigner, setRouterSigner] = useState();
  const [factorySigner, setFactorySigner] = useState();

  const [routerProvider, setRouterProvider] = useState();
  const [factoryProvider, setFactoryProvider] = useState();

  useEffect(() => {
    if (signer) {
      const factory_contract = new ethers.Contract(
        factory_address,
        factory_abi,
        signer
      );
      const router_contract = new ethers.Contract(
        router_address,
        router_abi,
        signer
      );
      setFactorySigner(factory_contract);
      setRouterSigner(router_contract);
    }
  }, [signer]);

  useEffect(() => {
    if (provider) {
      const factory_contract = new ethers.Contract(
        factory_address,
        factory_abi,
        provider
      );
      const router_contract = new ethers.Contract(
        router_address,
        router_abi,
        provider
      );
      setFactoryProvider(factory_contract);
      setRouterProvider(router_contract);
    }
  }, [provider]);

  return (
    <>
      <ContractContext.Provider
        value={{
          provider,
          signer,
          routerProvider,
          factoryProvider,
          routerSigner,
          factorySigner,
          router_address,
          factory_address,
        }}
      >
        {props.children}
      </ContractContext.Provider>
    </>
  );
};

export default ContractContextProvideer;
