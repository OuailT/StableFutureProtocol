// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {StableFutureStructs} from "./libraries/StableFutureStructs.sol";
import {StableFutureErrors} from "./libraries/StableFutureErrors.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {SafeCast} from "openzeppelin-contracts/contracts/utils/math/SafeCastUpgradeable.sol";


/**
    TODO: 
    Defining the important States variables of the contract:
    - Collateral, [x]
    - MaxAmountOfDeposit, [x]
    - 

 */

/// @title StableFutureVault 
/// @notice Contains state to be reused by different modules/contracts of the system.
/// @dev Holds the rETH deposited by liquidity providers

contract StableFutureVault is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeCast for *;

    /// @notice collateran deposited by the LP to get StableFuture Token
    IERC20 public collateral;

    /// @notice The minimum time that needs to expire between trade announcement and execution.
    uint64 public minExecutabilityAge;

    /// @notice The maximum amount of time that can expire between trade announcement and execution.
    uint64 public maxExecutabilityAge;

    /// @dev To prevent the implementation contract from being used, we invoke the _disableInitializers
    /// function in the constructor to automatically lock it when it is deployed.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    } // on deployment time(it's not save on EVM)


    
    /**
        Set functions params:
        Owner, 
        maxExecutabilityAge,
        minExecutabilityAge
    
    */
    function Initilize( 
        address _owner,
        _minExecutabilityAge,
        _maxExecutabilityAge ) public initializer {
        __Ownale_init();
        _transferOwnership(_owner);
        setExecutabilityAge(_minExecutabilityAge, _maxExecutabilityAge);
 
    } // Contract runtime deployment(bytes code executed on EVM)


    
    /**
    TODO: 
    Defining the important States variables of the contract:
    - Collateral, [x]
    - MaxAmountOfDeposit, [x]
    - Owner state variable [x]
    function initilize the contract [x]
    - Set functions params [x]
    - Create setters function to set min and max execubility ages; [x]
    - Create a modifier to limit access to sentive functions. [x]
    - Init ownership, transferownership to an owner address [x]
 */

    /////////////////////////////////////////////
    //            Setter Functions             //
    /////////////////////////////////////////////
    // limit access control
    function setExecutabilityAge(uint64 _minExecutabilityAge, uint64 _maxExecutabilityAge) external onlyOwner  {
        if(_minExecutabilityAge == 0) revert StableFutureErrors.ZeroValue("minExecutabilityAge");
        if(_maxExecutabilityAge == 0) revert StableFutureErrors.ZeroValue("maxExecutabilityAge");
        minExecutabilityAge = _minExecutabilityAge;
        maxExecutabilityAge = _maxExecutabilityAge;
    }



}