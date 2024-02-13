// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20Upgradeable.sol";
import {IStableFutureVault} from "./interfaces/StableFutureVault.sol";
import {StableModuleKeys} from "./libraries/StableModuleKeys.sol"
import {ModuleUpgradeable} from "./abstract/ModuleUpgradeable.sol";
import {StableFutureStructs} from "./libraries/StableFutureStructs.sol";



/**
    1-Import
    2- Create state variable and libraries
    [] Setting state variable: 
     1- announcedOrders mapping to keep track of announced order;
     2- Define a mintDeposit to announced an Order;
 */


contract Orders is ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MIN_DEPOSIT = 1e16;

    /// @dev mapping to store all the announced Orders in encoded format
    mapping(address => StableFutureStructs.Order order) public _announcedOrder;


    /// @dev To prevent the implementation contract from being used, we invoke the _disableInitializers
    /// function in the constructor to automatically lock it when it is deployed.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /// @notice Function to initialize this contract.
    // Initilize the the contract with reentrancyGuard and initModule
    // the vault as param
    /// @dev initializer to make sure the initilize function acts as constructor(only get called/initilized once); 
    function initialize(IStableFutureVault _vault) public initializer {
        __init_Module(StableModuleKeys.ORDERS, _vault);
        __ReentrancyGuard_init();
    }







}
