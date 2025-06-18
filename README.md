# PerpChain: Cross-Chain Perpetual Trading Platform

## Overview

PerpChain is a decentralized, cross-chain perpetual trading platform. It enables users to trade perpetual contracts across multiple blockchains, leveraging interoperability and decentralized finance (DeFi) principles. The platform is designed for high performance, security, and seamless user experience, allowing traders to access liquidity and trading opportunities beyond a single blockchain ecosystem.

## Key Features

- **Cross-Chain Trading:** Trade perpetual contracts across multiple blockchain networks.
- **Decentralized Architecture:** No central authority; all trades and settlements are handled by smart contracts.
- **High Performance:** Optimized for low latency and high throughput.
- **Secure and Transparent:** All transactions are verifiable on-chain.

## Architecture

The platform architecture consists of the following key components:

- **User Interface (UI):** A web-based frontend for traders to interact with the platform, view markets, and manage positions.
- **Smart Contracts:** Core logic for perpetual trading, margin management, liquidation, and settlement, deployed on multiple blockchains.
- **Cross-Chain Communication Layer:** Facilitates secure and efficient message passing and asset transfers between different blockchains.
- **Oracles:** Provide real-time price feeds and other external data required for contract settlement and risk management.
- **Liquidity Providers:** Supply liquidity to the platform, enabling efficient trade execution and minimizing slippage.

### High-Level Flow

1. **User connects wallet** and selects a trading pair.
2. **Order is placed** via the UI, which interacts with the smart contracts on the relevant blockchain.
3. **Cross-chain communication** is triggered if the trade involves assets or contracts on different chains.
4. **Oracles update prices** and provide data for margin and liquidation calculations.
5. **Smart contracts handle settlement** and update user balances accordingly.

## Documentation

- [Complete Build Guide](docs/Complete_Build_Guide.txt)
- [Key Concepts Explanation](docs/Key_Concepts_Explanation.txt)
- [Flow Diagram](docs/flow_diagram.txt)
- [High-Level Architecture](docs/high_level_architec.txt)

---

For more details, see the documentation in the `docs` folder.