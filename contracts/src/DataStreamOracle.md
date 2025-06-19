# DataStreamOracle.sol - Complete Documentation

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Core Components](#core-components)
- [Function Reference](#function-reference)
- [Security Features](#security-features)
- [Integration Guide](#integration-guide)
- [Testing & Deployment](#testing--deployment)

## 🎯 Overview

The `DataStreamOracle.sol` contract is a sophisticated price oracle system designed for cross-chain perpetual trading platforms. It integrates with Chainlink Data Streams to provide real-time, sub-second price updates with advanced risk management and fallback mechanisms.

### Key Features
- **Real-time Price Feeds**: Sub-second price updates via Chainlink Data Streams
- **Multi-Asset Support**: Handle multiple trading pairs (BTC/USD, ETH/USD, etc.)
- **Circuit Breakers**: Protection against price manipulation and extreme volatility
- **TWAP Calculations**: Time-weighted average pricing for stable valuations
- **Automated Monitoring**: Chainlink Automation for price staleness detection
- **Fallback Systems**: Redundancy with standard Chainlink aggregators

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Data Streams  │───▶│  DataStreamOracle │───▶│ Trading Platform│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │ Chainlink Keepers│
                       │   (Automation)   │
                       └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │ Fallback Oracles │
                       │  (Aggregators)   │
                       └──────────────────┘
```

## 🔧 Core Components

### 1. Data Structures

#### PriceData Struct
```solidity
struct PriceData {
    uint256 price;        // Latest price value
    uint256 timestamp;    // When price was updated
    uint256 roundId;      // Round identifier
    uint8 decimals;       // Price decimals
    bool isActive;        // Feed status
}
```

**Purpose**: Stores the latest price information for each trading pair.

**Usage**: 
- Retrieved by trading contracts for position valuation
- Used for liquidation calculations
- Provides price history tracking

#### TWAPData Struct
```solidity
struct TWAPData {
    uint256 cumulativePrice;  // Cumulative price sum
    uint256 lastTimestamp;    // Last update time
    uint256 twapPrice;        // Current TWAP value
    uint256 windowSize;       // Time window (seconds)
}
```

**Purpose**: Implements Time-Weighted Average Price calculations for smoother price transitions.

**Benefits**:
- Reduces impact of temporary price spikes
- Provides stable pricing for settlements
- Prevents MEV attacks on price feeds

#### FeedConfig Struct
```solidity
struct FeedConfig {
    string symbol;              // Trading pair symbol
    uint8 decimals;            // Price decimals
    uint256 heartbeat;         // Max time between updates
    uint256 deviationThreshold; // Max price change allowed
    bool isActive;             // Feed enabled/disabled
    address fallbackFeed;      // Backup oracle address
}
```

**Purpose**: Configuration parameters for each price feed.

**Configuration Options**:
- Symbol identification (e.g., "BTC/USD")
- Decimal precision (typically 8 for crypto)
- Update frequency requirements
- Price deviation limits
- Fallback oracle integration

#### CircuitBreaker Struct
```solidity
struct CircuitBreaker {
    uint256 maxDeviationBps;  // Max deviation (basis points)
    uint256 cooldownPeriod;   // Cooldown after trigger
    uint256 lastTriggered;    // Last trigger timestamp
    bool isEnabled;           // Circuit breaker active
}
```

**Purpose**: Implements automatic circuit breakers to prevent extreme price movements.

**Protection Mechanisms**:
- Percentage-based deviation limits
- Mandatory cooldown periods
- Automatic re-activation
- Emergency override capabilities

### 2. State Management

#### Core Mappings
```solidity
mapping(bytes32 => PriceData) public priceFeeds;
mapping(bytes32 => TWAPData) public twapData;
mapping(bytes32 => FeedConfig) public feedConfigs;
mapping(bytes32 => CircuitBreaker) public circuitBreakers;
```

**Access Patterns**:
- `feedId = keccak256(abi.encodePacked("BTC/USD"))`
- Direct O(1) lookup for all feed data
- Gas-efficient for high-frequency trading

#### Authorization System
```solidity
mapping(address => bool) public authorizedUpdaters;
mapping(address => bool) public priceValidators;
```

**Security Model**:
- Multi-tier access control
- Separate roles for different operations
- Owner-controlled authorization management

## 📖 Function Reference

### Core Price Functions

#### `updatePrice()`
```solidity
function updatePrice(
    bytes32 feedId,
    uint256 price,
    uint256 timestamp,
    uint256 roundId
) external onlyAuthorized validFeed(feedId)
```

**Purpose**: Updates a single price feed with new data from Chainlink Data Streams.

**Validation Checks**:
- Price must be positive
- Timestamp cannot be in the future
- Price age must be within limits
- Circuit breaker deviation checks

**Side Effects**:
- Updates TWAP calculations
- Emits PriceUpdated event
- May trigger circuit breakers

#### `updatePrices()` (Batch Update)
```solidity
function updatePrices(
    bytes32[] calldata feedIds,
    uint256[] calldata prices,
    uint256[] calldata timestamps,
    uint256[] calldata roundIds
) external onlyAuthorized
```

**Purpose**: Batch update multiple price feeds in a single transaction.

**Gas Optimization**:
- Reduces transaction costs for multiple feeds
- Atomic updates for correlated assets
- Efficient for high-frequency updates

#### `getLatestPrice()`
```solidity
function getLatestPrice(bytes32 feedId) 
    external view validFeed(feedId) 
    returns (uint256 price, uint256 timestamp, uint256 roundId)
```

**Purpose**: Retrieves the most recent price with staleness protection.

**Fallback Logic**:
1. Check primary Data Stream price
2. Validate price freshness
3. Fall back to Chainlink aggregator if stale
4. Revert if no valid price available

**Usage in Trading**:
- Position marking and valuation
- Margin requirement calculations
- Real-time P&L updates

#### `getTWAPPrice()`
```solidity
function getTWAPPrice(bytes32 feedId) 
    external view validFeed(feedId) 
    returns (uint256 twapPrice)
```

**Purpose**: Returns the time-weighted average price for smoother valuations.

**Applications**:
- Settlement price calculations
- Liquidation price determination
- Reducing price manipulation impact

#### `getValidatedPrice()`
```solidity
function getValidatedPrice(bytes32 feedId) 
    external view 
    returns (uint256 price, uint256 timestamp, bool isValid)
```

**Purpose**: Returns price with validation status for risk management.

**Validation Criteria**:
- Price exists and is non-zero
- Within heartbeat time window
- Circuit breaker not triggered
- Feed is active

### TWAP Implementation

#### `_updateTWAP()`
```solidity
function _updateTWAP(bytes32 feedId, uint256 price, uint256 timestamp) internal
```

**Algorithm**:
```
weightedPrice = (oldTWAP × (windowSize - timeElapsed) + newPrice × timeElapsed) / windowSize
```

**Benefits**:
- Smooths out temporary price spikes
- Provides fair average pricing
- Reduces arbitrage opportunities

### Circuit Breaker System

#### `_calculateDeviation()`
```solidity
function _calculateDeviation(uint256 oldPrice, uint256 newPrice) 
    internal pure returns (uint256)
```

**Formula**:
```
deviation = |newPrice - oldPrice| × 10000 / oldPrice
```

**Threshold Checking**:
- Compares against configured limits
- Returns basis points (1 bp = 0.01%)
- Triggers circuit breaker if exceeded

#### `_triggerCircuitBreaker()`
```solidity
function _triggerCircuitBreaker(bytes32 feedId, uint256 oldPrice, uint256 newPrice) internal
```

**Actions**:
- Records trigger timestamp
- Emits CircuitBreakerTriggered event
- Prevents price update temporarily
- Allows manual override by owner

### Chainlink Automation Integration

#### `checkUpkeep()`
```solidity
function checkUpkeep(bytes calldata) 
    external view override 
    returns (bool upkeepNeeded, bytes memory performData)
```

**Purpose**: Monitors all feeds for staleness and determines if intervention is needed.

**Logic Flow**:
1. Iterate through all active feeds
2. Check each feed's last update time
3. Compare against heartbeat requirement
4. Return stale feed IDs if found

#### `performUpkeep()`
```solidity
function performUpkeep(bytes calldata performData) external override
```

**Purpose**: Automatically updates stale prices using fallback oracles.

**Execution**:
1. Decode stale feed IDs
2. Attempt fallback price updates
3. Handle update failures gracefully
4. Maintain system availability

### Administration Functions

#### Feed Management
```solidity
function addFeed(string memory feedSymbol, ...) external onlyOwner
function pauseFeed(bytes32 feedId) external onlyOwner
function unpauseFeed(bytes32 feedId) external onlyOwner
```

**Capabilities**:
- Add new trading pairs
- Configure feed parameters
- Enable/disable feeds temporarily
- Emergency feed management

#### Access Control
```solidity
function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner
function setPriceValidator(address validator, bool enabled) external onlyOwner
```

**Security Management**:
- Grant/revoke update permissions
- Manage validator roles
- Implement least-privilege access

#### Emergency Functions
```solidity
function emergencyUpdatePrice(bytes32 feedId, uint256 price, uint256 timestamp) external onlyOwner
function resetCircuitBreaker(bytes32 feedId) external onlyOwner
```

**Crisis Management**:
- Manual price override capability
- Circuit breaker reset functionality
- Emergency system recovery

## 🛡️ Security Features

### 1. Access Control
- **Owner-only admin functions**: Critical operations restricted to contract owner
- **Authorized updaters**: Limited set of addresses can update prices
- **Role-based permissions**: Different roles for different operations

### 2. Input Validation
- **Price validation**: Non-zero, positive prices required
- **Timestamp checks**: Future timestamps rejected
- **Array length validation**: Batch operations require matching array sizes

### 3. Circuit Breakers
- **Deviation limits**: Configurable maximum price changes
- **Cooldown periods**: Mandatory waiting periods after triggers
- **Manual overrides**: Owner can reset circuit breakers

### 4. Staleness Protection
- **Heartbeat monitoring**: Maximum time between updates
- **Fallback mechanisms**: Secondary price sources
- **Automatic failover**: Seamless switching to backup oracles

### 5. State Consistency
- **Atomic updates**: All-or-nothing batch operations
- **Event logging**: Complete audit trail
- **Error handling**: Graceful failure management

## 🔌 Integration Guide

### For Trading Platforms

#### Basic Price Retrieval
```solidity
// Get current price for position valuation
(uint256 price, uint256 timestamp, uint256 roundId) = oracle.getLatestPrice(btcFeedId);

// Calculate position value
uint256 positionValue = (positionSize * price) / (10 ** decimals);
```

#### Risk Management Integration
```solidity
// Check price validity before liquidation
(uint256 price, uint256 timestamp, bool isValid) = oracle.getValidatedPrice(ethFeedId);

if (isValid && shouldLiquidate(price)) {
    // Proceed with liquidation
    liquidatePosition(positionId, price);
}
```

#### TWAP for Settlements
```solidity
// Use TWAP for fair settlement pricing
uint256 settlementPrice = oracle.getTWAPPrice(feedId);
settlePosition(positionId, settlementPrice);
```

### Event Monitoring

#### Price Update Events
```solidity
event PriceUpdated(bytes32 indexed feedId, uint256 price, uint256 timestamp, uint256 roundId);
```

**Frontend Integration**:
```javascript
// Listen for price updates
oracle.on('PriceUpdated', (feedId, price, timestamp, roundId) => {
    updateUI(feedId, price, timestamp);
    recalculatePositions();
});
```

#### Circuit Breaker Events
```solidity
event CircuitBreakerTriggered(bytes32 indexed feedId, uint256 oldPrice, uint256 newPrice);
```

**Risk Management**:
```javascript
// Monitor circuit breaker triggers
oracle.on('CircuitBreakerTriggered', (feedId, oldPrice, newPrice) => {
    pauseTrading(feedId);
    alertRiskTeam(feedId, oldPrice, newPrice);
});
```

## 🧪 Testing & Deployment

### Unit Testing

#### Price Update Tests
```solidity
function testPriceUpdate() public {
    bytes32 feedId = keccak256("BTC/USD");
    uint256 price = 50000e8;
    uint256 timestamp = block.timestamp;
    
    oracle.updatePrice(feedId, price, timestamp, 1);
    
    (uint256 retrievedPrice,,) = oracle.getLatestPrice(feedId);
    assertEq(retrievedPrice, price);
}
```

#### Circuit Breaker Tests
```solidity
function testCircuitBreaker() public {
    bytes32 feedId = keccak256("BTC/USD");
    
    // Initial price
    oracle.updatePrice(feedId, 50000e8, block.timestamp, 1);
    
    // Large price movement (>20%)
    vm.expectEmit(true, false, false, true);
    emit CircuitBreakerTriggered(feedId, 50000e8, 65000e8);
    
    oracle.updatePrice(feedId, 65000e8, block.timestamp + 1, 2);
}
```

#### TWAP Tests
```solidity
function testTWAPCalculation() public {
    bytes32 feedId = keccak256("ETH/USD");
    
    // Multiple price updates
    oracle.updatePrice(feedId, 3000e8, block.timestamp, 1);
    vm.warp(block.timestamp + 100);
    oracle.updatePrice(feedId, 3100e8, block.timestamp, 2);
    
    uint256 twapPrice = oracle.getTWAPPrice(feedId);
    assertTrue(twapPrice > 3000e8 && twapPrice < 3100e8);
}
```

### Integration Testing

#### Fallback Oracle Testing
```solidity
function testFallbackOracle() public {
    // Mock Chainlink aggregator
    MockAggregator mockAggregator = new MockAggregator();
    mockAggregator.setLatestAnswer(50000e8);
    
    // Set as fallback
    oracle.addFeed("BTC/USD", "BTC/USD", 8, 300, 500, address(mockAggregator));
    
    // Wait for staleness
    vm.warp(block.timestamp + 400);
    
    // Should use fallback
    (uint256 price,,) = oracle.getLatestPrice(keccak256("BTC/USD"));
    assertEq(price, 50000e8);
}
```

### Deployment Script

```solidity
// Deploy script
contract DeployOracle is Script {
    function run() public {
        vm.startBroadcast();
        
        DataStreamOracle oracle = new DataStreamOracle();
        
        // Configure feeds
        oracle.addFeed("BTC/USD", "BTC/USD", 8, 300, 500, CHAINLINK_BTC_FEED);
        oracle.addFeed("ETH/USD", "ETH/USD", 8, 300, 500, CHAINLINK_ETH_FEED);
        
        // Set authorized updaters
        oracle.setAuthorizedUpdater(DATA_STREAM_UPDATER, true);
        
        vm.stopBroadcast();
        
        console.log("Oracle deployed at:", address(oracle));
    }
}
```

### Gas Optimization

#### Efficient Feed Updates
- **Batch operations**: Use `updatePrices()` for multiple feeds
- **Packed structs**: Optimized storage layout
- **View functions**: Off-chain price validation

#### Storage Optimization
- **Mapping usage**: O(1) lookups for price data
- **Event indexing**: Efficient historical data retrieval
- **State minimization**: Only essential data stored

## 📊 Performance Metrics

### Gas Consumption
- **Single price update**: ~45,000 gas
- **Batch update (5 feeds)**: ~180,000 gas
- **Price retrieval**: ~3,000 gas (view function)
- **TWAP calculation**: ~8,000 gas

### Latency Targets
- **Price update processing**: <1 second
- **Circuit breaker evaluation**: <100ms
- **Fallback activation**: <5 seconds
- **TWAP calculation**: Real-time

### Reliability Metrics
- **Uptime target**: 99.9%
- **Price accuracy**: ±0.01%
- **Staleness tolerance**: 5 minutes maximum
- **Fallback success rate**: >95%

## 🚀 Best Practices

### For Developers
1. **Always validate prices** before using in critical calculations
2. **Monitor circuit breaker events** for risk management
3. **Use TWAP prices** for settlement operations
4. **Implement proper error handling** for oracle failures
5. **Set appropriate heartbeat values** for each asset

### For Operators
1. **Monitor feed health** continuously
2. **Maintain fallback oracles** for all critical feeds
3. **Regular circuit breaker parameter reviews**
4. **Automated alerting** for system anomalies
5. **Emergency response procedures** documented

### Security Considerations
1. **Multi-signature governance** for critical operations
2. **Time delays** for parameter changes
3. **Oracle diversity** to prevent single points of failure
4. **Regular security audits** and penetration testing
5. **Incident response plans** for oracle manipulation attempts

---

This oracle system provides enterprise-grade reliability and security suitable for high-stakes DeFi applications while maintaining the flexibility needed for innovative cross-chain perpetual trading platforms.