// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

library StableModuleKeys {
    // Each key module is attached to an contract address of each key model. stableModule.sol
    bytes32 internal constant ORDERS_MODULE_KEY = bytes32("orders");
    bytes32 internal constant ORACLE_MODULE_KEY = bytes32("oracles");
    
}