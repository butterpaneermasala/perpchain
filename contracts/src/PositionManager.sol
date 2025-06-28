// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Add interface for DataStreamOracle
interface IDataStreamOracle {
    function getLatestPrice(
        bytes32 feedId
    ) external view returns (uint256 price, uint256 timestamp, uint256 roundId);
}

/**
 * @title PositionManager
 * @dev Manages perpetual trading positions, margin calculations, and position tracking
 */
contract PositionManager is ReentrancyGuard, Ownable {
    // ============ STRUCTS ============

    struct Position {
        uint256 positionId;
        address trader;
        address asset;
        uint256 size;
        uint256 entryPrice;
        uint256 margin;
        uint256 leverage;
        bool isLong;
        uint256 timestamp;
        bool isOpen;
        uint256 unrealizedPnl;
        int256 realizedPnl;
    }

    struct PositionStats {
        uint256 totalPositions;
        uint256 openPositions;
        uint256 totalVolume;
        int256 totalPnl;
    }

    // ============ STATE VARIABLES ============

    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public userPositions;
    mapping(address => PositionStats) public userStats;

    uint256 public nextPositionId;
    uint256 public totalPositions;
    uint256 public totalVolume;

    // Configuration
    uint256 public minMargin = 100 * 10 ** 18; // 100 USDC minimum
    uint256 public maxLeverage = 100; // 100x max leverage
    uint256 public liquidationThreshold = 80 * 10 ** 16; // 80% threshold

    // Oracle reference
    IDataStreamOracle public oracle;
    // Staleness threshold per asset (can be set per asset if needed)
    mapping(address => uint256) public stalenessThreshold;
    // Add to PositionManager
    mapping(address => bytes32) public assetToFeedId;

    address public liquidationEngine;

    // ============ CONSTRUCTOR ============

    constructor(address _oracle) Ownable(msg.sender) {
        oracle = IDataStreamOracle(_oracle);
    }

    // ============ EVENTS ============

    event PositionOpened(
        uint256 indexed positionId,
        address indexed trader,
        address indexed asset,
        uint256 size,
        uint256 entryPrice,
        uint256 margin,
        uint256 leverage,
        bool isLong
    );

    event PositionClosed(
        uint256 indexed positionId,
        address indexed trader,
        uint256 exitPrice,
        uint256 pnl,
        bool isProfit
    );

    event PositionLiquidated(
        uint256 indexed positionId,
        address indexed trader,
        uint256 liquidationPrice,
        uint256 loss
    );

    event MarginAdded(
        uint256 indexed positionId,
        address indexed trader,
        uint256 amount
    );

    event MarginRemoved(
        uint256 indexed positionId,
        address indexed trader,
        uint256 amount
    );

    // ============ MODIFIERS ============

    modifier onlyPositionOwner(uint256 positionId) {
        require(
            positions[positionId].trader == msg.sender,
            "Not position owner"
        );
        _;
    }

    modifier onlyOpenPosition(uint256 positionId) {
        require(positions[positionId].isOpen, "Position not open");
        _;
    }

    modifier onlyLiquidationEngine() {
        require(
            msg.sender == liquidationEngine,
            "Not authorized liquidation engine"
        );
        _;
    }

    // ============ CORE FUNCTIONS ============

    function setAssetFeed(address asset, bytes32 feedId) external onlyOwner {
        assetToFeedId[asset] = feedId;
    }

    function getPositionAsset(
        uint256 positionId
    ) external view returns (address) {
        return positions[positionId].asset;
    }

    /**
     * @dev Open a new perpetual position
     * @param asset Asset being traded
     * @param size Position size
     * @param entryPrice Entry price
     * @param margin Margin amount
     * @param leverage Leverage multiplier
     * @param isLong True for long position, false for short
     */
    function openPosition(
        address asset,
        uint256 size,
        uint256 entryPrice,
        uint256 margin,
        uint256 leverage,
        bool isLong
    ) external nonReentrant returns (uint256 positionId) {
        require(size > 0, "Size must be greater than 0");
        require(entryPrice > 0, "Entry price must be greater than 0");
        require(margin >= minMargin, "Margin below minimum");
        require(leverage <= maxLeverage, "Leverage exceeds maximum");
        require(leverage > 0, "Leverage must be greater than 0");

        // Get latest price and staleness check
        bytes32 feedId = keccak256(abi.encodePacked(asset));
        (uint256 oraclePrice, uint256 timestamp, ) = oracle.getLatestPrice(
            feedId
        );
        require(oraclePrice > 0, "Invalid oracle price");
        uint256 threshold = stalenessThreshold[asset] > 0
            ? stalenessThreshold[asset]
            : 300; // default 5 min
        require(block.timestamp - timestamp <= threshold, "Stale price");
        entryPrice = oraclePrice;

        // Calculate required margin
        uint256 requiredMargin = (size * entryPrice) / leverage;
        require(margin >= requiredMargin, "Insufficient margin");

        positionId = nextPositionId++;

        Position storage position = positions[positionId];
        position.positionId = positionId;
        position.trader = msg.sender;
        position.asset = asset;
        position.size = size;
        position.entryPrice = entryPrice;
        position.margin = margin;
        position.leverage = leverage;
        position.isLong = isLong;
        position.timestamp = block.timestamp;
        position.isOpen = true;
        position.unrealizedPnl = 0;
        position.realizedPnl = 0;

        // Update user positions
        userPositions[msg.sender].push(positionId);

        // Update statistics
        userStats[msg.sender].totalPositions++;
        userStats[msg.sender].openPositions++;
        userStats[msg.sender].totalVolume += size;

        totalPositions++;
        totalVolume += size;

        emit PositionOpened(
            positionId,
            msg.sender,
            asset,
            size,
            entryPrice,
            margin,
            leverage,
            isLong
        );

        return positionId;
    }

    /**
     * @dev Close an open position
     * @param positionId Position ID to close
     * @param exitPrice Exit price
     */
    function closePosition(
        uint256 positionId,
        uint256 exitPrice
    )
        external
        nonReentrant
        onlyPositionOwner(positionId)
        onlyOpenPosition(positionId)
    {
        Position storage position = positions[positionId];
        require(exitPrice > 0, "Exit price must be greater than 0");

        // Calculate P&L
        uint256 pnl;
        bool isProfit;

        if (position.isLong) {
            if (exitPrice > position.entryPrice) {
                pnl =
                    ((exitPrice - position.entryPrice) * position.size) /
                    position.entryPrice;
                isProfit = true;
            } else {
                pnl =
                    ((position.entryPrice - exitPrice) * position.size) /
                    position.entryPrice;
                isProfit = false;
            }
        } else {
            if (exitPrice < position.entryPrice) {
                pnl =
                    ((position.entryPrice - exitPrice) * position.size) /
                    position.entryPrice;
                isProfit = true;
            } else {
                pnl =
                    ((exitPrice - position.entryPrice) * position.size) /
                    position.entryPrice;
                isProfit = false;
            }
        }

        // Update position
        position.isOpen = false;
        position.realizedPnl = isProfit ? int256(pnl) : -int256(pnl);

        // Update user statistics
        userStats[msg.sender].openPositions--;
        if (isProfit) {
            userStats[msg.sender].totalPnl += int256(pnl);
        } else {
            userStats[msg.sender].totalPnl -= int256(pnl);
        }

        emit PositionClosed(positionId, msg.sender, exitPrice, pnl, isProfit);
    }

    /**
     * @dev Add margin to an open position
     * @param positionId Position ID
     * @param amount Amount to add
     */
    function addMargin(
        uint256 positionId,
        uint256 amount
    )
        external
        nonReentrant
        onlyPositionOwner(positionId)
        onlyOpenPosition(positionId)
    {
        require(amount > 0, "Amount must be greater than 0");

        Position storage position = positions[positionId];
        position.margin += amount;

        emit MarginAdded(positionId, msg.sender, amount);
    }

    /**
     * @dev Remove margin from an open position
     * @param positionId Position ID
     * @param amount Amount to remove
     */
    function removeMargin(
        uint256 positionId,
        uint256 amount
    )
        external
        nonReentrant
        onlyPositionOwner(positionId)
        onlyOpenPosition(positionId)
    {
        require(amount > 0, "Amount must be greater than 0");

        Position storage position = positions[positionId];
        require(position.margin > amount, "Insufficient margin to remove");

        // Check if removal would trigger liquidation
        uint256 remainingMargin = position.margin - amount;
        uint256 requiredMargin = (position.size * position.entryPrice) /
            position.leverage;
        require(
            remainingMargin >= requiredMargin,
            "Removal would trigger liquidation"
        );

        position.margin -= amount;

        emit MarginRemoved(positionId, msg.sender, amount);
    }

    /**
     * @dev Update unrealized P&L for a position
     * @param positionId Position ID
     * @param currentPrice Current market price
     */
    function updateUnrealizedPnl(
        uint256 positionId,
        uint256 currentPrice
    ) external onlyOpenPosition(positionId) {
        Position storage position = positions[positionId];

        uint256 pnl;

        if (position.isLong) {
            if (currentPrice > position.entryPrice) {
                pnl =
                    ((currentPrice - position.entryPrice) * position.size) /
                    position.entryPrice;
            } else {
                pnl =
                    ((position.entryPrice - currentPrice) * position.size) /
                    position.entryPrice;
            }
        } else {
            if (currentPrice < position.entryPrice) {
                pnl =
                    ((position.entryPrice - currentPrice) * position.size) /
                    position.entryPrice;
            } else {
                pnl =
                    ((currentPrice - position.entryPrice) * position.size) /
                    position.entryPrice;
            }
        }

        position.unrealizedPnl = pnl;
    }

    /**
     * @dev Liquidate a position (called by liquidation engine)
     * @param positionId Position ID to liquidate
     * @param liquidationPrice Liquidation price
     */
    function liquidatePosition(
        uint256 positionId,
        uint256 liquidationPrice
    ) external onlyOpenPosition(positionId) onlyLiquidationEngine {
        Position storage position = positions[positionId];

        // Calculate loss
        uint256 loss = position.margin; // Simplified - actual calculation would be more complex

        // Update position
        position.isOpen = false;
        position.realizedPnl = -int256(loss);

        // Update user statistics
        userStats[position.trader].openPositions--;
        userStats[position.trader].totalPnl -= int256(loss);

        emit PositionLiquidated(
            positionId,
            position.trader,
            liquidationPrice,
            loss
        );
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @dev Get position details
     * @param positionId Position ID
     * @return position Position struct
     */
    function getPosition(
        uint256 positionId
    ) external view returns (Position memory position) {
        return positions[positionId];
    }

    /**
     * @dev Get user's positions
     * @param user User address
     * @return positionIds Array of position IDs
     */
    function getUserPositions(
        address user
    ) external view returns (uint256[] memory positionIds) {
        return userPositions[user];
    }

    /**
     * @dev Get user's statistics
     * @param user User address
     * @return stats User statistics
     */
    function getUserStats(
        address user
    ) external view returns (PositionStats memory stats) {
        return userStats[user];
    }

    /**
     * @dev Calculate position health factor
     * @param positionId Position ID
     * @param currentPrice Current market price
     * @return healthFactor Health factor (0-100)
     */
    function calculateHealthFactor(
        uint256 positionId,
        uint256 currentPrice
    ) external view returns (uint256 healthFactor) {
        Position storage position = positions[positionId];
        if (!position.isOpen) return 0;

        // Calculate current value
        uint256 currentValue = (position.size * currentPrice) /
            position.entryPrice;
        uint256 requiredMargin = (position.size * position.entryPrice) /
            position.leverage;

        if (currentValue <= requiredMargin) {
            return 0;
        }

        return ((currentValue - requiredMargin) * 100) / requiredMargin;
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @dev Update minimum margin requirement
     * @param _minMargin New minimum margin
     */
    function updateMinMargin(uint256 _minMargin) external onlyOwner {
        minMargin = _minMargin;
    }

    /**
     * @dev Update maximum leverage
     * @param _maxLeverage New maximum leverage
     */
    function updateMaxLeverage(uint256 _maxLeverage) external onlyOwner {
        maxLeverage = _maxLeverage;
    }

    /**
     * @dev Update liquidation threshold
     * @param _liquidationThreshold New liquidation threshold
     */
    function updateLiquidationThreshold(
        uint256 _liquidationThreshold
    ) external onlyOwner {
        liquidationThreshold = _liquidationThreshold;
    }

    function setLiquidationEngine(address _engine) external onlyOwner {
        require(_engine != address(0), "Invalid address");
        liquidationEngine = _engine;
    }
}
