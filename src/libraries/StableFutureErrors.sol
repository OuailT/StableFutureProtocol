// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {StableFutureStructs} from "./StableFutureStructs.sol";

library StableFutureErrors {

    enum PriceSource {
            onChain, 
            OffChain
    }
    
    error ZeroAddress(string variableName);

    error ZeroValue(string variableName);

    error Paused(bytes moduleKey);

    error onlyOwner(address msgSender);

    error onlyAuthorizedModule(address msgSender);
    
    error ModuleKeyEmpty();

    error HighSlippage(uint256 amountOut, uint256 accepted);

    error OrderHasExpired();

    error ExecutableAtTimeNotReached(uint256 executableAtTime);

    error AmountToSmall(uint256 depositAmount, uint256 minDeposit);

    error InvalidOracleConfig();
    
}