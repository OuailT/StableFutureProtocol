// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStableFutureVault} from "./interfaces/IStableFutureVault.sol";
import {StableModuleKeys} from "./libraries/StableModuleKeys.sol";
import {ModuleUpgradeable} from "./abstracts/ModuleUpgradeable.sol";
import {StableFutureStructs} from "./libraries/StableFutureStructs.sol";
import {StableFutureEvents} from "./libraries/StableFutureEvents.sol";
import {StableFutureErrors} from "./libraries/StableFutureErrors.sol";


/**
    NOTE:
    - The code inside a constructor or part of a global variable declaration is not part of a deployed contract's runtime bytecode
    This code is only executed once. Because is only executed once, the code withing the logic contract(implementation)
    will never be executed in the context of the proxy's state.
    Because of the proxy designed, proxies are not aware at all of the state changes made by the constructor.
    To solve this logic(implementation contract) and in order for the proxy to be aware of the state changes in the implementation
    contract. we shouldn't use constructor but mode all the code within the constructor to the regular function Initilize.
    - The constructor runs only once to initilize the contract's state(__ReentrancyGuard_init, owner, etc), After deployment
    the initilization code is not needed as it's doesn't have to be part of the bytescode in the contracts deployement.

*/



contract Orders is ReentrancyGuardUpgradeable, ModuleUpgradeable {

    uint256 public constant MIN_DEPOSIT = 1e16;

    /// @dev mapping to store all the announced Orders in encoded format
    mapping(address => StableFutureStructs.Order order) public _announcedOrder;

    using SafeERC20 for IERC20;


    /// @dev To prevent the implementation contract from being used, we invoke the _disableInitializers
    /// function in the constructor to automatically lock it when it is deployed.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /**
    * @dev Initializes the orders module with a reference to the vault
    * @param _vault The StableFutureVault contract address this module will interact with.
    */
    function initialize(IStableFutureVault _vault) external initializer {
        __init_Module(StableModuleKeys.ORDERS_MODULE_KEY, _vault);
        __ReentrancyGuard_init();
    }



    /**
    * @dev Announces a deposit order, allowing keepers to execute it after a specified time.
    * @param depositAmount The amount to be deposited.
    * @param minAmountOut The minimum amount of tokens expected from the deposit.
    * @param keeperFee The fee paid to the keeper for executing the deposit.
    */
    function announceDeposit(
            uint256 depositAmount,
            uint256 minAmountOut, 
            uint256 keeperFee) public {
        
        // Calculate the time when the order becomes executable by the keeper
        uint64 executableAtTime = _orderExecutionTime();

        // Check for minimum deposit
        if(depositAmount < MIN_DEPOSIT) {
            revert StableFutureErrors.AmountToSmall({depositAmount: depositAmount, minDeposit: MIN_DEPOSIT});
        }
        
        // Check if deposit amount is below a minimum threshold
        uint256 amountOut = vault.depositQuote(depositAmount);

        /// Check for slippage
        if(amountOut < minAmountOut) revert StableFutureErrors.HighSlippage({amountOut: amountOut, accepted: minAmountOut});
        

        // record the announceDeposit order in the _announceOrdermapping [x]
        _announcedOrder[msg.sender] = StableFutureStructs.Order({
            orderType: StableFutureStructs.OrderType.Deposit,
            orderData: abi.encode(
                StableFutureStructs.AnnouncedLiquidityDeposit({
                depositAmount: depositAmount, minAmountOut: minAmountOut})
            ),
            keeperFee: keeperFee,
            executableAtTime: executableAtTime
        });
        
        // Transfer rETh from msg.sender to this address(this) which will transfer it later to the vault when the annonced order is executed(x)
        vault.collateral().safeTransferFrom(msg.sender, address(this), depositAmount + keeperFee);

        // Emit Event
        emit StableFutureEvents.OrderAnnounced({
            account: msg.sender,
            orderType: StableFutureStructs.OrderType.Deposit,
            keeperFee: keeperFee
        });
        
    }



    /**
    * @dev Executes a previously announced deposit order for the specified account.
    * @param account The account for which the deposit order will be executed.
    * @return liquidityMinted The amount of liquidity minted as a result of the deposit.
    */
    function executeAnnounceDeposit(address account) external returns(uint256 liquidityMinted) {

            // Get the users order
            StableFutureStructs.Order memory order = _announcedOrder[account];

            // Decode the data inside order.orderData
            StableFutureStructs.AnnouncedLiquidityDeposit memory liquidityDeposit = abi.decode(
                order.orderData,
                (StableFutureStructs.AnnouncedLiquidityDeposit)
            );
            

            _orderTimeValidity(account, order.executableAtTime);

        liquidityMinted = IStableFutureVault(vault)._executeDeposit(account, liquidityDeposit);

        // Transfer fees to the keeper
        vault.collateral().safeTransfer({to: msg.sender, value: order.keeperFee});

        // Transfer depositAmount to the vault
        vault.collateral().safeTransfer({to: address(vault), value: liquidityDeposit.depositAmount});

        emit StableFutureEvents.DepositExecuted({account: account,
                                                orderType: order.orderType,
                                                keeperFee: order.keeperFee});
    }


    
    /**
    * @dev Checks the validity of an order's execution time and deletes the order if valid.
    * @param account The account associated with the order.
    * @param _executableAtTime The timestamp when the order becomes executable.
    */
    function _orderTimeValidity(address account, uint256 _executableAtTime) internal {
        
        // Check if the order didn't expired
        if(block.timestamp > _executableAtTime + vault.maxExecutabilityAge()) {
            revert StableFutureErrors.OrderHasExpired();
        }

        // Check if the order reached the executableAtTime
        if(block.timestamp < _executableAtTime) {
            revert StableFutureErrors.ExecutableAtTimeNotReached(_executableAtTime);
        }

        // delete the announce deposit if both condition doesn't revert
        delete _announcedOrder[account];
        
    }



    /////////////////////////////////////////////
    //            View Functions             //
    /////////////////////////////////////////////
    
    /**
    * @dev Calculates the future timestamp when an order becomes executable.
    * @return executeAtTime The timestamp at which a new order will become executable, based on the vault's minimum executability age.
    */
    function _orderExecutionTime() private view returns(uint64 executeAtTime) {
        // Todo: Cancel pending orders
        // Check for Minmum amount of keeperFee
        // settle fundingFees
        return executeAtTime = uint64(block.timestamp + vault.minExecutabilityAge());
    }


}
