Here's a step-by-step guide to deploy your contracts using Foundry, including all terminal commands and configurations:

### 1. **Environment Setup**
Create a `.env` file in your project root with:
```bash
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key_without_0x_prefix
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 2. **Install Dependencies**
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install OpenZeppelin and Chainlink dependencies
forge install openzeppelin/openzeppelin-contracts
forge install smartcontractkit/chainlink
```

### 3. **Deployment Command**
Run this command to deploy all contracts:
```bash
forge script script/DeployPerpetualTrading.s.sol:DeployPerpetualTrading \
--rpc-url $SEPOLIA_RPC_URL \
--broadcast \
--verify \
--etherscan-api-key $ETHERSCAN_API_KEY \
-vvvv
```

### 4. **Post-Deployment Configuration**
After deployment, run these commands to configure cross-chain settings (replace placeholders with actual addresses from deployment logs):

```bash
# Allow Arbitrum Sepolia as source chain
cast send  \
"setAllowedSourceChain(uint64,bool)" \
3478487238524512106 true \
--rpc-url $SEPOLIA_RPC_URL

# Allow Arbitrum's CCIPReceiver as sender
cast send  \
"setAllowedSender(address,bool)" \
 true \
--rpc-url $SEPOLIA_RPC_URL

# Repeat for Arbitrum network (swap addresses)
cast send  \
"setAllowedSourceChain(uint64,bool)" \
16015286601757825753 true \
--rpc-url $ARB_SEPOLIA_RPC_URL

cast send  \
"setAllowedSender(address,bool)" \
 true \
--rpc-url $ARB_SEPOLIA_RPC_URL
```

### 5. **Fund Contracts**
Send testnet ETH/LINK to contracts for gas:
```bash
# Send ETH to CCIPReceiver for fees
cast send  --value 0.1ether

# Get testnet LINK from faucet and send to CCIPReceiver
cast send  \
"transfer(address,uint256)" \
 \
1000000000000000000  # 1 LINK
```

### 6. **Automation Setup**
Register for Chainlink Automation:
```bash
cast send  \
"register()" --value 0.1ether
```

### 7. **Verification (Alternative)**
If Etherscan verification fails, verify manually:
```bash
forge verify-contract  \
src/PerpetualTrading.sol:PerpetualTrading \
--chain-id 11155111 \
--verifier etherscan \
--etherscan-api-key $ETHERSCAN_API_KEY
```

### Key Configuration Notes:
1. **Update Addresses**: Replace all `` placeholders with addresses from deployment logs
2. **Chain Selectors**:
   - Sepolia: `16015286601757825753`
   - Arbitrum Sepolia: `3478487238524512106`
3. **Testnet Tokens**:
   - USDC: `0x07865c6E87B9F70255377e024ace6630C1Eaa37F`
   - WETH: `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9`

### Troubleshooting:
- If RPC errors occur, retry with `--gas-estimate-multiplier 200`
- For contract calls, add `--legacy` if on a non-EIP1559 chain
- Top up deployer account with Sepolia ETH from [faucets](https://sepoliafaucet.com/)

This sequence handles deployment, verification, cross-chain setup, and contract funding. All contracts are wired together with testnet parameters for immediate testing.

