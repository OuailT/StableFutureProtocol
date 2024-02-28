// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStableFutureVault} from "./interfaces/IStableFutureVault.sol";
import {StableModuleKeys} from "./libraries/StableModuleKeys.sol";
import {ModuleUpgradeable} from "./abstracts/ModuleUpgradeable.sol";
import {StableFutureStructs} from "./libraries/StableFutureStructs.sol";
import {StableFutureEvents} from "./libraries/StableFutureEvents.sol";


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


/**
    1-Import
    2- Create state variable and libraries
    [] Setting state variable: 
     1- announcedOrders mapping to keep track of announced order;
     2- Define a mintDeposit to announced an Order;
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


    /// @notice Function to initialize this contract.
    // Initilize the the contract with reentrancyGuard and initModule
    // the vault as param
    /// @dev initializer to make sure the initilize function acts as constructor(only get called/initilized once); 
    function initialize(IStableFutureVault _vault) external initializer {
        __init_Module(StableModuleKeys.ORDERS, _vault);
        __ReentrancyGuard_init(); 
    }

    
    /**
        TODO:
        Function Def: function that will allow user to annonce a deposit by providing liquidity rETH(rocket pool)
        This announced deposit will be executed by a keeper later.
        Params: depositAmount, minAmount, keeperFees
        Modifier: add pausable functionnalities (x)
        - record the announceDeposit order in the _announceOrdermapping [x]
        - 
        - Emit the the event
        - Create a function that will allow 
    */
    // mapping(address => StableFutureStructs.Order order) public _announcedOrder;
    function announceDeposit(
            uint256 depositAmount,
            uint256 minAmountOut, 
            uint256 keeperFee) public {
        
        // record the announceDeposit order in the _announceOrdermapping [x]
        _announcedOrder[msg.sender] = StableFutureStructs.Order({
            orderType: StableFutureStructs.OrderType.StableDeposit,
            orderData: abi.encode(
                StableFutureStructs.AnnouncedLiquidityDeposit({
                depositAmount: depositAmount, minAmountOut: minAmountOut})
            ),
            keeperFee: keeperFee
            // executableAtTime: to implement later
        });

        // Transfer rETh from msg.sender to this address(this) which will transfer it later to the vault when the annonced order is executed(x)
        // vault.collateral().safeTransferFrom(msg.sender, address(this), depositAmount + keeperFee);

        // Emit Event
        emit StableFutureEvents.OrderAnnounced({
            account: msg.sender,
            orderType: StableFutureStructs.OrderType.StableDeposit,
            keeperFee: keeperFee
        });
        
    }


    //  struct AnnouncedLiquidityDeposit {
    //     // Amount of liquidity deposited
    //     uint256 depositAmount;
    //     // The minimum amount of tokens expected to receive back after providing liquidity
    //     uint256 minAmountOut;
    // }

    // enum OrderType {
    //     None, // 1
    //     StableDeposit, // 2 
    //     StableWithdraw // 3f
    // }

    // struct Order {
    //     OrderType orderType;
    //     bytes orderData;
    //     uint256 keeperFee; // The deposit paid upon submitting that needs to be paid / refunded on tx confirmation
    //     uint64 executableAtTime; // The timestamp at which this order is executable at
    // }








    


}
