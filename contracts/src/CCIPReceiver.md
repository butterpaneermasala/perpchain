# CCIPReceiver.sol - Cross-Chain Message Handler

## Overview

The `CCIPReceiver.sol` contract is a core component of the cross-chain perpetual trading platform that handles incoming messages from other blockchains via Chainlink's Cross-Chain Interoperability Protocol (CCIP). This contract serves as the receiving endpoint for cross-chain asset transfers, position updates, and liquidations.

## Table of Contents

- [Architecture](#architecture)
- [Key Features](#key-features)
- [Contract Structure](#contract-structure)
- [Message Types](#message-types)
- [Security Mechanisms](#security-mechanisms)
- [Function Documentation](#function-documentation)
- [Integration Guide](#integration-guide)
- [Events](#events)
- [Error Handling](#error-handling)

## Architecture

```
Source Chain                    Destination Chain
┌─────────────┐    CCIP Router    ┌─────────────────┐
│   Sender    │ ────────────────► │ CCIPReceiver    │
│  Contract   │                   │   Contract      │
└─────────────┘                   └─────────────────┘
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │   Vault &       │
                                  │ Trading Engine  │
                                  └─────────────────┘
```

## Key Features

### 🔐 Security First
- **Multi-layer Validation**: Source chain and sender allowlists
- **Replay Protection**: Message ID tracking prevents duplicate processing
- **Nonce System**: Sequential message ordering per user
- **Access Control**: Role-based permissions (Admin, Operator)
- **Pausable**: Emergency stop functionality

### 🔄 Cross-Chain Operations
- **Asset Deposits**: Receive and process cross-chain asset transfers
- **Asset Withdrawals**: Handle withdrawal requests from other chains
- **Position Sync**: Update trading positions across chains
- **Liquidations**: Process liquidation events from any chain

### 🛡️ Robust Error Handling
- Custom errors for precise failure identification
- Comprehensive validation at every step
- Emergency recovery mechanisms

## Contract Structure

### Inheritance Chain
```solidity
CrossChainReceiver
├── CCIPReceiver (Chainlink)
├── ReentrancyGuard (OpenZeppelin)
├── Pausable (OpenZeppelin)
└── AccessControl (OpenZeppelin)
```

### Core Components

#### 1. **Roles and Permissions**
```solidity
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
```

- **ADMIN_ROLE**: Full contract control, configuration changes
- **OPERATOR_ROLE**: Operational functions, monitoring
- **DEFAULT_ADMIN_ROLE**: Super admin, can grant/revoke other roles

#### 2. **State Variables**
```solidity
mapping(uint64 => bool) public allowedSourceChains;    // Allowed chain selectors
mapping(address => bool) public allowedSenders;        // Allowed sender contracts
mapping(bytes32 => bool) public processedMessages;     // Replay protection
mapping(address => uint256) public userNonces;         // User message ordering
```

#### 3. **External Contract Interfaces**
```solidity
ICrossChainVault public immutable vault;
IPerpetualTrading public immutable perpetualTrading;
```

## Message Types

### 1. **ASSET_DEPOSIT**
Handles incoming asset deposits from other chains.

**Data Structure:**
```solidity
struct AssetMessage {
    address user;      // User receiving the deposit
    address token;     // Token contract address
    uint256 amount;    // Amount being deposited
    uint256 nonce;     // Message sequence number
}
```

**Process Flow:**
1. Validate message structure and nonce
2. Verify token amounts match CCIP transfer
3. Update user nonce
4. Call vault to process deposit
5. Emit AssetProcessed event

### 2. **ASSET_WITHDRAWAL**
Processes withdrawal requests initiated on other chains.

**Process Flow:**
1. Decode withdrawal message
2. Validate nonce sequence
3. Update user nonce
4. Execute withdrawal through vault
5. Emit processing confirmation

### 3. **POSITION_UPDATE**
Synchronizes trading position changes across chains.

**Data Structure:**
```solidity
struct PositionMessage {
    address user;          // Position owner
    bytes32 positionId;    // Unique position identifier
    uint256 size;          // Position size
    uint256 collateral;    // Collateral amount
    bool isLong;           // Long/short direction
    uint256 entryPrice;    // Entry price
    uint256 nonce;         // Message sequence
}
```

### 4. **POSITION_LIQUIDATION**
Handles liquidation events from other chains.

**Data Structure:**
```solidity
struct LiquidationMessage {
    bytes32 positionId;    // Position being liquidated
    address liquidator;    // Liquidator address
    uint256 nonce;         // Message sequence
}
```

### 5. **EMERGENCY_STOP**
Triggers emergency pause of the contract.

## Security Mechanisms

### 1. **Source Chain Validation**
```solidity
if (!allowedSourceChains[any2EvmMessage.sourceChainSelector]) {
    revert InvalidSourceChain(any2EvmMessage.sourceChainSelector);
}
```
Only pre-approved chains can send messages to prevent unauthorized access.

### 2. **Sender Validation**
```solidity
address sender = abi.decode(any2EvmMessage.sender, (address));
if (!allowedSenders[sender]) {
    revert InvalidSender(sender);
}
```
Only authorized contracts can initiate cross-chain messages.

### 3. **Replay Protection**
```solidity
bytes32 messageId = any2EvmMessage.messageId;
if (processedMessages[messageId]) {
    revert MessageAlreadyProcessed(messageId);
}
processedMessages[messageId] = true;
```
Prevents the same message from being processed multiple times.

### 4. **Nonce System**
```solidity
uint256 expectedNonce = userNonces[assetMsg.user] + 1;
if (assetMsg.nonce != expectedNonce) {
    revert InvalidNonce(expectedNonce, assetMsg.nonce);
}
```
Ensures messages are processed in the correct order for each user.

## Function Documentation

### Core Functions

#### `_ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)`
**Purpose**: Main entry point for all CCIP messages
**Modifiers**: `nonReentrant`, `whenNotPaused`
**Process**:
1. Validates source chain and sender
2. Checks for message replay
3. Decodes message type and routes to appropriate handler
4. Emits MessageReceived event

#### `_processAssetDeposit(bytes memory messageData, Client.EVMTokenAmount[] memory tokenAmounts)`
**Purpose**: Processes incoming asset deposits
**Validation**:
- Nonce sequence validation
- Token amount verification
- Message data integrity

#### `_processAssetWithdrawal(bytes memory messageData)`
**Purpose**: Handles withdrawal requests
**Security**: Nonce validation and vault integration

#### `_processPositionUpdate(bytes memory messageData)`
**Purpose**: Updates trading positions from cross-chain messages
**Integration**: Calls perpetualTrading contract

#### `_processPositionLiquidation(bytes memory messageData)`
**Purpose**: Processes liquidation events
**Result**: Triggers liquidation in trading engine

### Administrative Functions

#### `setAllowedSourceChain(uint64 chainSelector, bool allowed)`
**Access**: `ADMIN_ROLE`
**Purpose**: Configure allowed source chains

#### `setAllowedSender(address sender, bool allowed)`
**Access**: `ADMIN_ROLE`
**Purpose**: Configure allowed sender contracts

#### `pause() / unpause()`
**Access**: `ADMIN_ROLE`
**Purpose**: Emergency contract control

#### `emergencyTokenRecovery(address token, uint256 amount, address to)`
**Access**: `ADMIN_ROLE`
**Purpose**: Recover stuck tokens

### View Functions

#### `getUserNonce(address user) → uint256`
**Purpose**: Get current nonce for a user

#### `isMessageProcessed(bytes32 messageId) → bool`
**Purpose**: Check if message was already processed

#### `isSourceChainAllowed(uint64 chainSelector) → bool`
**Purpose**: Check if source chain is authorized

#### `isSenderAllowed(address sender) → bool`
**Purpose**: Check if sender is authorized

## Integration Guide

### 1. **Deployment Setup**
```solidity
// Deploy with required parameters
constructor(
    address _router,        // CCIP Router address
    address _vault,         // CrossChainVault contract
    address _perpetualTrading // PerpetualTrading contract
)
```

### 2. **Initial Configuration**
```javascript
// Configure allowed chains (e.g., Ethereum, Polygon, Avalanche)
await ccipReceiver.setAllowedSourceChain(ethereumChainSelector, true);
await ccipReceiver.setAllowedSourceChain(polygonChainSelector, true);

// Configure allowed senders (sender contracts on other chains)
await ccipReceiver.setAllowedSender(ethereumSenderContract, true);
await ccipReceiver.setAllowedSender(polygonSenderContract, true);
```

### 3. **Required Interfaces**
Ensure your vault and trading contracts implement:

```solidity
interface ICrossChainVault {
    function depositFromCCIP(address user, address token, uint256 amount) external;
    function withdrawToCCIP(address user, address token, uint256 amount) external;
}

interface IPerpetualTrading {
    function updatePositionFromCCIP(
        address user,
        bytes32 positionId,
        uint256 size,
        uint256 collateral,
        bool isLong,
        uint256 entryPrice
    ) external;
    function liquidatePositionFromCCIP(bytes32 positionId, address liquidator) external;
}
```

## Events

### `MessageReceived`
```solidity
event MessageReceived(
    bytes32 indexed messageId,
    uint64 indexed sourceChainSelector,
    address indexed sender,
    MessageType messageType
);
```
**Emitted**: On every successful message reception

### `AssetProcessed`
```solidity
event AssetProcessed(
    address indexed user,
    address indexed token,
    uint256 amount,
    bool isDeposit,
    uint256 nonce
);
```
**Emitted**: On asset deposit/withdrawal processing

### `PositionUpdated`
```solidity
event PositionUpdated(
    address indexed user,
    bytes32 indexed positionId,
    uint256 size,
    uint256 collateral,
    uint256 nonce
);
```
**Emitted**: On position synchronization

### `PositionLiquidated`
```solidity
event PositionLiquidated(
    bytes32 indexed positionId,
    address indexed liquidator,
    uint256 nonce
);
```
**Emitted**: On liquidation processing

## Error Handling

### Custom Errors

#### `InvalidSourceChain(uint64 sourceChainSelector)`
**Cause**: Message from unauthorized chain
**Resolution**: Add chain to allowlist

#### `InvalidSender(address sender)`
**Cause**: Message from unauthorized sender
**Resolution**: Add sender to allowlist

#### `MessageAlreadyProcessed(bytes32 messageId)`
**Cause**: Duplicate message processing attempt
**Resolution**: Check message tracking system

#### `InvalidNonce(uint256 expected, uint256 received)`
**Cause**: Out-of-order message processing
**Resolution**: Verify message sequencing

#### `InvalidMessageData()`
**Cause**: Malformed message data
**Resolution**: Verify message encoding

## Monitoring and Maintenance

### Key Metrics to Monitor
- Message processing rate
- Failed message count
- Nonce gaps per user
- Contract pause events
- Token recovery events

### Health Checks
```javascript
// Check contract status
const isPaused = await ccipReceiver.paused();
const chainAllowed = await ccipReceiver.isSourceChainAllowed(chainId);
const senderAllowed = await ccipReceiver.isSenderAllowed(senderAddress);
```

### Emergency Procedures
1. **Pause Contract**: Call `pause()` if issues detected
2. **Check Allowlists**: Verify authorized chains/senders
3. **Monitor Events**: Track processing failures
4. **Token Recovery**: Use `emergencyTokenRecovery()` if needed

## Testing Recommendations

### Unit Tests
- Message type routing
- Validation logic
- Access control
- Error scenarios

### Integration Tests
- End-to-end cross-chain flows
- Vault integration
- Trading engine integration
- Emergency scenarios

### Security Tests
- Replay attack prevention
- Authorization bypass attempts
- Nonce manipulation
- Emergency pause functionality

## Gas Optimization Tips

1. **Batch Processing**: Consider batching multiple messages
2. **State Management**: Minimize storage operations
3. **Event Efficiency**: Use indexed parameters appropriately
4. **Error Messages**: Use custom errors instead of strings

## Conclusion

The CCIPReceiver contract provides a secure, robust foundation for cross-chain perpetual trading operations. Its multi-layered security approach, comprehensive validation, and flexible architecture make it suitable for production deployment while maintaining the ability to handle emergency situations and system updates.