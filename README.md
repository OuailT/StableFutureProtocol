# StableFuture Protocol

## About the Project

StableFuture is a DeFi protocol that enables users to provide liquidity, borrow assets, and trade leveraged positions. Key features include:

- Liquidity providers can deposit rETH(Rocket Pool ETH) and receive SFR tokens
- Traders can open leveraged long positions on rETH
- NFT representation of trading positions
- Points system for borrowers based on position size
- Dual oracle system using Pyth network and Chainlink for accurate rETH pricing
- Liquidity providers earn yields on staked rETH and collect protocol fees

The protocol offers a way for users to earn passive income and for traders to leverage their positions and earn Yield in the Perpetual Futures Market.

## External Integrations

### [Rocket Pool Protocol](https://rocketpool.net/)
StableFuture integrates with Rocket Pool, utilizing rETH tokens as the main asset for liquidity provision and trading.
### [Pyth Network](https://pyth.network/)
### [Chainlink Oracles](https://chain.link/)

## Actors

* **Liquidity Providers**: Users who deposit rETH into the protocol and receive SFR tokens in return. They earn yields on their staked rETH and collect fees from the protocol's operations.
* **Leverage Traders**: Users who open leveraged long positions on rETH, using their deposited rETH as collateral and borrowing additional rETH from the protocol.
* **Keepers**: External actors who can run liquidation processes to ensure the timely closure of underwater positions, protecting the protocol and liquidity providers.

## Protocol Flow to Open Long Position as Leverage Trader

1. **Deposit rETH as Collateral**: Trader deposits rETH from their wallet as security for the leverage trade.
2. **Borrowing rETH for Leverage**: Trader chooses a leverage ratio (e.g., 2x, 5x) to borrow additional rETH.
3. **Opening the Long Position**: Total position (original rETH plus borrowed rETH) is used to open a long position.
4. **Receive an NFT**: Trader receives an NFT representing their trade.
5. **Gain Points**: Trader earns points based on the borrowed amount ("additionalSize") when opening the leverage position.
6. **Adjust Position**: Trader can modify the trade, updating the NFT representing their position.
7. **Close Position**: Trader can close the trade and withdraw collateral (paying fees).
8. **Liquidation**: If the trade hits the liquidation price, the position is automatically closed, and the trader loses their collateral.


## Foundry Test

To set up and run tests for StableFuture:

1. Follow the [instructions](https://book.getfoundry.sh/getting-started/installation.html) to install [Foundry](https://github.com/foundry-rs/foundry).
2. Clone and install dependencies: git submodule update --init --recursive

Note: I'm actively working on building comprehensive test coverage for all aspects of the StableFuture protocol. Updates will be provided as development progresses.
