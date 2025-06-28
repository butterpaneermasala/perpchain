// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function decimals() external view returns (uint8);
}

contract DataStreamOracle is Ownable(msg.sender), Pausable {
    // ===== Structs =====
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        uint256 roundId;
        uint8 decimals;
        bool isActive;
    }
    struct TWAPData {
        uint256 cumulativePrice;
        uint256 lastTimestamp;
        uint256 twapPrice;
        uint256 windowSize;
    }
    struct FeedConfig {
        string symbol;
        uint8 decimals;
        uint256 heartbeat;
        uint256 deviationThreshold;
        bool isActive;
        address fallbackFeed;
    }
    struct CircuitBreaker {
        uint256 maxDeviationBps;
        uint256 cooldownPeriod;
        uint256 lastTriggered;
        bool isEnabled;
    }

    // ===== State =====
    mapping(bytes32 => PriceData) public priceFeeds;
    mapping(bytes32 => TWAPData) public twapData;
    mapping(bytes32 => FeedConfig) public feedConfigs;
    mapping(bytes32 => CircuitBreaker) public circuitBreakers;
    mapping(address => bool) public authorizedUpdaters;
    mapping(address => bool) public priceValidators;
    bytes32[] public allFeeds;

    // ===== Events =====
    event PriceUpdated(bytes32 indexed feedId, uint256 price, uint256 timestamp, uint256 roundId);
    event CircuitBreakerTriggered(bytes32 indexed feedId, uint256 oldPrice, uint256 newPrice);

    // ===== Modifiers =====
    modifier onlyAuthorized() {
        require(authorizedUpdaters[msg.sender], "Not authorized updater");
        _;
    }
    modifier validFeed(bytes32 feedId) {
        require(feedConfigs[feedId].isActive, "Feed not active");
        _;
    }

    // ===== Core Functions =====
    function updatePrice(bytes32 feedId, uint256 price, uint256 timestamp, uint256 roundId) internal onlyAuthorized validFeed(feedId) whenNotPaused {
        require(price > 0, "Invalid price");
        require(timestamp <= block.timestamp, "Future timestamp");
        FeedConfig storage config = feedConfigs[feedId];
        require(config.isActive, "Feed not active");
        PriceData storage pd = priceFeeds[feedId];
        CircuitBreaker storage cb = circuitBreakers[feedId];
        // Circuit breaker check
        if (pd.price > 0 && cb.isEnabled) {
            uint256 deviation = _calculateDeviation(pd.price, price);
            if (deviation > cb.maxDeviationBps && block.timestamp > cb.lastTriggered + cb.cooldownPeriod) {
                cb.lastTriggered = block.timestamp;
                emit CircuitBreakerTriggered(feedId, pd.price, price);
                revert("Circuit breaker triggered");
            }
        }
        // Update price
        pd.price = price;
        pd.timestamp = timestamp;
        pd.roundId = roundId;
        pd.decimals = config.decimals;
        pd.isActive = true;
        // Update TWAP
        _updateTWAP(feedId, price, timestamp);
        emit PriceUpdated(feedId, price, timestamp, roundId);
    }

    function updatePrices(bytes32[] calldata feedIds, uint256[] calldata prices, uint256[] calldata timestamps, uint256[] calldata roundIds) external onlyAuthorized whenNotPaused {
        require(feedIds.length == prices.length && prices.length == timestamps.length && timestamps.length == roundIds.length, "Array length mismatch");
        for (uint256 i = 0; i < feedIds.length; i++) {
            updatePrice(feedIds[i], prices[i], timestamps[i], roundIds[i]);
        }
    }

    function getLatestPrice(bytes32 feedId) external view validFeed(feedId) returns (uint256 price, uint256 timestamp, uint256 roundId) {
        PriceData storage pd = priceFeeds[feedId];
        FeedConfig storage config = feedConfigs[feedId];
        // Staleness check
        if (block.timestamp - pd.timestamp > config.heartbeat) {
            // Fallback
            (price, timestamp, roundId) = _getFallbackPrice(feedId);
        } else {
            price = pd.price;
            timestamp = pd.timestamp;
            roundId = pd.roundId;
        }
    }

    function getTWAPPrice(bytes32 feedId) external view validFeed(feedId) returns (uint256 twapPrice) {
        TWAPData storage td = twapData[feedId];
        twapPrice = td.twapPrice;
    }

    function getValidatedPrice(bytes32 feedId) external view returns (uint256 price, uint256 timestamp, bool isValid) {
        FeedConfig storage config = feedConfigs[feedId];
        PriceData storage pd = priceFeeds[feedId];
        isValid = false;
        if (!config.isActive) return (0, 0, false);
        if (pd.price == 0) return (0, 0, false);
        if (block.timestamp - pd.timestamp > config.heartbeat) return (0, 0, false);
        CircuitBreaker storage cb = circuitBreakers[feedId];
        if (cb.isEnabled && block.timestamp < cb.lastTriggered + cb.cooldownPeriod) return (0, 0, false);
        price = pd.price;
        timestamp = pd.timestamp;
        isValid = true;
    }

    // ===== TWAP Internal =====
    function _updateTWAP(bytes32 feedId, uint256 price, uint256 timestamp) internal {
        TWAPData storage td = twapData[feedId];
        uint256 window = td.windowSize > 0 ? td.windowSize : 300; // default 5 min
        if (td.lastTimestamp == 0) {
            td.twapPrice = price;
            td.cumulativePrice = price * window;
            td.lastTimestamp = timestamp;
            td.windowSize = window;
        } else {
            uint256 timeElapsed = timestamp - td.lastTimestamp;
            if (timeElapsed > window) timeElapsed = window;
            td.twapPrice = (td.twapPrice * (window - timeElapsed) + price * timeElapsed) / window;
            td.cumulativePrice += price * timeElapsed;
            td.lastTimestamp = timestamp;
        }
    }

    // ===== Circuit Breaker Internal =====
    function _calculateDeviation(uint256 oldPrice, uint256 newPrice) internal pure returns (uint256) {
        if (oldPrice == 0) return 0;
        if (newPrice > oldPrice) {
            return ((newPrice - oldPrice) * 10000) / oldPrice;
        } else {
            return ((oldPrice - newPrice) * 10000) / oldPrice;
        }
    }

    // ===== Fallback Logic =====
    function _getFallbackPrice(bytes32 feedId) internal view returns (uint256 price, uint256 timestamp, uint256 roundId) {
        FeedConfig storage config = feedConfigs[feedId];
        require(config.fallbackFeed != address(0), "No fallback feed");
        AggregatorV3Interface fallbackFeed = AggregatorV3Interface(config.fallbackFeed);
        (uint80 rId, int256 answer, uint256 _startedAt, uint256 updatedAt, uint80 _answeredInRound) = fallbackFeed.latestRoundData();
        require(answer > 0, "Fallback price invalid");
        price = uint256(answer);
        timestamp = updatedAt;
        roundId = uint256(rId);
    }

    // ===== Chainlink Automation =====
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        bytes32[] memory staleFeeds = new bytes32[](allFeeds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < allFeeds.length; i++) {
            bytes32 feedId = allFeeds[i];
            FeedConfig storage config = feedConfigs[feedId];
            PriceData storage pd = priceFeeds[feedId];
            if (config.isActive && block.timestamp - pd.timestamp > config.heartbeat) {
                staleFeeds[count++] = feedId;
            }
        }
        if (count > 0) {
            bytes memory data = abi.encode(staleFeeds, count);
            return (true, data);
        }
        return (false, "");
    }

    function performUpkeep(bytes calldata performData) external {
        (bytes32[] memory staleFeeds, uint256 count) = abi.decode(performData, (bytes32[], uint256));
        for (uint256 i = 0; i < count; i++) {
            bytes32 feedId = staleFeeds[i];
            // Try fallback update
            (uint256 price, uint256 timestamp, uint256 roundId) = _getFallbackPrice(feedId);
            PriceData storage pd = priceFeeds[feedId];
            pd.price = price;
            pd.timestamp = timestamp;
            pd.roundId = roundId;
            pd.isActive = true;
            emit PriceUpdated(feedId, price, timestamp, roundId);
        }
    }

    // ===== Admin Functions =====
    function addFeed(string memory feedSymbol, string memory symbol, uint8 decimals, uint256 heartbeat, uint256 deviationThreshold, address fallbackFeed) external onlyOwner {
        bytes32 feedId = keccak256(abi.encodePacked(feedSymbol));
        require(!feedConfigs[feedId].isActive, "Feed already exists");
        feedConfigs[feedId] = FeedConfig({
            symbol: symbol,
            decimals: decimals,
            heartbeat: heartbeat,
            deviationThreshold: deviationThreshold,
            isActive: true,
            fallbackFeed: fallbackFeed
        });
        circuitBreakers[feedId] = CircuitBreaker({
            maxDeviationBps: deviationThreshold,
            cooldownPeriod: 300,
            lastTriggered: 0,
            isEnabled: true
        });
        allFeeds.push(feedId);
    }

    function pauseFeed(bytes32 feedId) external onlyOwner {
        feedConfigs[feedId].isActive = false;
    }
    function unpauseFeed(bytes32 feedId) external onlyOwner {
        feedConfigs[feedId].isActive = true;
    }
    function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner {
        authorizedUpdaters[updater] = authorized;
    }
    function setPriceValidator(address validator, bool enabled) external onlyOwner {
        priceValidators[validator] = enabled;
    }
    function emergencyUpdatePrice(bytes32 feedId, uint256 price, uint256 timestamp) external onlyOwner {
        require(price > 0, "Invalid price");
        require(timestamp <= block.timestamp, "Future timestamp");
        PriceData storage pd = priceFeeds[feedId];
        pd.price = price;
        pd.timestamp = timestamp;
        pd.roundId = pd.roundId + 1;
        pd.isActive = true;
        emit PriceUpdated(feedId, price, timestamp, pd.roundId);
    }
    function resetCircuitBreaker(bytes32 feedId) external onlyOwner {
        circuitBreakers[feedId].lastTriggered = 0;
    }

    // ===== New Setter Functions =====
    /**
     * @notice Set the TWAP window size for a feed
     * @param feedId The feed identifier
     * @param windowSize The new window size in seconds
     */
    function setTWAPWindowSize(bytes32 feedId, uint256 windowSize) external onlyOwner validFeed(feedId) {
        require(windowSize > 0, "Window size must be positive");
        twapData[feedId].windowSize = windowSize;
    }

    /**
     * @notice Set circuit breaker parameters for a feed
     * @param feedId The feed identifier
     * @param maxDeviationBps Maximum deviation in basis points
     * @param cooldownPeriod Cooldown period in seconds
     * @param isEnabled Whether the circuit breaker is enabled
     */
    function setCircuitBreakerParams(bytes32 feedId, uint256 maxDeviationBps, uint256 cooldownPeriod, bool isEnabled) external onlyOwner validFeed(feedId) {
        CircuitBreaker storage cb = circuitBreakers[feedId];
        cb.maxDeviationBps = maxDeviationBps;
        cb.cooldownPeriod = cooldownPeriod;
        cb.isEnabled = isEnabled;
    }
}
