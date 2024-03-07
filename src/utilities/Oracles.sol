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
import {IChainlinkAggregatorV3} from "../interfaces/IChainlinkAggregatorV3.sol";
import {IPyth} from "pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "pyth-sdk-solidity/PythStructs.sol";
import {safeCast} from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";


contract Oracles is ReentrancyGuardUpgradeable, ModuleUpgradeable {

    address public asset; // Asset to price

    using SafeERC20 for IERC20;
    using  for *;

    // Structs that represent both PythNetowrkOracle, chainlinkOracle.
    StableFutureStructs.ChainlinkOracle public chainlinkOracle; // struct reference(assigning the struct to a variable)
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
        * @param _newchainlinkOracle The new chainlinkOracle struct.
        * @param _newPythNetworkOracle The new PythNetworkOracle struct.
        * @param _maxPriceDiffPercent The maximum price difference percentage.
    */
    function initialize(
        address _asset,
        IStableFutureVault _vault,
        StableFutureStructs.ChainlinkOracle calldata _newchainlinkOracle,
        StableFutureStructs.PythNetworkOracle calldata _newPythNetworkOracle,
        uint256 _maxPriceDiffPercent
    ) external initializer {

        __init_Module(StableModuleKeys.ORACLE_MODULE_KEY, _vault);
        __ReentrancyGuard_init();

        _setchainlinkOracle(_newchainlinkOracle);
        _setPythNetworkOracle(_newPythNetworkOracle);
        _setMaxPriceDiffPercent(_maxPriceDiffPercent);
        _setAsset(_asset);
    } 




    // Exerices: Create a function to get the price of chainlink price: DONE
    // Param: none
    // returns price, timestamp
    // Verification 
    function _getChainlinkPrice() external view returns(uint256 timestamp, uint256 price) {

        // Get the contract address of chainlink contract associtated with the pair
        IChainlinkAggregatorV3 oracle = chainlinkOracle.chainlinkOracle;
        
        if(address(oracle) == address(0)) {
            revert StableFutureErrors.ZeroAddress("oracle");
        }

        // get the price using latestRoundData
        (, int256 answer,,uint256 updatedAt,)= oracle.latestRoundData();

        
        // Check if the price is stale or within a certain freshness window
        if(block.timestamp - updatedAt > chainlinkOracle.maxAge) {
            revert StableFutureErrors.PriceStale(StableFutureErrors.PriceSource.chainlinkOracle); // add which price is stale
        }

        if(answer > 0) {
            price = uint256(answer) * (10**10); // convert the return value from 8 to 18 decimals
            timestamp = updatedAt;
        } else {
            revert StableFutureErrors.InvalidPrice(StableFutureErrors.PriceSource.chainlinkOracle);
        }

    }

        
    // Exerices function to get the price of the address of an assest on Pyth network
    // func definition: above
    // Params: none
    // returns value: timestamp, invalid, price

    function _getPythNetworkPrice() external view returns(uint256 price, bool invalid, uint256 timestamp) {
        
        // get the Pyth oracle address contract
        IPyth oracle = pythNetworkOracle.pythNetworkContract;

        // get the price
        try oracle.getPriceNoOlderThan(pythNetworkOracle.priceId, pythNetworkOracle.maxAge) returns (
            PythStructs.Price memory oracleData
        ) {

            // Check if the price is not invalid based on the passed params to getPriceNoOlderThan
            if(oracleData.price > 0 && oracleData.conf > 0 && oracleData.expo < 0 ) {
                
                // scale the price to 19 decimals
                price = ((oracleData.price).toUint256()) * (10 ** (18 + oracleData.expo).toUint256());
            
            } else {
                invalid = true
            }

            // check if the price is accurate(respecte the minimum price confidence)
            // Devide the returns price but the returned confidence
            if(oracleData.price / oracleData.conf <  pythNetworkOracle.minConfidenceRatio) {
                revert StableFutureErrors.PriceStale(StableFutureErrors.PriceStale.Pythoracle);
            }

        } catch {
            invalid = true;
        }

    }








    /////////////////////////////////////////////
    //            Setter Functions             //
    /////////////////////////////////////////////


    /**
        * @dev Sets the chainlinkOracle configuration.
        * @param newOracle The new chainlinkOracle struct to be set.
    */
    function _setchainlinkOracle(StableFutureStructs.ChainlinkOracle calldata newOracle) internal {
        
        // Sanity checks
        if(address(newOracle.chainlinkOracle) == address(0) || 
            newOracle.maxAge <= 0 ) revert StableFutureErrors.InvalidOracleConfig(); 

        // set chainLink oracle config to struct
        chainlinkOracle = StableFutureStructs.ChainlinkOracle(
            newOracle.chainlinkOracle,
            newOracle.maxAge
        );

        // Emit the event
        emit StableFutureEvents.NewchainlinkOracleSet(newOracle);
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