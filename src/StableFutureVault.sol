// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {StableFutureStructs} from "./libraries/StableFutureStructs.sol";
import {StableFutureErrors} from "./libraries/StableFutureErrors.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
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

    /// @notice collateran deposited by the LP to get StableFuture Token
    IERC20 public collateral;

    /// @notice The minimum time that needs to expire between trade announcement and execution.
    uint64 public minExecutabilityAge;

    /// @notice The maximum amount of time that can expire between trade announcement and execution.
    uint64 public maxExecutabilityAge;

    /// @notice The total amount of RETH deposited in the vault
    uint256 public totalVaultDeposit;

    /// @notice Minimum liquidity to provide as a first depositor
    uint256 public constant MIN_LIQUIDITY = 10_000;

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
    function initialize( 
        address _owner,
        IERC20 _collateral,
        uint64 _minExecutabilityAge,
        uint64 _maxExecutabilityAge 
    ) external initializer {
        if(_owner == address(0)) revert StableFutureErrors.ZeroAddress("Owner");
        if(address(_collateral) == address(0)) revert StableFutureErrors.ZeroAddress("Collateral");
        
        __Ownable_init(msg.sender);
        _transferOwnership(_owner);
        __ERC20_init("Stable Future", "SFR");

        collateral = _collateral;

        setExecutabilityAge(_minExecutabilityAge, _maxExecutabilityAge);

    } // Contract runtime deployment(bytes code executed on EVM)


    // Exercise:1
    // function that to execute annnounced deposit by minting tokens and poin to the users.
    // Params: account, StructsAnnouncDeposit to get the data
    // returns liquidity minted
    // TODO emit event || LATER MINT POINT
    function _executeDeposit(address account,
                             StableFutureStructs.AnnouncedLiquidityDeposit calldata liquidityDeposit)
                    external returns (uint256 liquidityMinted) {
        
        // cach variables 
        uint256 depositAmount = liquidityDeposit.depositAmount;
        uint256 minAmountOut = liquidityDeposit.minAmountOut;

        liquidityMinted = depositQuote(depositAmount);

        if(liquidityMinted < minAmountOut) {
            revert StableFutureErrors.HighSlippage({amountOut: amountOut, accepted: minAmountOut});
        }

        _mint(account, liquidityMinted);


        // update total deposit in the pool
        updateTotalVaulDeposit(depositAmount);

        // Check if the liquidity provided respect the min liquidity to provide to avoid inflation
        // attacks and position with small amount of tokens 

        if(totalSupply() < MIN_LIQUIDITY) {
            revert StableFutureErrors.AmountToSmall({amount: totalSupply(), minAmount: MIN_LIQUIDITY});
        } 

    }
    


    /////////////////////////////////////////////
    //            View Functions             //
    /////////////////////////////////////////////


    /// @notice Function to calculate the total collateral per share based on the current totalSupply, totalVaultDeposit
    function totalDepositPerShare() internal view returns(uint256 _collateralPerShare) {
        uint256 totalSupply = totalSupply();

        if(totalSupply > 0) {
            _collateralPerShare = totalVaultDeposit * (10 ** decimals()) / totalSupply;
        } else {
             _collateralPerShare = 1e18;
        }
    }

    
    /// @notice Quoter function to calculate the the amount out of SFR tokens for a _deposit amount
    function depositQuote(uint256 _depositAmount) external view returns(uint256 _amountOut) {
            _amountOut = _depositAmount * (10 ** decimals()) / totalDepositPerShare();
    }

    
    // NOTE: Allow only this contract/Module to called this function or other contract can called it
    // If it's only called by this contract I'll set it up to private
    // THIS function must be added to the execute announcedDeposit to update the totalVaultDeposit
    /// @notice Function to update totalVaultDeposit each time the announce deposit is executed by the keeper
    function updateTotalVaulDeposit(uint256 _newDeposit) external {
        
        // totalVaultDeposit
        uint256 newTotalVaultDeposit = totalVaultDeposit + _newDeposit;
        
        totalVaultDeposit = (newTotalVaultDeposit > 0) ? newTotalVaultDeposit : 0;
    }


    

    /////////////////////////////////////////////
    //            Setter Functions             //
    /////////////////////////////////////////////
    function setExecutabilityAge(uint64 _minExecutabilityAge, uint64 _maxExecutabilityAge) public onlyOwner  {
        if(_minExecutabilityAge == 0) revert StableFutureErrors.ZeroValue("minExecutabilityAge");
        if(_maxExecutabilityAge == 0) revert StableFutureErrors.ZeroValue("maxExecutabilityAge");
        minExecutabilityAge = _minExecutabilityAge;
        maxExecutabilityAge = _maxExecutabilityAge;
    }






}