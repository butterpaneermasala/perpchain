# CrossChainVault.sol

## Overview
The CrossChainVault contract is a core component of the PerpChain platform, responsible for managing user assets and collateral across multiple blockchains. It leverages Chainlink CCIP for secure cross-chain messaging and asset transfers, enabling seamless DeFi trading experiences and solving liquidity fragmentation.

## Use Case
CrossChainVault allows users to deposit collateral on one chain and use it for trading perpetual contracts on another, without manual bridging. This enables unified liquidity and a frictionless user experience.

## Key Responsibilities
- Accept and track user deposits for supported assets (e.g., USDC, ETH)
- Lock assets on the source chain and release them on the destination chain via CCIP
- Handle cross-chain asset synchronization and messaging
- Provide secure withdrawal and emergency pause mechanisms
- Integrate with trading and liquidation logic for settlement

## Main Functions
- `depositCollateral(asset, amount)`: Deposit supported collateral into the vault
- `withdrawCollateral(asset, amount)`: Withdraw collateral from the vault
- `_ccipReceive(message)`: Process incoming cross-chain messages
- `lockAssets(user, asset, amount)`: Lock user assets for cross-chain transfer
- `releaseAssets(user, asset, amount)`: Release assets on the destination chain
- `pause() / unpause()`: Emergency stop for contract operations

## Example Usage
```solidity
// User deposits USDC on Chain A
vault.depositCollateral(USDC, 1000e6);

// User initiates cross-chain transfer to Chain B
vault.lockAssets(user, USDC, 1000e6);
// CCIP message sent, assets released on Chain B
```

## Deployment & Integration Notes
- Deploy on each supported chain with correct CCIP router configuration
- Set up access controls for admin/emergency functions
- Integrate with PerpetualTrading contract for collateral checks and settlements
- Ensure proper event logging for cross-chain audits

## Security Considerations
- Use multi-signature for admin/emergency functions
- Validate all cross-chain messages and asset transfers
- Implement circuit breakers for abnormal activity
- Regularly audit contract and dependencies

## References
- [Chainlink CCIP Documentation](https://docs.chain.link/ccip)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [PerpChain Architecture Docs](../../docs/high_level_architec.txt)
