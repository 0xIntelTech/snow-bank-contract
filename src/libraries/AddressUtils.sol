// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library AddressUtils {
    // Function to check if an address is a contract
    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }
        return codeSize > 0;
    }
}