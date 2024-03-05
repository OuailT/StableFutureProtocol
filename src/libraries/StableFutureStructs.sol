// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;


library StableFutureStructs {

    enum OrderType {
        None, // 1
        Deposit, // 2 
        Withdraw // 3f
    }

    struct Order {
        OrderType orderType;
        bytes orderData;
        uint256 keeperFee; // The deposit paid upon submitting that needs to be paid / refunded on tx confirmation
        uint64 executableAtTime; // The timestamp at which this order is executable at
    }

    struct AnnouncedLiquidityDeposit {
        // Amount of liquidity deposited
        uint256 depositAmount;
        // The minimum amount of tokens expected to receive back after providing liquidity
        uint256 minAmountOut;
    }

}

