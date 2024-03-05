// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;


import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {StableFutureStructs} from "../libraries/StableFutureStructs.sol";
import {StableFutureErrors} from "../libraries/StableFutureErrors.sol";
import {StableFutureEvents} from "../libraries/StableFutureEvents.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {ModuleUpgradeable} from "../abstracts/ModuleUpgradeable.sol";



contract Oracles is ReentrancyGuardUpgradeable, ModuleUpgradeable {

    address public asset; // Asset to price

    using SafeERC20 for IERC20;

    // Structs that represent both PythNetowrkOracle, ChainlinkOracle.
    StableFutureStructs.ChainLinkOracle public chainLinkOracle;
    StableFutureStructs.PythNetworkOracle public pythNetworkOracle;


    /// @dev To prevent the implementation contract from being used, we invoke the _disableInitializers
    /// function in the constructor to automatically lock it when it is deployed.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    function initialize(
        address _asset,
        
    
    ) external initializer {

    } 


}