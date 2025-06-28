// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Importing security and utility contracts from OpenZeppelin and Chainlink
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Prevents reentrancy attacks
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol"; // Allows contract to be paused/unpaused
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // Provides access control (onlyOwner)
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Interface for ERC20 tokens
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Safe ERC20 operations
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {CrossChainLendingPool} from "./LendingPool.sol"; // Importing LendingPool for collateral management;

// IDataStreamOracle interface (unified)
interface IDataStreamOracle {
    function getLatestPrice(
        bytes32 feedId
    ) external view returns (uint256 price, uint256 timestamp, uint256 roundId);

    function getPriceWithValidation(
        bytes32 feedId
    ) external view returns (uint256 price, bool isValid);

    function getValidatedPrice(
        bytes32 feedId
    ) external view returns (uint256 price, uint256 timestamp, bool isValid);
}

/**
 * @title PerpetualTrading
 * @dev Cross-chain perpetual futures trading contract with Chainlink integration
 * @notice Supports leveraged trading with automated liquidations and cross-chain collateral
 */
contract PerpetualTrading is
    ReentrancyGuard, // Protects functions from reentrancy attacks
    Pausable, // Allows pausing of contract functions in emergencies
    Ownable, // Restricts certain functions to the contract owner
    AutomationCompatibleInterface // Enables Chainlink automation for liquidations
{
    using SafeERC20 for IERC20; // Enables safe ERC20 operations
    CrossChainLendingPool public lendingPool; // Lending pool for collateral management
    // Constants for precision and limits
    uint256 public constant PRECISION = 1e18; // Used for decimal calculations
    uint256 public constant MAX_LEVERAGE = 100; // Maximum leverage allowed (100x)
    uint256 public constant LIQUIDATION_THRESHOLD = 80; // Liquidation threshold (80% of margin)
    uint256 public constant LIQUIDATION_PENALTY = 5; // Penalty for liquidation (5%)
    uint256 public constant TRADING_FEE = 100; // Trading fee (0.1% in basis points)
    uint256 public constant BASIS_POINTS = 100000; // 100,000 basis points = 100%
    uint256 public constant STALENESS_THRESHOLD = 300; // 5 minutes

    // Enum for position type: LONG or SHORT
    enum PositionType {
        LONG,
        SHORT
    }
    // Enum for position status: OPEN, CLOSED, or LIQUIDATED
    enum PositionStatus {
        OPEN,
        CLOSED,
        LIQUIDATED
    }

    // Struct to store information about each trading position
    struct Position {
        uint256 id; // Unique position ID
        address trader; // Address of the trader
        PositionType positionType; // LONG or SHORT
        PositionStatus status; // OPEN, CLOSED, or LIQUIDATED
        uint256 size; // Position size in USD
        uint256 collateral; // Amount of collateral posted
        uint256 leverage; // Leverage used
        uint256 entryPrice; // Price at which position was opened
        uint256 liquidationPrice; // Price at which position will be liquidated
        uint256 timestamp; // When the position was opened
        uint256 lastFundingPayment; // Last time funding was paid
        bytes32 assetPair; // Asset pair traded (e.g., "BTC/USD")
        address collateralToken; // Token used as collateral
    }

    // Struct to store market data for each asset pair
    struct MarketData {
        bytes32 assetPair; // Asset pair identifier
        uint256 maxLeverage; // Max leverage for this market
        uint256 maintenanceMargin; // Maintenance margin in basis points
        bool isActive; // Whether the market is active
    }

    // Struct to store funding rate information for each asset pair
    struct FundingRate {
        bytes32 assetPair; // Asset pair identifier
        int256 rate; // Funding rate per hour (can be negative)
        uint256 lastUpdate; // Last time the funding rate was updated
    }

    // Mappings to store contract state
    mapping(uint256 => Position) public positions; // Maps position ID to Position struct
    mapping(address => uint256[]) public userPositions; // Maps user address to their position IDs
    mapping(bytes32 => MarketData) public markets; // Maps asset pair to market data
    mapping(bytes32 => FundingRate) public fundingRates; // Maps asset pair to funding rate
    mapping(address => mapping(address => uint256)) public userCollateral; // User's collateral per token
    mapping(uint256 => bool) public positionsToLiquidate; // Tracks positions marked for liquidation
    mapping(uint256 => uint256) public positionDebt; // positionId => debt amount in collateral token

    uint256 public nextPositionId = 1; // Next position ID to assign
    uint256 public totalVolume; // Total trading volume
    uint256 public totalFees; // Total fees collected
    address public feeRecipient; // Address to receive fees
    address public liquidationBot; // Address allowed to perform liquidations

    // Supported collateral tokens and their price feeds
    mapping(address => bool) public supportedTokens;
    // Asset/collateral to feedId mapping
    mapping(bytes32 => bytes32) public assetPairToFeedId; // assetPair => feedId
    mapping(address => bytes32) public tokenToFeedId; // token => feedId

    // Cross-chain related variables
    address public ccipReceiver; // Address for cross-chain messages
    mapping(uint256 => bool) public crossChainPositions; // Tracks cross-chain positions

    // Oracle reference
    IDataStreamOracle public oracle;

    // Events to log important actions
    event PositionOpened(
        uint256 indexed positionId,
        address indexed trader,
        bytes32 assetPair,
        PositionType positionType,
        uint256 size,
        uint256 collateral,
        uint256 leverage,
        uint256 entryPrice
    );

    event PositionClosed(
        uint256 indexed positionId,
        address indexed trader,
        uint256 exitPrice,
        int256 pnl,
        uint256 fees
    );

    event PositionLiquidated(
        uint256 indexed positionId,
        address indexed trader,
        address indexed liquidator,
        uint256 liquidationPrice,
        uint256 penalty
    );

    event CollateralDeposited(
        address indexed user,
        address token,
        uint256 amount
    );
    event CollateralWithdrawn(
        address indexed user,
        address token,
        uint256 amount
    );
    event FundingRateUpdated(bytes32 indexed assetPair, int256 rate);

    // Modifier to restrict function to the liquidation bot or owner
    modifier onlyLiquidationBot() {
        require(
            msg.sender == liquidationBot || msg.sender == owner(),
            "Only liquidation bot"
        );
        _;
    }

    // Modifier to restrict function to the CCIP receiver
    modifier onlyCCIPReceiver() {
        require(msg.sender == ccipReceiver, "Only CCIP receiver");
        _;
    }

    // Modifier to check if a market is active
    modifier validMarket(bytes32 assetPair) {
        require(markets[assetPair].isActive, "Market not active");
        _;
    }

    // Constructor sets the fee recipient, initial liquidation bot, and oracle
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

    /**
     * @dev Add a new trading market (only owner)
     * @param assetPair The asset pair (e.g., "BTC/USD")
     * @param feedId The Chainlink price feed ID
     * @param maxLeverage Maximum leverage for this market
     * @param maintenanceMargin Maintenance margin in basis points
     */
    function addMarket(
        bytes32 assetPair,
        bytes32 feedId,
        uint256 maxLeverage,
        uint256 maintenanceMargin
    ) external onlyOwner {
        require(maxLeverage <= MAX_LEVERAGE, "Leverage too high");
        require(
            maintenanceMargin > 0 && maintenanceMargin < 10000,
            "Invalid maintenance margin"
        );
        // Store market data
        markets[assetPair] = MarketData({
            assetPair: assetPair,
            maxLeverage: maxLeverage,
            maintenanceMargin: maintenanceMargin,
            isActive: true
        });
        assetPairToFeedId[assetPair] = feedId;
        // Initialize funding rate for this market
        fundingRates[assetPair] = FundingRate({
            assetPair: assetPair,
            rate: 0,
            lastUpdate: block.timestamp
        });
    }

    /**
     * @dev Add a supported collateral token (only owner)
     * @param token The ERC20 token address
     * @param feedId The Chainlink price feed ID
     */
    function addSupportedToken(
        address token,
        bytes32 feedId
    ) external onlyOwner {
        supportedTokens[token] = true;
        tokenToFeedId[token] = feedId;
    }

    /**
     * @dev Deposit collateral to the contract
     * @param token The ERC20 token address
     * @param amount The amount to deposit
     */
    function depositCollateral(
        address token,
        uint256 amount
    ) external nonReentrant {
        require(supportedTokens[token], "Token not supported");
        require(amount > 0, "Amount must be positive");

        // Transfer tokens from user to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        // Update user's collateral balance
        userCollateral[msg.sender][token] += amount;

        emit CollateralDeposited(msg.sender, token, amount);
    }

    /**
     * @dev Withdraw collateral from the contract
     * @param token The ERC20 token address
     * @param amount The amount to withdraw
     */
    function withdrawCollateral(
        address token,
        uint256 amount
    ) external nonReentrant {
        require(supportedTokens[token], "Token not supported");
        require(
            userCollateral[msg.sender][token] >= amount,
            "Insufficient collateral"
        );

        // Ensure withdrawal won't undercollateralize user's open positions
        require(
            _canWithdrawCollateral(msg.sender, token, amount),
            "Would undercollateralize positions"
        );

        // Update user's collateral balance
        userCollateral[msg.sender][token] -= amount;
        // Transfer tokens back to user
        IERC20(token).safeTransfer(msg.sender, amount);

        emit CollateralWithdrawn(msg.sender, token, amount);
    }

    /**
     * @dev Open a new perpetual trading position
     * @param assetPair The asset pair to trade
     * @param positionType LONG or SHORT
     * @param size Position size in USD
     * @param leverage Leverage to use
     * @param collateralToken Token used as collateral
     */
    function openPosition(
        bytes32 assetPair,
        PositionType positionType,
        uint256 size,
        uint256 leverage,
        address collateralToken
    ) external nonReentrant whenNotPaused validMarket(assetPair) {
        require(size > 0, "Size must be positive");
        require(
            leverage > 0 && leverage <= markets[assetPair].maxLeverage,
            "Invalid leverage"
        );
        require(
            supportedTokens[collateralToken],
            "Collateral token not supported"
        );

        // Calculate required collateral for the position
        uint256 requiredCollateral = size / leverage;
        uint256 collateralValue = _getCollateralValue(
            msg.sender,
            collateralToken
        );
        require(
            collateralValue >= requiredCollateral,
            "Insufficient collateral"
        );

        // Get current price
        uint256 currentPrice = _getAssetPrice(assetPair);
        uint256 liquidationPrice = _calculateLiquidationPrice(
            positionType,
            currentPrice,
            leverage,
            markets[assetPair].maintenanceMargin
        );

        // Calculate trading fee
        uint256 fee = (size * TRADING_FEE) / BASIS_POINTS;
        uint256 feeInCollateral = _convertUSDToToken(fee, collateralToken);
        require(
            userCollateral[msg.sender][collateralToken] >=
                feeInCollateral + requiredCollateral,
            "Insufficient collateral for fee and margin"
        );

        // Calculate and borrow leveraged amount
        uint256 borrowAmount = size - requiredCollateral;
        lendingPool.borrow(collateralToken, borrowAmount);

        // Update collateral balances
        userCollateral[msg.sender][collateralToken] -= feeInCollateral;
        userCollateral[msg.sender][collateralToken] -= requiredCollateral;
        totalFees += fee;

        Position memory newPosition = Position({
            id: nextPositionId,
            trader: msg.sender,
            positionType: positionType,
            status: PositionStatus.OPEN,
            size: size,
            collateral: requiredCollateral,
            leverage: leverage,
            entryPrice: currentPrice,
            liquidationPrice: liquidationPrice,
            timestamp: block.timestamp,
            lastFundingPayment: block.timestamp,
            assetPair: assetPair,
            collateralToken: collateralToken
        });

        positions[nextPositionId] = newPosition;
        userPositions[msg.sender].push(nextPositionId);

        // Record debt for position
        positionDebt[nextPositionId] = borrowAmount;

        emit PositionOpened(
            nextPositionId,
            msg.sender,
            assetPair,
            positionType,
            size,
            requiredCollateral,
            leverage,
            currentPrice
        );

        totalVolume += size; // Update total trading volume
        nextPositionId++; // Increment position ID for next position
    }

    /**
     * @dev Close an open position (only position owner)
     * @param positionId The ID of the position to close
     */
    function closePosition(uint256 positionId) external nonReentrant {
        Position storage position = positions[positionId];
        require(position.trader == msg.sender, "Not position owner");
        require(position.status == PositionStatus.OPEN, "Position not open");

        uint256 currentPrice = _getAssetPrice(position.assetPair);
        int256 fundingPayment = _calculateFundingPayment(positionId);
        int256 pnl = _calculatePnL(position, currentPrice);
        pnl -= fundingPayment;

        uint256 exitFee = (position.size * TRADING_FEE) / BASIS_POINTS;

        // Repay debt to lending pool
        uint256 debt = positionDebt[positionId];
        if (debt > 0) {
            lendingPool.repay(position.collateralToken, debt);
            delete positionDebt[positionId];
        }

        // Settle position
        _settlePosition(position, pnl, exitFee);
        position.status = PositionStatus.CLOSED;

        emit PositionClosed(positionId, msg.sender, currentPrice, pnl, exitFee);
    }

    /**
     * @dev Liquidate an undercollateralized position (only liquidation bot)
     * @param positionId The ID of the position to liquidate
     */
    function liquidatePosition(
        uint256 positionId
    ) external onlyLiquidationBot nonReentrant {
        Position storage position = positions[positionId];
        require(position.status == PositionStatus.OPEN, "Position not open");

        // Get current price of the asset
        uint256 currentPrice = _getAssetPrice(position.assetPair);
        // Check if position is eligible for liquidation
        require(
            _isLiquidatable(position, currentPrice),
            "Position not liquidatable"
        );

        // Calculate penalty for liquidation
        uint256 penalty = (position.collateral * LIQUIDATION_PENALTY) / 100;
        if (positionDebt[positionId] > 0) {
            uint256 repayAmount = positionDebt[positionId];
            uint256 contractBalance = IERC20(position.collateralToken)
                .balanceOf(address(this));
            if (repayAmount > contractBalance) {
                repayAmount = contractBalance;
            }
            if (repayAmount > 0) {
                lendingPool.repay(position.collateralToken, repayAmount);
                delete positionDebt[positionId];
            }
        }
        // Mark position as liquidated
        position.status = PositionStatus.LIQUIDATED;

        // Remaining collateral (if any) is returned to trader
        uint256 remainingCollateral = position.collateral > penalty
            ? position.collateral - penalty
            : 0;

        emit PositionLiquidated(
            positionId,
            position.trader,
            msg.sender,
            currentPrice,
            penalty
        );
    }

    /**
     * @dev Update funding rate for an asset pair (only owner)
     * @param assetPair The asset pair
     * @param newRate The new funding rate
     */
    function updateFundingRate(
        bytes32 assetPair,
        int256 newRate
    ) external onlyOwner {
        fundingRates[assetPair].rate = newRate;
        fundingRates[assetPair].lastUpdate = block.timestamp;

        emit FundingRateUpdated(assetPair, newRate);
    }

    /**
     * @dev Chainlink Automation: Check if upkeep (liquidation) is needed
     * @return upkeepNeeded True if any positions need liquidation
     * @return performData Encoded list of positions to liquidate
     */
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256[] memory liquidatablePositions = new uint256[](100); // Max 100 per batch
        uint256 count = 0;

        // Loop through all positions to find liquidatable ones
        for (uint256 i = 1; i < nextPositionId && count < 100; i++) {
            Position storage position = positions[i];
            if (position.status == PositionStatus.OPEN) {
                uint256 currentPrice = _getAssetPrice(position.assetPair);
                if (_isLiquidatable(position, currentPrice)) {
                    liquidatablePositions[count] = i;
                    count++;
                }
            }
        }

        if (count > 0) {
            // Resize array to actual count
            uint256[] memory result = new uint256[](count);
            for (uint256 i = 0; i < count; i++) {
                result[i] = liquidatablePositions[i];
            }
            upkeepNeeded = true;
            performData = abi.encode(result);
        }
    }

    /**
     * @dev Chainlink Automation: Perform upkeep (liquidate positions)
     * @param performData Encoded list of positions to liquidate
     */
    function performUpkeep(bytes calldata performData) external override {
        uint256[] memory positionIds = abi.decode(performData, (uint256[]));

        for (uint256 i = 0; i < positionIds.length; i++) {
            Position storage position = positions[positionIds[i]];
            if (position.status == PositionStatus.OPEN) {
                uint256 currentPrice = _getAssetPrice(position.assetPair);
                if (_isLiquidatable(position, currentPrice)) {
                    // Perform liquidation
                    uint256 penalty = (position.collateral *
                        LIQUIDATION_PENALTY) / 100;
                    position.status = PositionStatus.LIQUIDATED;

                    emit PositionLiquidated(
                        positionIds[i],
                        position.trader,
                        address(this),
                        currentPrice,
                        penalty
                    );
                }
            }
        }
    }

    // =========================
    // Internal Helper Functions
    // =========================

    /**
     * @dev Get the latest price for an asset pair from Chainlink
     * @param assetPair The asset pair
     * @return price The latest price (scaled to PRECISION)
     */
    function _getAssetPrice(bytes32 assetPair) internal view returns (uint256) {
        bytes32 feedId = assetPairToFeedId[assetPair];
        require(feedId != 0, "No feed for asset pair");
        (uint256 price, uint256 timestamp, bool isValid) = oracle
            .getValidatedPrice(feedId);
        require(isValid, "Oracle price invalid or circuit breaker active");
        require(price > 0, "Invalid price");
        require(
            block.timestamp - timestamp < STALENESS_THRESHOLD,
            "Stale price"
        );
        return price;
    }

    /**
     * @dev Get the value of a user's collateral in USD
     * @param user The user's address
     * @param token The collateral token
     * @return value The value in USD
     */
    function _getCollateralValue(
        address user,
        address token
    ) internal view returns (uint256) {
        uint256 balance = userCollateral[user][token];
        if (balance == 0) return 0;
        bytes32 feedId = tokenToFeedId[token];
        require(feedId != 0, "No feed for token");
        (uint256 price, uint256 timestamp, bool isValid) = oracle
            .getValidatedPrice(feedId);
        require(isValid, "Oracle price invalid or circuit breaker active");
        require(price > 0, "Invalid token price");
        require(
            block.timestamp - timestamp < STALENESS_THRESHOLD,
            "Stale price"
        );
        return (balance * price) / PRECISION;
    }

    /**
     * @dev Convert a USD amount to the equivalent amount in a token
     * @param usdAmount The amount in USD
     * @param token The token address
     * @return tokenAmount The equivalent token amount
     */
    function _convertUSDToToken(
        uint256 usdAmount,
        address token
    ) internal view returns (uint256) {
        bytes32 feedId = tokenToFeedId[token];
        require(feedId != 0, "No feed for token");
        (uint256 price, uint256 timestamp, bool isValid) = oracle
            .getValidatedPrice(feedId);
        require(isValid, "Oracle price invalid or circuit breaker active");
        require(price > 0, "Invalid token price");
        require(
            block.timestamp - timestamp < STALENESS_THRESHOLD,
            "Stale price"
        );
        return (usdAmount * PRECISION) / price;
    }

    /**
     * @dev Calculate the liquidation price for a position
     * @param positionType LONG or SHORT
     * @param entryPrice The price at which position was opened
     * @param leverage The leverage used
     * @param maintenanceMargin Maintenance margin in basis points
     * @return liquidationPrice The price at which position will be liquidated
     */
    function _calculateLiquidationPrice(
        PositionType positionType,
        uint256 entryPrice,
        uint256 leverage,
        uint256 maintenanceMargin
    ) internal pure returns (uint256) {
        uint256 liquidationMargin = (maintenanceMargin * PRECISION) /
            BASIS_POINTS;

        if (positionType == PositionType.LONG) {
            // For long: liquidation when price drops
            uint256 priceChange = (entryPrice *
                (PRECISION - liquidationMargin)) / (leverage * PRECISION);
            return entryPrice - priceChange;
        } else {
            // For short: liquidation when price rises
            uint256 priceChange = (entryPrice *
                (PRECISION - liquidationMargin)) / (leverage * PRECISION);
            return entryPrice + priceChange;
        }
    }

    /**
     * @dev Calculate profit or loss (PnL) for a position
     * @param position The position struct
     * @param currentPrice The current price of the asset
     * @return pnl The profit or loss (can be negative)
     */
    function _calculatePnL(
        Position memory position,
        uint256 currentPrice
    ) internal pure returns (int256) {
        int256 priceDiff;

        if (position.positionType == PositionType.LONG) {
            priceDiff = int256(currentPrice) - int256(position.entryPrice);
        } else {
            priceDiff = int256(position.entryPrice) - int256(currentPrice);
        }

        return
            (priceDiff * int256(position.size)) / int256(position.entryPrice);
    }

    /**
     * @dev Calculate funding payment for a position
     * @param positionId The position ID
     * @return payment The funding payment (can be negative)
     */
    function _calculateFundingPayment(
        uint256 positionId
    ) internal view returns (int256) {
        Position storage position = positions[positionId];
        FundingRate storage fundingRate = fundingRates[position.assetPair];

        uint256 timeElapsed = block.timestamp - position.lastFundingPayment;
        uint256 hoursElapsed = timeElapsed / 3600; // Convert to hours

        int256 payment = (int256(position.size) *
            fundingRate.rate *
            int256(hoursElapsed)) / (int256(BASIS_POINTS) * 24);

        // Long positions pay positive funding rates, short positions receive them
        if (position.positionType == PositionType.SHORT) {
            payment = -payment;
        }

        return payment;
    }

    /**
     * @dev Check if a position is eligible for liquidation
     * @param position The position struct
     * @param currentPrice The current price of the asset
     * @return isLiquidatable True if position should be liquidated
     */
    function _isLiquidatable(
        Position memory position,
        uint256 currentPrice
    ) internal pure returns (bool) {
        if (position.positionType == PositionType.LONG) {
            return currentPrice <= position.liquidationPrice;
        } else {
            return currentPrice >= position.liquidationPrice;
        }
    }

    /**
     * @dev Check if user can withdraw collateral without undercollateralizing positions
     * @param user The user's address
     * @param token The collateral token
     * @param amount The amount to withdraw
     * @return canWithdraw True if withdrawal is allowed
     */
    function _canWithdrawCollateral(
        address user,
        address token,
        uint256 amount
    ) internal view returns (bool) {
        // Get user's open positions
        uint256[] memory userPos = userPositions[user];
        // Calculate remaining collateral after withdrawal
        uint256 remainingCollateral = userCollateral[user][token] - amount;
        uint256 remainingValue = _getTokenValue(remainingCollateral, token);

        uint256 totalRequired = 0;
        // Sum required collateral for all open positions
        for (uint256 i = 0; i < userPos.length; i++) {
            Position memory pos = positions[userPos[i]];
            if (pos.status == PositionStatus.OPEN) {
                totalRequired += pos.collateral;
            }
        }

        return remainingValue >= totalRequired;
    }

    /**
     * @dev Get the value of a token amount in USD
     * @param amount The token amount
     * @param token The token address
     * @return value The value in USD
     */
    function _getTokenValue(
        uint256 amount,
        address token
    ) internal view returns (uint256) {
        if (amount == 0) return 0;
        bytes32 feedId = tokenToFeedId[token];
        require(feedId != 0, "No feed for token");
        (uint256 price, uint256 timestamp, bool isValid) = oracle
            .getValidatedPrice(feedId);
        require(isValid, "Oracle price invalid or circuit breaker active");
        require(price > 0, "Invalid token price");
        require(
            block.timestamp - timestamp < STALENESS_THRESHOLD,
            "Stale price"
        );
        return (amount * price) / PRECISION;
    }

    /**
     * @dev Settle a closed position (update balances, etc.)
     * @param position The position struct
     * @param pnl The profit or loss
     * @param fee The exit fee
     */
    function _settlePosition(
        Position memory position,
        int256 pnl,
        uint256 fee
    ) internal {
        // Implementation depends on collateral token used for the position
        // This is a simplified version - full implementation would track collateral token per position
        totalFees += fee;
    }

    // =========================
    // View Functions
    // =========================

    /**
     * @dev Get details of a position by ID
     * @param positionId The position ID
     * @return position The Position struct
     */
    function getPosition(
        uint256 positionId
    ) external view returns (Position memory) {
        return positions[positionId];
    }

    /**
     * @dev Get all position IDs for a user
     * @param user The user's address
     * @return positionIds Array of position IDs
     */
    function getUserPositions(
        address user
    ) external view returns (uint256[] memory) {
        return userPositions[user];
    }

    /**
     * @dev Get market data for an asset pair
     * @param assetPair The asset pair
     * @return marketData The MarketData struct
     */
    function getMarketData(
        bytes32 assetPair
    ) external view returns (MarketData memory) {
        return markets[assetPair];
    }

    /**
     * @dev Get user's collateral balance for a token
     * @param user The user's address
     * @param token The token address
     * @return amount The collateral amount
     */
    function getUserCollateral(
        address user,
        address token
    ) external view returns (uint256) {
        return userCollateral[user][token];
    }

    // =========================
    // Admin Functions (onlyOwner)
    // =========================

    /**
     * @dev Set the CCIP receiver address (only owner)
     * @param _ccipReceiver The new CCIP receiver address
     */
    function setCCIPReceiver(address _ccipReceiver) external onlyOwner {
        ccipReceiver = _ccipReceiver;
    }

    /**
     * @dev Set the liquidation bot address (only owner)
     * @param _liquidationBot The new liquidation bot address
     */
    function setLiquidationBot(address _liquidationBot) external onlyOwner {
        liquidationBot = _liquidationBot;
    }

    /**
     * @dev Set the fee recipient address (only owner)
     * @param _feeRecipient The new fee recipient address
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Set the oracle address (only owner)
     * @param _oracle The new oracle address
     */
    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        oracle = IDataStreamOracle(_oracle);
    }

    /**
     * @dev Pause the contract (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency withdraw all tokens from contract (only owner)
     * @param token The token address
     */
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), balance);
    }

    /**
     * @dev Set the lending pool address (only owner)
     * @param _lendingPool The new lending pool address
     */
    function setLendingPool(address _lendingPool) external onlyOwner {
        require(_lendingPool != address(0), "Invalid lending pool address");
        lendingPool = CrossChainLendingPool(_lendingPool);
    }

    // Modify the getpositions function to return status as uint
    function getpositions(
        uint id
    )
        external
        view
        returns (
            uint256,
            address,
            PositionType,
            uint status, // Change enum to uint
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Position storage p = positions[id];
        return (
            p.id,
            p.trader,
            p.positionType,
            uint(p.status), // Explicit conversion
            p.size,
            p.collateral,
            p.leverage,
            p.entryPrice,
            p.liquidationPrice
        );
    }
}
