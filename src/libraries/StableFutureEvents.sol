// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {StableFutureStructs} from "./StableFutureStructs.sol";

library StableFutureEvents {

    // Emit when a user provide liquidity by announcing an orders first.
    event OrderAnnounced(address account, StableFutureStructs.OrderType orderType, uint256 keeperFee);

}