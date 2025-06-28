// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/PerpetuaTrading.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CrossChainLendingPool} from "../../src/LendingPool.sol";

// Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Enhanced Mock Oracle for testing
contract MockOracle {
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        bool isValid;
    }
    
    mapping(bytes32 => PriceData) public prices;
    
    function setPrice(bytes32 feedId, uint256 price, bool isValid) external {
        prices[feedId] = PriceData({
            price: price,
            timestamp: block.timestamp,
            isValid: isValid
        });
    }
    
    function setPriceWithTimestamp(bytes32 feedId, uint256 price, bool isValid, uint256 timestamp) external {
        prices[feedId] = PriceData({
            price: price,
            timestamp: timestamp,
            isValid: isValid
        });
    }
    
    function getLatestPrice(bytes32 feedId) external view returns (uint256 price, uint256 timestamp, uint256 roundId) {
        PriceData memory data = prices[feedId];
        return (data.price, data.timestamp, 1);
    }
    
    function getPriceWithValidation(bytes32 feedId) external view returns (uint256 price, bool isValid) {
        PriceData memory data = prices[feedId];
        return (data.price, data.isValid);
    }
    
    function getValidatedPrice(bytes32 feedId) external view returns (uint256 price, uint256 timestamp, bool isValid) {
        PriceData memory data = prices[feedId];
        return (data.price, data.timestamp, data.isValid);
    }
}

