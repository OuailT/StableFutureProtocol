// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {StableFutureStructs} from "./libraries/StableFutureStructs.sol";
import {StableFutureErrors} from "./libraries/StableFutureErrors.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {SafeCast} from "openzeppelin-contracts/contracts/utils/math/SafeCastUpgradeable.sol";
import {ERC20LockableUpgradeable} from "./utilities/ERC20LockableUpgradeable.sol";


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

contract StableFutureVault is OwnableUpgradeable, ERC20LockableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeCast for *;

    /// @notice collateran deposited by the LP to get StableFuture Token
    IERC20 public collateral;

    /// @notice The minimum time that needs to expire between trade announcement and execution.
    uint64 public minExecutabilityAge;

    /// @notice The maximum amount of time that can expire between trade announcement and execution.
    uint64 public maxExecutabilityAge;

    /// @notice The total amount of RETH deposited in the vault
    uint64 public totalVaultDeposit;

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
        IERC20 _collateral,
        _minExecutabilityAge,
        _maxExecutabilityAge 
    ) public initializer {
        if(_owner == address(0)) revert StableFutureErrors.ZeroAddress("Owner");
        if(_collateral == address(0)) revert StableFutureErrors.ZeroAddress("Collateral");
        
        __Ownale_init();
        __ERC20_init("Stable Future", "SFR");
        _transferOwnership(_owner);

        collateral = _collateral;

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
    - Set collateral Address [x]
    - Initilize ERC20 tokens [x]
    - Create a function that will calculate the depositPerShare based on the totaldeposit In the vault  the vault and totalSupply[x]
    - Create a function depositQuote to return the amount of SFR tokens retuned for a deposit amount [x]
    - Create function to update totalVaultDeposit each time the announce deposit is executed by the keeper. [x]
    - TODO NEXT: Finished components that announce Deposit function needs to be executed safely.
    */


    /////////////////////////////////////////////
    //            View Functions             //
    /////////////////////////////////////////////


    /// @notice Function to calculate the total collateral per share based on the current totalSupply, totalVaultDeposit
    function totalDepositPerShare() external view returns(_collateralPerShare) {
        uint256 totalSupply = totalSupply();

        if(totalSupply > 0) {
            _collateralPerShare = totalVaultDeposit * (10 ** decimals()) / totalSupply;
        } else {
             _collateralPerShare = 1e18;
        }
    }

    
    /// @notice Quoter function to calculate the the amount out of SFR tokens for a _deposit amount
    function depositQuote(uint256 _depositAmount) external view returns(_amountOut) {
        return _depositAmount * (10 ** decimals()) / totalDepositPerShare();
    }


    
    // Allow only this contract/Module to called this function or other contract can called it
    // If it's only called by this contract I'll set it up to private

    /// @notice Function to update totalVaultDeposit each time the announce deposit is executed by the keeper
    function updateTotalVaulDeposit(uint256 _newDeposit) external  {
        
        // totalVaultDeposit
        uint256 newTotalVaultDeposit = totalVaultDeposit + _newDeposit;
        
        totalVaultDeposit = (newTotalVaultDeposit > 0) ? newTotalVaultDeposit : 0;
    }






    /////////////////////////////////////////////
    //            Setter Functions             //
    /////////////////////////////////////////////
    function setExecutabilityAge(uint64 _minExecutabilityAge, uint64 _maxExecutabilityAge) external onlyOwner  {
        if(_minExecutabilityAge == 0) revert StableFutureErrors.ZeroValue("minExecutabilityAge");
        if(_maxExecutabilityAge == 0) revert StableFutureErrors.ZeroValue("maxExecutabilityAge");
        minExecutabilityAge = _minExecutabilityAge;
        maxExecutabilityAge = _maxExecutabilityAge;
    }






}