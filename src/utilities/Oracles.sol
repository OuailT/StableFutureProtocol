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

    uint256 public maxPriceDiffPercent;

    /// @dev To prevent the implementation contract from being used, we invoke the _disableInitializers
    /// function in the constructor to automatically lock it when it is deployed.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    
    /**
        * @dev Initializes the OracleModule.
        * @param _asset The asset contract.
        * @param _vault The vault contract.
        * @param _newchainLinkOracle The new ChainLinkOracle struct.
        * @param _newPythNetworkOracle The new PythNetworkOracle struct.
        * @param _maxPriceDiffPercent The maximum price difference percentage.
    */
    function initialize(
        address _asset,
        IStableFutureVault _vault,
        StableFutureStructs.ChainLinkOracle calldata _newchainLinkOracle,
        StableFutureStructs.PythNetworkOracle calldata _newPythNetworkOracle,
        uint256 _maxPriceDiffPercent
    ) external initializer {

        __init_Module(StableModuleKeys.ORACLE_MODULE_KEY, _vault);
        __ReentrancyGuard_init();

        _setChainlinkOracle(_newchainLinkOracle);
        _setPythNetworkOracle(_newPythNetworkOracle);
        _setMaxPriceDiffPercent(_maxPriceDiffPercent);
        _setAsset(_asset);
    } 



    /**
        * @dev Sets the ChainLinkOracle configuration.
        * @param newOracle The new ChainLinkOracle struct to be set.
    */
    function _setChainlinkOracle(StableFutureStructs.ChainLinkOracle calldata newOracle) internal {
        
        // Sanity checks
        if(address(newOracle.chainLinkContract) == address(0) || 
            newOracle.maxAge <= 0 ) revert StableFutureErrors.InvalidOracleConfig(); 

        // set chainLink oracle config to struct
        chainLinkOracle = StableFutureStructs.ChainLinkOracle(
            newOracle.chainLinkContract,
            newOracle.maxAge
        );

        // Emit the event
        emit StableFutureEvents.NewChainlinkOracleSet(newOracle);
    }



    /**
        * @dev Sets the PythNetworkOracle configuration.
        * @param newOracle The new PythNetworkOracle struct to be set.
    */
    function _setPythNetworkOracle(StableFutureStructs.PythNetworkOracle calldata newOracle) internal {
        
        // Check the validity of these configs
        if(address(newOracle.pythNetworkContract) == address(0) ||
           newOracle.priceId == bytes32(0) ||
           newOracle.maxAge <= 0 ||
           newOracle.minConfidenceRatio <= 0) revert StableFutureErrors.InvalidOracleConfig(); 


        // Set new Pyth network config to struct
        pythNetworkOracle = StableFutureStructs.PythNetworkOracle (
            newOracle.pythNetworkContract,
            newOracle.priceId,
            newOracle.maxAge,
            newOracle.minConfidenceRatio
        );

        emit StableFutureEvents.NewPythNetworkOracleSet(newOracle); 
    }



    /**
        * @dev Sets the asset address.
        * @param _asset The new asset address to be set.
    */
    function _setAsset(address _asset) internal {
    
        if(_asset == address(0)) revert StableFutureErrors.ZeroAddress("newAsset");

        asset = _asset;

        emit StableFutureEvents.AssetSet(_asset);
    }



    /** * @dev the priceDiff between chainlink and Pyth must be bewteen 0(no difference is tolerated) and
               maxPriceDiffPerecent(any difference is acceptable) 1e18 = 100%
        * @dev Sets the maximum price difference percentage.
        * @param _maxPriceDiffPercent The new maximum price difference percentage to be set.
    */
    function _setMaxPriceDiffPercent(uint256 _maxPriceDiffPercent) internal {
        
        if(_maxPriceDiffPercent == 0 || _maxPriceDiffPercent > 1e18) {
            revert StableFutureErrors.InvalidOracleConfig();
        } 
         
        maxPriceDiffPercent = _maxPriceDiffPercent;

        emit StableFutureEvents.MaxPriceDiffPerecentSet(_maxPriceDiffPercent);
    }


}