# PositionManager.sol

## Overview
The PositionManager contract manages perpetual trading positions, margin calculations, and position tracking for the PerpChain platform. It allows users to open, close, and manage leveraged long/short positions, tracks user statistics, and enforces risk controls such as margin requirements and liquidation thresholds.

## Use Case
PositionManager enables users to participate in perpetual trading by opening positions with leverage, managing their margin, and tracking their P&L. It is designed to be integrated with vaults and oracles for a complete DeFi trading experience.

## Key Responsibilities
- Open, close, and manage perpetual long/short positions
- Track user positions and statistics (volume, P&L, open/closed positions)
- Enforce margin and leverage requirements
- Calculate and update unrealized and realized P&L
- Support margin adjustments and position liquidation

## Main Functions
- `openPosition(asset, size, entryPrice, margin, leverage, isLong)`: Open a new position
- `closePosition(positionId, exitPrice)`: Close an open position and settle P&L
- `addMargin(positionId, amount)`: Add margin to an open position
- `removeMargin(positionId, amount)`: Remove margin from an open position
- `updateUnrealizedPnl(positionId, currentPrice)`: Update unrealized P&L for a position
- `liquidatePosition(positionId, liquidationPrice)`: Liquidate a position (by liquidation engine)
- `getPosition(positionId)`: Get details of a position
- `getUserPositions(user)`: Get all position IDs for a user
- `getUserStats(user)`: Get trading statistics for a user
- `calculateHealthFactor(positionId, currentPrice)`: Calculate health factor for a position

## Example Usage
```solidity
// User opens a 10x long position on an asset
positionManager.openPosition(asset, 1000e18, 2000e6, 200e6, 10, true);

// User closes the position
positionManager.closePosition(positionId, 2100e6);

// Add margin to a position
positionManager.addMargin(positionId, 50e6);

// Remove margin from a position
positionManager.removeMargin(positionId, 20e6);

// Liquidate a position
positionManager.liquidatePosition(positionId, 1800e6);
```

## Deployment & Integration Notes
- Deploy as an Ownable contract; configure minMargin, maxLeverage, and liquidationThreshold as needed
- Integrate with vaults for collateral management and with oracles for price feeds
- Set up access control for liquidation (e.g., restrict to liquidation engine or automation)
- Connect to frontend/backend for user position management and analytics

## Security Considerations
- Validate all user inputs and enforce margin/leverage constraints
- Use access control for sensitive functions (liquidation, admin updates)
- Monitor for abnormal trading or margin removal
- Regularly audit contract and dependencies

## References
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [PerpChain Architecture Docs](../../docs/high_level_architec.txt)
