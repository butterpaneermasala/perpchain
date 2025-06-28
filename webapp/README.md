# PerpChain dApp

A frontend for the PerpChain protocol, built with React, Vite, Chakra UI, RainbowKit, wagmi, and ethers.

## Getting Started

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Run the dev server:**
   ```bash
   npm run dev
   ```
   The app will be available at http://localhost:5173

3. **Build for production:**
   ```bash
   npm run build
   ```

## Project Structure

- `src/abis/` — Contract ABIs (auto-copied from /contracts)
- `src/contracts.ts` — Deployed contract addresses
- `src/pages/` — Main app pages (Dashboard, Collateral, Oracle, Trading, Admin)
- `src/hooks/useContracts.ts` — Web3 contract hooks

## Notes
- Make sure your contracts are deployed and addresses are up to date in `src/contracts.ts`.
- The app uses RainbowKit for wallet connection and Chakra UI for styling. 