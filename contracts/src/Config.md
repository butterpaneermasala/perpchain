## Detailed Configuration Guide for Deploying Cross-Chain Perpetual Trading Contracts with CCIP on Testnets

This guide explains, with code references, all the configuration changes you must make before deploying your contracts (such as PerpetualTrading, CrossChainVault, LendingPool, CCIPReceiver, etc.) for testing with Chainlink CCIP routing and cross-chain functionality. It also lists recommended testnets and how to set up your deployment.

### **1. Choose Your Testnets**

For robust cross-chain and CCIP testing, select from these widely supported testnets:

| Testnet            | Chain Selector (example) | Supported by CCIP? | Notes                                 |
|--------------------|-------------------------|--------------------|---------------------------------------|
| Ethereum Sepolia   | 16015286601757825753    | Yes                | Most common for EVM/CCIP              |
| Avalanche Fuji     | 14767482510784806043    | Yes                | Fast, ideal for cross-chain with Sepolia|
| BNB Chain Testnet  | 13264668187771770619    | Yes                | Popular for cross-chain                |
| Base Sepolia       | 10344971235874465080    | Yes                | L2, supported by CCIP                  |
| Arbitrum Sepolia   | 3478487238524512106     | Yes                | L2, supported by CCIP                  |

**Reference:**  
See the full list and chain selectors at Chainlink’s [CCIP Directory][1][2].

### **2. Update Contract Addresses and Parameters**

#### **A. Constructor Arguments**

When deploying contracts like `PerpetualTrading`, `CrossChainVault`, `LendingPool`, and `CCIPReceiver`, you must provide the addresses of their dependencies (oracle, vault, lending pool, router, etc.) as constructor arguments.

**Example (PerpetualTrading.sol):**
```solidity
constructor(
    address _feeRecipient,
    address _oracle,
    address _lendingpool
) Ownable(msg.sender) {
    feeRecipient = _feeRecipient;
    liquidationBot = msg.sender;
    lendingPool = CrossChainLendingPool(_lendingpool);
    oracle = IDataStreamOracle(_oracle);
}
```
**What to change:**  
- `_feeRecipient`: Your own testnet wallet or multisig.
- `_oracle`: Address of your deployed DataStreamOracle on the testnet.
- `_lendingpool`: Address of your deployed LendingPool on the testnet.

#### **B. CCIP Router and Receiver**

- **Router:** Each testnet has a different CCIP router address.  
- **Receiver:** The address of your deployed CCIPReceiver contract.

**Example (CrossChainVault.sol):**
```solidity
constructor(address _router) Ownable(msg.sender) {
    require(_router != address(0), "Invalid router address");
    router = IRouterClient(_router);
}
```
**What to change:**  
- `_router`: Use the router address for the chosen testnet from the [CCIP Directory][1][2].

**Example (LendingPool.sol):**
```solidity
constructor(address _ccipRouter) Ownable(msg.sender) {
    ccipRouter = IRouterClient(_ccipRouter);
}
```

#### **C. Supported Tokens and Chain Selectors**

- Add supported tokens and supported chain selectors via admin functions after deployment.

**Example (CrossChainVault.sol):**
```solidity
function addSupportedToken(address token) external onlyOwner {
    require(token != address(0), "Invalid token address");
    supportedTokens[token] = true;
}

function addSupportedChain(uint64 chainSelector) external onlyOwner {
    require(chainSelector != 0, "Invalid chain selector");
    supportedChains[chainSelector] = true;
}
```
**What to change:**  
- Add the addresses of testnet ERC20 tokens you want to support.
- Add the chain selectors of testnets you want to support cross-chain transfers with.

#### **D. Chainlink Feed IDs**

- When adding markets or collateral tokens, use the correct feed IDs for the testnet.
- Feed IDs are typically the keccak256 hash of the feed symbol, or you can use the address of a deployed Chainlink price feed.

**Example (PerpetualTrading.sol):**
```solidity
function addMarket(
    bytes32 assetPair,
    bytes32 feedId,
    uint256 maxLeverage,
    uint256 maintenanceMargin
) external onlyOwner {
    // Add market logic
}

function addSupportedToken(
    address token,
    bytes32 feedId
) external onlyOwner {
    // Add token logic
}
```
**What to change:**  
- Use testnet feed IDs and addresses for each asset and collateral token.

#### **E. LINK Token Address**

- Set the LINK token address for paying CCIP fees on each testnet.

**Example (CCIPSender contract):**
```solidity
address link;
constructor(address _link, address _router) {
    link = _link;
    router = _router;
    LinkTokenInterface(link).approve(router, type(uint256).max);
}
```
**What to change:**  
- Use the LINK token address for your selected testnet (see [CCIP Directory][1][2]).

#### **F. Permissions and Allowlists (CCIPReceiver.sol)**

- Set allowed source chains and sender addresses for security.
```solidity
function setAllowedSourceChain(uint64 chainSelector, bool allowed) external onlyRole(ADMIN_ROLE) {
    allowedSourceChains[chainSelector] = allowed;
}

function setAllowedSender(address sender, bool allowed) external onlyRole(ADMIN_ROLE) {
    allowedSenders[sender] = allowed;
}
```
**What to change:**  
- Add the chain selectors and sender contract addresses you trust for cross-chain messages.

