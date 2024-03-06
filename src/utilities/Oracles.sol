// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;


import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {StableFutureStructs} from "../libraries/StableFutureStructs.sol";
import {StableFutureErrors} from "../libraries/StableFutureErrors.sol";
import {StableFutureEvents} from "../libraries/StableFutureEvents.sol";
import {StableModuleKeys} from "../libraries/StableModuleKeys.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {ModuleUpgradeable} from "../abstracts/ModuleUpgradeable.sol";
import {IStableFutureVault} from "../interfaces/IStableFutureVault.sol";



contract Oracles is ReentrancyGuardUpgradeable, ModuleUpgradeable {

    address public asset; // Asset to price

    using SafeERC20 for IERC20;

    // Structs that represent both PythNetowrkOracle, ChainlinkOracle.
    StableFutureStructs.ChainLinkOracle public chainLinkOracle; // struct reference(assigning the struct to a variable)
    StableFutureStructs.PythNetworkOracle public pythNetworkOracle; // struct reference


    /// @dev To prevent the implementation contract from being used, we invoke the _disableInitializers
    /// function in the constructor to automatically lock it when it is deployed.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
        Exercices: 
        - Create an Initiliaze function : Initial the module with a vault address and module key 
        - setChainlink Oracle config function, pythNetworkOralce config function
        - 
    */

    function initialize(
        address _asset,
        IStableFutureVault _vault,
        StableFutureStructs.ChainLinkOracle calldata _newchainLinkOracle,
        StableFutureStructs.PythNetworkOracle calldata _newPythNetworkOracle
    ) external initializer {

        __init_Module(StableModuleKeys.ORACLE_MODULE_KEY, _vault);
        __ReentrancyGuard_init();

        _setChainlinkOracle(_newchainLinkOracle);
        _setPythNetworkOracle(_newPythNetworkOracle);
        _setAsset(_asset);
        
    } 



    // Create a function to set chainlink oracle config
    function _setChainlinkOracle(StableFutureStructs.ChainLinkOracle calldata newOracle) internal {
        
        // Do some sanity checks
        if(address(newOracle.chainLinkContract) == address(0) || 
            newOracle.maxAge <= 0 ) revert StableFutureErrors.InvalidOracleConfig(); 

        // set chainLink oracle config to the struct
        chainLinkOracle = StableFutureStructs.ChainLinkOracle({
            newOracle.chainLinkContract,
            newOracle.maxAge
        });

        // Emit the event
        emit StableFutureEvents.NewChainlinkOracleSet(newOracle);
    }



    // Create function to set the pyth netwrok oracle config
    function _setPythNetworkOracle(StableFutureStructs.PythNetworkOracle calldata newOracle) internal {
        
        // Check the validity of these configs
        if(address(newOracle.pythNetworkContract) == address(0) ||
           newOracle.priceId == bytes32(0) ||
           newOracle.maxAge <= 0 ||
           newOracle.minConfidenceRatio <= 0) revert StableFutureErrors.InvalidOracleConfig(); 


        // Set new Pyth network config to struct
        pythNetworkOracle = StableFutureStructs.PythNetworkOracle ({
            newOracle.pythNetworkContract,
            newOracle.priceId,
            newOracle.maxAge,
            newOracle.minConfidenceRatio
        });

        emit StableFutureEvents.NewPythNetworkOracleSet(newOracle); // check it later and why and how we choose the right params
    }

    

    // Function to set a new asset
    function _setAsset(address _asset) internal {
        if(_asset == address(0)) revert StableFutureErrors.ZeroAddress("newAsset");

        asset = _asset;

        emit StableFutureEvents.AssetSet(asset);
    }




    // struct PythNetworkOracle {
    //     // Pyth network oracle contract
    //     IPyth pythNetworkContract;

    //     // Pyth network priceID
    //     bytes32 priceId;

    //     // the oldest price acceptable to use
    //     uint32 maxAge;

    //     // Minimum confid ratio aka expo ratio, The higher, the more confident the accuracy of the price.
    //     uint32 minConfRatio;
    // }
}