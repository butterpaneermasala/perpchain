// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

interface IPositionManager {
    struct Position {
        address trader;
        address asset;
        uint256 size;
        uint256 collateral;
        uint256 entryPrice;
        int256 unrealizedPnl;
        uint256 lastUpdateTime;
        bool isLong;
        bool isActive;
    }

    function getPosition(
        uint256 positionId
    ) external view returns (Position memory);

    function closePosition(
        uint256 positionId,
        uint256 price,
        address liquidator
    ) external;

    function getAllActivePositions() external view returns (uint256[] memory);

    function updatePositionPnl(uint256 positionId, int256 pnl) external;
}

interface IDataStreamOracle {
    function getLatestPrice(
        bytes32 feedId
    ) external view returns (uint256 price, uint256 timestamp);

    function getPriceWithValidation(
        bytes32 feedId
    ) external view returns (uint256 price, bool isValid);
}

interface ICrossChainVault {
    function getCollateralValue(
        address user,
        address token
    ) external view returns (uint256);

    function liquidateCollateral(
        address user,
        uint256 amount,
        address liquidator
    ) external;

    function getTotalCollateralUSD(
        address user
    ) external view returns (uint256);
}

/**
 * @title LiquidationEngine
 * @dev Automated liquidation system for cross-chain perpetual trading platform
 * Integrates with Chainlink Automation for reliable liquidation triggers
 */