#### **G. Circuit Breaker and Heartbeat (DataStreamOracle.sol)**

- Set heartbeat and circuit breaker parameters for each feed to match testnet oracle update frequency and volatility.
```solidity
function addFeed(string memory feedSymbol, string memory symbol, uint8 decimals, uint256 heartbeat, uint256 deviationThreshold, address fallbackFeed) external onlyOwner {
    // Add feed logic
}
function setCircuitBreakerParams(bytes32 feedId, uint256 maxDeviationBps, uint256 cooldownPeriod, bool isEnabled) external onlyOwner validFeed(feedId) {
    // Set circuit breaker logic
}
```
**What to change:**  
- Adjust heartbeat (in seconds) and deviation threshold (in bps) per feed.

### **3. Example Configuration Workflow**

**Step 1: Deploy Oracle**
- Deploy `DataStreamOracle` on each testnet.
- Add feeds for each asset/collateral using testnet price feed addresses.

**Step 2: Deploy Vault, LendingPool, PerpetualTrading, CCIPReceiver**
- Deploy `CrossChainVault` with the testnet router address.
- Deploy `LendingPool` with the testnet router address.
- Deploy `PerpetualTrading` with addresses of the vault, oracle, and lending pool.
- Deploy `CCIPReceiver` with the router, vault, trading, and lending pool addresses.

**Step 3: Configure Contracts**
- Add supported tokens and chains in `CrossChainVault`.
- Add supported tokens and markets in `PerpetualTrading`.
- Set the CCIPReceiver address in `PerpetualTrading` and `LendingPool`.
- Set allowed chains and senders in `CCIPReceiver`.

**Step 4: Fund Contracts**
- Send testnet LINK to your contracts for CCIP fees.
- Fund your own testnet wallets with testnet tokens.

### **4. Example: Adding a Market and Token on Sepolia**

Suppose you want to support USDC as collateral and ETH/USD as a trading market on Sepolia.

```solidity
// Add USDC as supported collateral
perpetualTrading.addSupportedToken(
    0x...USDC_ADDRESS_ON_SEPOLIA, // USDC token address
    keccak256(abi.encodePacked("USDC/USD")) // Feed ID for USDC/USD
);

// Add ETH/USD market
perpetualTrading.addMarket(
    keccak256(abi.encodePacked("ETH/USD")), // Asset pair
    keccak256(abi.encodePacked("ETH/USD")), // Feed ID for ETH/USD
    50, // Max leverage (e.g., 50x)
    5000 // Maintenance margin (e.g., 5,000 bps = 5%)
);
```
---

### **5. Environment Variables and Deployment**

Set environment variables for private keys and RPC URLs.  
**Example .env:**
```
PRIVATE_KEY="your_testnet_private_key"
ETHEREUM_SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/..."
AVALANCHE_FUJI_RPC_URL="https://api.avax-test.network/ext/bc/C/rpc"
```
**Reference:**  
See [How to use Chainlink CCIP][3].

### **6. Testing Checklist**

- Deploy all contracts to at least two testnets (e.g., Sepolia and Fuji).
- Configure all addresses, feeds, tokens, and routers as above.
- Test cross-chain deposits/withdrawals, position opening/closing, and liquidations.
- Monitor contract events and logs for correct cross-chain message handling.

## **Summary Table: What to Change Per Testnet**

| Parameter                | Where to Set                    | How to Find Value                | Example (Sepolia)         |
|--------------------------|----------------------------------|----------------------------------|---------------------------|
| Oracle address           | PerpetualTrading, PositionManager| Deploy Oracle, use its address   | 0x...                     |
| Lending pool address     | PerpetualTrading                 | Deploy LendingPool, use address  | 0x...                     |
| Vault address            | LendingPool, CCIPReceiver        | Deploy Vault, use address        | 0x...                     |
| CCIP Router address      | Vault, LendingPool, CCIPReceiver | CCIP Directory                   | 0x...                     |
| LINK token address       | CCIPSender, for fees             | CCIP Directory                   | 0x...                     |
| Supported tokens         | Vault, PerpetualTrading          | Testnet ERC20 addresses          | 0x...                     |
| Feed IDs                 | Oracle, PerpetualTrading         | keccak256("SYMBOL/USD") or addr  | keccak256("ETH/USD")      |
| Allowed chains/selectors | Vault, CCIPReceiver              | CCIP Directory                   | 16015286601757825753      |
| Allowed senders          | CCIPReceiver                     | Your contract addresses          | 0x...                     |

## **References**
- [Chainlink CCIP Directory][1]
- [How to use Chainlink CCIP][3]
- [CCIP React Components Network Config Example][2]

**In summary:**  
Update all contract addresses, supported tokens, Chainlink feeds, CCIP router and receiver addresses, LINK token addresses, and permissions for each testnet you use. Use Sepolia, Avalanche Fuji, BNB Chain Testnet, Base Sepolia, or Arbitrum Sepolia for cross-chain CCIP testing, and configure each contract with the correct parameters as shown above for secure and effective deployment and testing.