contract PerpetualTradingTest is Test {
    PerpetualTrading public trading;
    MockOracle public oracle;
    MockERC20 public usdc;
    MockERC20 public weth;
    CrossChainLendingPool public lendingPool;

    address public owner;
    address public trader1;
    address public trader2;
    address public liquidationBot;
    address public feeRecipient;

    bytes32 public constant BTC_USD = bytes32("BTC/USD");
    bytes32 public constant ETH_USD = bytes32("ETH/USD");
    bytes32 public constant USDC_FEED = bytes32("USDC/USD");
    bytes32 public constant WETH_FEED = bytes32("WETH/USD");
    bytes32 public constant BTC_FEED = bytes32("BTC/USD");
    bytes32 public constant ETH_FEED = bytes32("ETH/USD");

    uint256 public constant INITIAL_BTC_PRICE = 50000 * 1e18;
    uint256 public constant INITIAL_ETH_PRICE = 3000 * 1e18;
    uint256 public constant INITIAL_USDC_PRICE = 1 * 1e18;

    function setUp() public {
        owner = address(this);
        trader1 = makeAddr("trader1");
        trader2 = makeAddr("trader2");
        liquidationBot = makeAddr("liquidationBot");
        feeRecipient = makeAddr("feeRecipient");

        // Deploy contracts
        oracle = new MockOracle();
        lendingPool = new CrossChainLendingPool(address(this));
        trading = new PerpetualTrading(feeRecipient, address(oracle), address(lendingPool));

        // Deploy mock tokens
        usdc = new MockERC20("USDC", "USDC");
        weth = new MockERC20("WETH", "WETH");

        // Set up oracle prices
        oracle.setPrice(BTC_FEED, INITIAL_BTC_PRICE, true);
        oracle.setPrice(ETH_FEED, INITIAL_ETH_PRICE, true);
        oracle.setPrice(USDC_FEED, INITIAL_USDC_PRICE, true);
        oracle.setPrice(WETH_FEED, INITIAL_ETH_PRICE, true);

        // Add markets
        trading.addMarket(BTC_USD, BTC_FEED, 50, 500); // 50x leverage, 5% maintenance margin
        trading.addMarket(ETH_USD, ETH_FEED, 25, 400); // 25x leverage, 4% maintenance margin

        // Add supported tokens
        trading.addSupportedToken(address(usdc), USDC_FEED);
        trading.addSupportedToken(address(weth), WETH_FEED);

        // Set up lending pool
        lendingPool.addSupportedToken(address(usdc), 500);
        lendingPool.setCCIPReceiver(address(this));
        lendingPool.setPerpetualTrading(address(trading));

        // Add liquidity to lending pool
        usdc.mint(address(this), 1000000 * 1e18);
        usdc.approve(address(lendingPool), 1000000 * 1e18);
        lendingPool.finalizeCrossChainDeposit(address(this), address(usdc), 1000000 * 1e18, bytes32("setup"));
        // Ensure pool has real balance
        usdc.transfer(address(lendingPool), 1000000 * 1e18);

        // Set liquidation bot
        trading.setLiquidationBot(liquidationBot);

        // Mint tokens to traders
        usdc.mint(trader1, 100000 * 1e18);
        usdc.mint(trader2, 100000 * 1e18);
        weth.mint(trader1, 100 * 1e18);
        weth.mint(trader2, 100 * 1e18);
    }

    function testDepositCollateral() public {
        uint256 amount = 1000 * 1e18;
        
        vm.startPrank(trader1);
        usdc.approve(address(trading), amount);
        trading.depositCollateral(address(usdc), amount);
        
        uint256 balance = trading.getUserCollateral(trader1, address(usdc));
        assertEq(balance, amount);
        vm.stopPrank();
    }

    function testOpenPosition() public {
        uint256 size = 10000 * 1e18;
        uint256 leverage = 10;
        uint256 requiredCollateral = size / leverage;
        uint256 fee = (size * trading.TRADING_FEE()) / trading.BASIS_POINTS();
        uint256 totalDeposit = requiredCollateral + fee;
        // Deposit collateral
        vm.startPrank(trader1);
        usdc.approve(address(trading), totalDeposit);
        trading.depositCollateral(address(usdc), totalDeposit);
        // Open position
        trading.openPosition(BTC_USD, PerpetualTrading.PositionType.LONG, size, leverage, address(usdc));
        // Check position
        PerpetualTrading.Position memory position = trading.getPosition(1);
        assertEq(position.trader, trader1);
        assertEq(position.size, size);
        assertEq(position.leverage, leverage);
        assertEq(uint8(position.positionType), uint8(PerpetualTrading.PositionType.LONG));
        vm.stopPrank();
    }

    function testClosePosition() public {
        uint256 size = 10000 * 1e18;
        uint256 leverage = 10;
        uint256 requiredCollateral = size / leverage;
        uint256 fee = (size * trading.TRADING_FEE()) / trading.BASIS_POINTS();
        uint256 totalDeposit = requiredCollateral + fee;
        // Setup and open position
        vm.startPrank(trader1);
        usdc.approve(address(trading), totalDeposit);
        trading.depositCollateral(address(usdc), totalDeposit);
        trading.openPosition(BTC_USD, PerpetualTrading.PositionType.LONG, size, leverage, address(usdc));
        vm.stopPrank();
        // Approve lending pool to spend tokens from trading contract
        vm.prank(address(trading));
        usdc.approve(address(lendingPool), type(uint256).max);
        // Close position as trader1
        vm.startPrank(trader1);
        trading.closePosition(1);
        vm.stopPrank();
        // Check position status
        PerpetualTrading.Position memory position = trading.getPosition(1);
        assertEq(uint8(position.status), uint8(PerpetualTrading.PositionStatus.CLOSED));
    }

    function testLiquidation() public {
        uint256 size = 10000 * 1e18;
        uint256 leverage = 10;
        uint256 requiredCollateral = size / leverage;
        uint256 fee = (size * trading.TRADING_FEE()) / trading.BASIS_POINTS();
        uint256 totalDeposit = requiredCollateral + fee;
        // Setup and open position
        vm.startPrank(trader1);
        usdc.approve(address(trading), totalDeposit);
        trading.depositCollateral(address(usdc), totalDeposit);
        trading.openPosition(BTC_USD, PerpetualTrading.PositionType.LONG, size, leverage, address(usdc));
        vm.stopPrank();
        // Approve lending pool to spend tokens from trading contract
        vm.prank(address(trading));
        usdc.approve(address(lendingPool), type(uint256).max);
        // Simulate price drop
        oracle.setPrice(BTC_FEED, 30000 * 1e18, true);
        // Liquidate position as liquidationBot
        vm.prank(liquidationBot);
        trading.liquidatePosition(1);
        // Check position status
        PerpetualTrading.Position memory position = trading.getPosition(1);
        assertEq(uint8(position.status), uint8(PerpetualTrading.PositionStatus.LIQUIDATED));
    }

    function testWithdrawCollateral() public {
        uint256 amount = 1000 * 1e18;
        
        vm.startPrank(trader1);
        usdc.approve(address(trading), amount);
        trading.depositCollateral(address(usdc), amount);
        
        trading.withdrawCollateral(address(usdc), amount / 2);
        
        uint256 balance = trading.getUserCollateral(trader1, address(usdc));
        assertEq(balance, amount / 2);
        vm.stopPrank();
    }

    function testOnlyLiquidationBotCanLiquidate() public {
        uint256 size = 10000 * 1e18;
        uint256 leverage = 10;
        uint256 requiredCollateral = size / leverage;
        uint256 fee = (size * trading.TRADING_FEE()) / trading.BASIS_POINTS();
        uint256 totalDeposit = requiredCollateral + fee;
        // Setup and open position
        vm.startPrank(trader1);
        usdc.approve(address(trading), totalDeposit);
        trading.depositCollateral(address(usdc), totalDeposit);
        trading.openPosition(BTC_USD, PerpetualTrading.PositionType.LONG, size, leverage, address(usdc));
        vm.stopPrank();
        // Approve lending pool to spend tokens from trading contract
        vm.prank(address(trading));
        usdc.approve(address(lendingPool), type(uint256).max);
        // Simulate price drop
        oracle.setPrice(BTC_FEED, 30000 * 1e18, true);
        // Try to liquidate as non-liquidation bot
        vm.prank(trader2);
        vm.expectRevert("Only liquidation bot");
        trading.liquidatePosition(1);
        // Liquidate as liquidationBot (should succeed)
        vm.prank(liquidationBot);
        trading.liquidatePosition(1);
    }

    function testChainlinkAutomation() public {
        uint256 size = 10000 * 1e18;
        uint256 leverage = 10;
        uint256 requiredCollateral = size / leverage;
        uint256 fee = (size * trading.TRADING_FEE()) / trading.BASIS_POINTS();
        uint256 totalDeposit = requiredCollateral + fee;
        // Setup and open position
        vm.startPrank(trader1);
        usdc.approve(address(trading), totalDeposit);
        trading.depositCollateral(address(usdc), totalDeposit);
        trading.openPosition(BTC_USD, PerpetualTrading.PositionType.LONG, size, leverage, address(usdc));
        vm.stopPrank();
        // Approve lending pool to spend tokens from trading contract
        vm.prank(address(trading));
        usdc.approve(address(lendingPool), type(uint256).max);
        // Simulate price drop to trigger liquidation
        oracle.setPrice(BTC_FEED, 30000 * 1e18, true);
        // Check upkeep
        (bool upkeepNeeded, bytes memory performData) = trading.checkUpkeep("");
        assertTrue(upkeepNeeded);
        // Perform upkeep as contract owner
        vm.prank(address(this));
        trading.performUpkeep(performData);
        // Verify position was liquidated
        PerpetualTrading.Position memory position = trading.getPosition(1);
        assertEq(uint8(position.status), uint8(PerpetualTrading.PositionStatus.LIQUIDATED));
    }

    // --- Fuzz Tests for PerpetualTrading ---

    // Helper function for fuzzing
    function _depositCollateral(address trader, MockERC20 token, PerpetualTrading tradingInstance, uint256 amount) internal {
        vm.startPrank(trader);
        token.approve(address(tradingInstance), amount);
        tradingInstance.depositCollateral(address(token), amount);
        vm.stopPrank();
    }

    // Fuzz: Deposit Collateral with various amounts
    function testFuzz_DepositCollateral(uint256 amount) public {
        vm.assume(amount > 0 && amount <= usdc.balanceOf(trader1));
        _depositCollateral(trader1, usdc, trading, amount);
        assertEq(trading.getUserCollateral(trader1, address(usdc)), amount);
    }

    // Fuzz: Open Position with various parameters
    function testFuzz_OpenPosition(uint8 positionTypeRaw, uint256 size, uint256 leverage, uint256 collateralAmount) public {
        PerpetualTrading.PositionType positionType = PerpetualTrading.PositionType(bound(positionTypeRaw, 0, 1));
        size = bound(size, 1000 * 1e18, 100000 * 1e18);
        leverage = bound(leverage, 1, 50);
        if (leverage == 0 || size / leverage > 50000 * 1e18) return;
        collateralAmount = bound(collateralAmount, size / leverage, 50000 * 1e18);
        _depositCollateral(trader1, usdc, trading, collateralAmount);
        vm.startPrank(trader1);
        try trading.openPosition(BTC_USD, positionType, size, leverage, address(usdc)) {
            if (collateralAmount >= size / leverage + (size * trading.TRADING_FEE()) / trading.BASIS_POINTS()) {
                uint256 positionId = trading.nextPositionId() - 1;
                PerpetualTrading.Position memory position = trading.getPosition(positionId);
                assertEq(position.id, positionId);
                assertEq(position.trader, trader1);
                assertEq(uint8(position.positionType), uint8(positionType));
                assertEq(position.size, size);
                assertEq(position.leverage, leverage);
                assertEq(position.entryPrice, INITIAL_BTC_PRICE);
            }
        } catch {}
        vm.stopPrank();
    }

    // Fuzz: Withdraw collateral scenarios
    function testFuzz_WithdrawCollateral(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1000 * 1e18, 50000 * 1e18);
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);
        _depositCollateral(trader1, usdc, trading, depositAmount);
        vm.startPrank(trader1);
        trading.withdrawCollateral(address(usdc), withdrawAmount);
        assertEq(trading.getUserCollateral(trader1, address(usdc)), depositAmount - withdrawAmount);
        vm.stopPrank();
    }

    // Fuzz: Multiple positions with different parameters
    function testFuzz_MultiplePositions(uint256 numPositions, uint256 baseSize, uint256 baseLeverage) public {
        numPositions = bound(numPositions, 1, 10);
        baseSize = bound(baseSize, 1000 * 1e18, 10000 * 1e18);
        baseLeverage = bound(baseLeverage, 2, 25);
        uint256 totalCollateralNeeded = numPositions * ((baseSize / baseLeverage) + ((baseSize * trading.TRADING_FEE()) / trading.BASIS_POINTS()));
        _depositCollateral(trader1, usdc, trading, totalCollateralNeeded);
        vm.startPrank(trader1);
        for (uint256 i = 0; i < numPositions; i++) {
            try trading.openPosition(BTC_USD, (i % 2 == 0) ? PerpetualTrading.PositionType.LONG : PerpetualTrading.PositionType.SHORT, baseSize + (i * 100 * 1e18), baseLeverage + (i % 5), address(usdc)) {
            } catch {}
        }
        uint256[] memory userPositions = trading.getUserPositions(trader1);
        assertTrue(userPositions.length <= numPositions);
        vm.stopPrank();
    }

    // Fuzz: Chainlink Automation upkeep
    function testFuzz_ChainlinkUpkeep(uint256 numPositions, uint256 priceDropPercent) public {
        numPositions = bound(numPositions, 1, 20);
        priceDropPercent = bound(priceDropPercent, 10, 90);
        uint256 totalCollateral = numPositions * 2000 * 1e18;
        _depositCollateral(trader1, usdc, trading, totalCollateral);
        vm.startPrank(trader1);
        for (uint256 i = 0; i < numPositions; i++) {
            try trading.openPosition(BTC_USD, PerpetualTrading.PositionType.LONG, 1000 * 1e18, 10, address(usdc)) {
            } catch {}
        }
        vm.stopPrank();
        (bool upkeepNeeded, bytes memory performData) = trading.checkUpkeep("");
        if (upkeepNeeded) {
            try trading.performUpkeep(performData) {
                uint256[] memory positionIds = abi.decode(performData, (uint256[]));
                for (uint256 i = 0; i < positionIds.length; i++) {
                    PerpetualTrading.Position memory position = trading.getPosition(positionIds[i]);
                    if (position.id != 0) {
                        assertTrue(
                            uint8(position.status) == uint8(PerpetualTrading.PositionStatus.LIQUIDATED) ||
                            uint8(position.status) == uint8(PerpetualTrading.PositionStatus.OPEN)
                        );
                    }
                }
            } catch {}
        }
    }
}