contract LiquidationEngine is
    AutomationCompatibleInterface,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    // State Variables
    IPositionManager public positionManager;

    IDataStreamOracle public oracle;
    ICrossChainVault public vault;

    // Liquidation parameters
    uint256 public constant LIQUIDATION_THRESHOLD = 8000; // 80% in basis points
    uint256 public constant LIQUIDATION_REWARD = 500; // 5% reward for liquidator
    uint256 public constant MIN_LIQUIDATION_REWARD = 10e18; // 10 USD minimum
    uint256 public constant MAX_LIQUIDATION_REWARD = 1000e18; // 1000 USD maximum
    uint256 public constant PRICE_IMPACT_THRESHOLD = 200; // 2% max price impact

    // Automation settings
    uint256 public lastLiquidationCheck;
    uint256 public liquidationInterval = 30; // Check every 30 seconds
    uint256 public maxPositionsPerCheck = 50; // Batch processing limit

    // Fee settings
    uint256 public liquidationFee = 100; // 1% platform fee
    address public feeRecipient;

    // Emergency controls
    bool public emergencyMode = false;
    uint256 public emergencyLiquidationThreshold = 9000; // 90% in emergency

    // Position tracking
    mapping(uint256 => bool) public isPositionQueued;
    // Asset (address or bytes32) => feedId mapping
    mapping(address => bytes32) public assetToFeedId;
    uint256[] public liquidationQueue;

    // Liquidator management
    mapping(address => bool) public authorizedLiquidators;
    mapping(address => uint256) public liquidatorRewards;

    // Events
    event PositionLiquidated(
        uint256 indexed positionId,
        address indexed trader,
        address indexed liquidator,
        uint256 collateralLiquidated,
        uint256 liquidatorReward,
        uint256 timestamp
    );

    event LiquidationQueued(uint256 indexed positionId, uint256 healthRatio);
    event LiquidationDequeued(uint256 indexed positionId);
    event EmergencyModeToggled(bool enabled);
    event LiquidatorAuthorized(address indexed liquidator);
    event LiquidatorRevoked(address indexed liquidator);

    // Modifiers
    modifier onlyAuthorizedLiquidator() {
        require(
            authorizedLiquidators[msg.sender] || msg.sender == owner(),
            "Not authorized liquidator"
        );
        _;
    }

    modifier validPositionId(uint256 positionId) {
        require(positionId > 0, "Invalid position ID");
        _;
    }

    constructor(
        address _positionManager,
        address _oracle,
        address _vault,
        address _feeRecipient
    ) Ownable(msg.sender) {
        positionManager = IPositionManager(_positionManager);
        oracle = IDataStreamOracle(_oracle);
        vault = ICrossChainVault(_vault);
        feeRecipient = _feeRecipient;
        lastLiquidationCheck = block.timestamp;

        // Owner is automatically authorized liquidator
        authorizedLiquidators[msg.sender] = true;
    }

    /**
     * @dev Chainlink Automation checkUpkeep function
     * Determines if liquidations need to be performed
     */
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Check if enough time has passed
        bool timeCondition = (block.timestamp - lastLiquidationCheck) >=
            liquidationInterval;

        if (!timeCondition || paused()) {
            return (false, "");
        }

        // Get positions that need liquidation
        uint256[] memory positionsToLiquidate = _getPositionsToLiquidate();

        if (positionsToLiquidate.length > 0) {
            // Limit batch size
            uint256 batchSize = positionsToLiquidate.length >
                maxPositionsPerCheck
                ? maxPositionsPerCheck
                : positionsToLiquidate.length;

            uint256[] memory batch = new uint256[](batchSize);
            for (uint256 i = 0; i < batchSize; i++) {
                batch[i] = positionsToLiquidate[i];
            }

            upkeepNeeded = true;
            performData = abi.encode(batch);
        }
    }

    /**
     * @dev Chainlink Automation performUpkeep function
     * Executes liquidations automatically
     */
    function performUpkeep(bytes calldata performData) external override {
        require(!paused(), "Contract is paused");

        uint256[] memory positionIds = abi.decode(performData, (uint256[]));

        for (uint256 i = 0; i < positionIds.length; i++) {
            _executeLiquidation(positionIds[i], address(this));
        }

        lastLiquidationCheck = block.timestamp;
    }

    /**
     * @dev Manual liquidation function for authorized liquidators
     */
    function liquidatePosition(
        uint256 positionId
    )
        external
        nonReentrant
        whenNotPaused
        onlyAuthorizedLiquidator
        validPositionId(positionId)
    {
        require(
            _isPositionLiquidatable(positionId),
            "Position not liquidatable"
        );
        _executeLiquidation(positionId, msg.sender);
    }

    /**
     * @dev Batch liquidation for multiple positions
     */
    function batchLiquidate(
        uint256[] calldata positionIds
    ) external nonReentrant whenNotPaused onlyAuthorizedLiquidator {
        require(positionIds.length <= maxPositionsPerCheck, "Batch too large");

        for (uint256 i = 0; i < positionIds.length; i++) {
            if (_isPositionLiquidatable(positionIds[i])) {
                _executeLiquidation(positionIds[i], msg.sender);
            }
        }
    }

    /**
     * @dev Internal liquidation execution
     */
    function _executeLiquidation(
        uint256 positionId,
        address liquidator
    ) internal {
        IPositionManager.Position memory position = positionManager.getPosition(
            positionId
        );
        require(position.isActive, "Position not active");

        // Get current price for the asset
        bytes32 feedId = _getFeedId(positionId); // Implementation depends on your asset mapping
        (uint256 currentPrice, bool isValid) = oracle.getPriceWithValidation(
            feedId
        );
        require(isValid, "Invalid price data");

        // Calculate liquidation amounts
        uint256 liquidationReward = _calculateLiquidationReward(
            position.collateral
        );
        uint256 platformFee = (position.collateral * liquidationFee) / 10000;
        uint256 remainingCollateral = position.collateral -
            liquidationReward -
            platformFee;

        // Update position PnL before liquidation
        int256 pnl = _calculatePnL(position, currentPrice);
        positionManager.updatePositionPnl(positionId, pnl);

        // Execute liquidation through position manager
        positionManager.closePosition(positionId, currentPrice, liquidator);

        // Handle collateral liquidation
        vault.liquidateCollateral(
            position.trader,
            position.collateral,
            liquidator
        );

        // Distribute rewards
        if (liquidator != address(this)) {
            liquidatorRewards[liquidator] =
                liquidatorRewards[liquidator] +
                liquidationReward;
        }

        // Remove from queue if present
        _removeFromQueue(positionId);

        emit PositionLiquidated(
            positionId,
            position.trader,
            liquidator,
            position.collateral,
            liquidationReward,
            block.timestamp
        );
    }

    /**
     * @dev Set the feedId for a given asset (admin only)
     * @param asset The asset address (or use bytes32 for asset pair)
     * @param feedId The oracle feedId
     */
    function setAssetFeed(address asset, bytes32 feedId) external onlyOwner {
        require(asset != address(0), "Invalid asset");
        require(feedId != 0, "Invalid feedId");
        assetToFeedId[asset] = feedId;
    }

    /**
     * @dev Internal: Get feedId for a position
     *      Uses the asset address stored in PositionManager
     */
    function _getFeedId(uint256 positionId) internal view returns (bytes32) {
        IPositionManager.Position memory position = positionManager.getPosition(
            positionId
        );
        bytes32 feedId = assetToFeedId[position.asset];
        require(feedId != 0, "No feedId set for asset");
        return feedId;
    }

    /**
     * @dev Check if position is liquidatable
     */
    function _isPositionLiquidatable(
        uint256 positionId
    ) internal view returns (bool) {
        IPositionManager.Position memory position = positionManager.getPosition(
            positionId
        );

        if (!position.isActive) return false;

        bytes32 feedId = _getFeedId(positionId);
        (uint256 currentPrice, bool isValid) = oracle.getPriceWithValidation(
            feedId
        );
        if (!isValid) return false;

        int256 pnl = _calculatePnL(position, currentPrice);
        uint256 healthRatio = _calculateHealthRatio(position, pnl);

        uint256 threshold = emergencyMode
            ? emergencyLiquidationThreshold
            : LIQUIDATION_THRESHOLD;

        return healthRatio <= threshold;
    }

    /**
     * @dev Calculate position PnL
     */
    function _calculatePnL(
        IPositionManager.Position memory position,
        uint256 currentPrice
    ) internal pure returns (int256) {
        if (position.isLong) {
            return int256((currentPrice * position.size) / position.entryPrice);
        } else {
            return int256((position.entryPrice * position.size) / currentPrice);
        }
    }

    /**
     * @dev Calculate position health ratio (collateral value / position value)
     */
    function _calculateHealthRatio(
        IPositionManager.Position memory position,
        int256 pnl
    ) internal pure returns (uint256) {
        int256 adjustedCollateral = int256(position.collateral) + pnl;

        if (adjustedCollateral <= 0) return 0;

        return (uint256(adjustedCollateral) * 10000) / position.size;
    }

    /**
     * @dev Calculate liquidation reward
     */
    function _calculateLiquidationReward(
        uint256 collateral
    ) internal pure returns (uint256) {
        uint256 reward = (collateral * LIQUIDATION_REWARD) / 10000;

        if (reward < MIN_LIQUIDATION_REWARD) {
            reward = MIN_LIQUIDATION_REWARD;
        } else if (reward > MAX_LIQUIDATION_REWARD) {
            reward = MAX_LIQUIDATION_REWARD;
        }

        return reward;
    }

    /**
     * @dev Get positions that need liquidation
     */
    function _getPositionsToLiquidate()
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory allPositions = positionManager.getAllActivePositions();
        uint256[] memory liquidatablePositions = new uint256[](
            allPositions.length
        );
        uint256 count = 0;

        for (uint256 i = 0; i < allPositions.length; i++) {
            if (_isPositionLiquidatable(allPositions[i])) {
                liquidatablePositions[count] = allPositions[i];
                count++;
            }
        }

        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = liquidatablePositions[i];
        }

        return result;
    }

    /**
     * @dev Queue position for liquidation
     */
    function queuePositionForLiquidation(
        uint256 positionId
    ) external onlyAuthorizedLiquidator {
        require(!isPositionQueued[positionId], "Position already queued");

        liquidationQueue.push(positionId);
        isPositionQueued[positionId] = true;

        IPositionManager.Position memory position = positionManager.getPosition(
            positionId
        );
        bytes32 feedId = _getFeedId(positionId);
        (uint256 currentPrice, ) = oracle.getLatestPrice(feedId);
        int256 pnl = _calculatePnL(position, currentPrice);
        uint256 healthRatio = _calculateHealthRatio(position, pnl);

        emit LiquidationQueued(positionId, healthRatio);
    }

    /**
     * @dev Remove position from liquidation queue
     */
    function _removeFromQueue(uint256 positionId) internal {
        if (!isPositionQueued[positionId]) return;

        for (uint256 i = 0; i < liquidationQueue.length; i++) {
            if (liquidationQueue[i] == positionId) {
                liquidationQueue[i] = liquidationQueue[
                    liquidationQueue.length - 1
                ];
                liquidationQueue.pop();
                break;
            }
        }

        isPositionQueued[positionId] = false;
        emit LiquidationDequeued(positionId);
    }

    // Admin functions
    function setLiquidationInterval(uint256 _interval) external onlyOwner {
        liquidationInterval = _interval;
    }

    function setMaxPositionsPerCheck(uint256 _maxPositions) external onlyOwner {
        maxPositionsPerCheck = _maxPositions;
    }

    function setLiquidationFee(uint256 _fee) external onlyOwner {
        require(_fee <= 1000, "Fee too high"); // Max 10%
        liquidationFee = _fee;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid address");
        feeRecipient = _feeRecipient;
    }

    function toggleEmergencyMode() external onlyOwner {
        emergencyMode = !emergencyMode;
        emit EmergencyModeToggled(emergencyMode);
    }

    function authorizeLiquidator(address liquidator) external onlyOwner {
        authorizedLiquidators[liquidator] = true;
        emit LiquidatorAuthorized(liquidator);
    }

    function revokeLiquidator(address liquidator) external onlyOwner {
        authorizedLiquidators[liquidator] = false;
        emit LiquidatorRevoked(liquidator);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // View functions
    function getQueuedPositions() external view returns (uint256[] memory) {
        return liquidationQueue;
    }

    function getPositionHealthRatio(
        uint256 positionId
    ) external view returns (uint256) {
        IPositionManager.Position memory position = positionManager.getPosition(
            positionId
        );
        bytes32 feedId = _getFeedId(positionId);
        (uint256 currentPrice, ) = oracle.getLatestPrice(feedId);
        int256 pnl = _calculatePnL(position, currentPrice);
        return _calculateHealthRatio(position, pnl);
    }

    function isLiquidationDue() external view returns (bool) {
        return (block.timestamp - lastLiquidationCheck) >= liquidationInterval;
    }

    // Emergency functions
    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external view onlyOwner {
        require(emergencyMode, "Not in emergency mode");
        // Implementation for emergency token withdrawal
    }

    function updateContracts(
        address _positionManager,
        address _oracle,
        address _vault
    ) external onlyOwner {
        if (_positionManager != address(0))
            positionManager = IPositionManager(_positionManager);
        if (_oracle != address(0)) oracle = IDataStreamOracle(_oracle);
        if (_vault != address(0)) vault = ICrossChainVault(_vault);
    }
}
