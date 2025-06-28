// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CrossChainVault} from "../../src/CrossChainVault.sol";
import {MockERC20, MockRouter} from "../utils/Mocks.sol";
import {PerpetualTrading} from "../../src/PerpetuaTrading.sol";
import {LiquidationEngine} from "../../src/LiquidationEngine.sol";
import {MockOracle, MockPositionManager, MockVault} from "../utils/Mocks.sol";
import {CrossChainLendingPool} from "../../src/LendingPool.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrossChainVaultFactory {
    function deploy(address router) external returns (address) {
        return address(new CrossChainVault(router));
    }

    function deployAndTransfer(
        address router,
        address newOwner
    ) external returns (address) {
        CrossChainVault vault = new CrossChainVault(router);
        vault.transferOwnership(newOwner);
        return address(vault);
    }
}

contract PerpetualTradingFactory {
    function deploy(
        address feeRecipient,
        address oracle,
        address lendingPool
    ) external returns (address) {
        return address(new PerpetualTrading(feeRecipient, oracle, lendingPool));
    }

    function deployAndTransfer(
        address feeRecipient,
        address oracle,
        address lendingPool,
        address newOwner
    ) external returns (address) {
        PerpetualTrading trading = new PerpetualTrading(
            feeRecipient,
            oracle,
            lendingPool
        );
        trading.transferOwnership(newOwner);
        return address(trading);
    }
}

contract CrossChainLendingPoolFactory {
    function deploy(address trading) external returns (address) {
        return address(new CrossChainLendingPool(trading));
    }

    function deployAndTransfer(
        address trading,
        address newOwner
    ) external returns (address) {
        CrossChainLendingPool pool = new CrossChainLendingPool(trading);
        pool.transferOwnership(newOwner);
        return address(pool);
    }
}

contract CrossChainVault_Integration is Test {
    CrossChainVault internal vault;
    MockERC20 internal token;
    MockRouter internal router;
    address internal user = address(0x123);
    address internal receiver = address(0x456);
    uint64 internal destChain = 137;
    CrossChainLendingPool lendingPool;

    function setUp() public {
        CrossChainVaultFactory vaultFactory = new CrossChainVaultFactory();
        CrossChainLendingPoolFactory poolFactory = new CrossChainLendingPoolFactory();
        vm.startPrank(address(this));
        router = new MockRouter();
        token = new MockERC20("MockToken", "MTK");
        address vaultAddr = vaultFactory.deployAndTransfer(
            address(router),
            address(this)
        );
        vault = CrossChainVault(payable(vaultAddr));
        assertEq(
            vault.owner(),
            address(this),
            "Vault owner should be address(this) after transfer"
        );
        vault.setAuthorizedCaller(address(this), true);
        vault.addSupportedToken(address(token));
        vault.addSupportedChain(destChain);
        token.mint(user, 1000 ether);
        vm.stopPrank();

        vm.startPrank(user);
        token.approve(address(vault), 1000 ether);
        vm.stopPrank();

        vm.startPrank(address(this));
        address poolAddr = poolFactory.deployAndTransfer(
            address(this),
            address(this)
        );
        lendingPool = CrossChainLendingPool(payable(poolAddr));
        assertEq(
            lendingPool.owner(),
            address(this),
            "LendingPool owner should be address(this) after transfer"
        );
        lendingPool.addSupportedToken(address(token), 500);
        // Add liquidity to the pool for testing
        token.mint(address(lendingPool), 1000 ether);
        vm.stopPrank();
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vault.withdraw(address(token), 50 ether);
        (uint256 totalDeposited, , ) = vault.getUserBalanceInfo(user);
        assertEq(totalDeposited, 50 ether);
        vm.stopPrank();
    }

    function testInitiateCrossChainTransfer() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        // This should not revert, but in a real test, you'd check router.ccipSend is called
        vault.initiateCrossChainTransfer(
            address(token),
            10 ether,
            destChain,
            receiver
        );
        vm.stopPrank();
    }
}

contract PerpetualTrading_Liquidation_Integration is Test {
    PerpetualTrading internal trading;
    LiquidationEngine internal engine;
    MockERC20 internal collateral;
    MockOracle internal oracle;
    CrossChainLendingPool internal lendingPool;
    address internal user = address(0xBEEF);
    bytes32 internal assetPair = keccak256("BTC/USD");
    bytes32 internal feedId = keccak256("BTC/USD");

    function setUp() public {
        PerpetualTradingFactory tradingFactory = new PerpetualTradingFactory();
        CrossChainLendingPoolFactory poolFactory = new CrossChainLendingPoolFactory();
        vm.startPrank(address(this));

        oracle = new MockOracle();
        collateral = new MockERC20("Mock Collateral", "MCK");

        address tradingAddr = tradingFactory.deployAndTransfer(
            address(this),
            address(oracle),
            address(0),
            address(this)
        );
        trading = PerpetualTrading(payable(tradingAddr));

        address poolAddr = poolFactory.deployAndTransfer(
            address(trading),
            address(this)
        );
        lendingPool = CrossChainLendingPool(payable(poolAddr));

        lendingPool.addSupportedToken(address(collateral), 500);
        lendingPool.setPerpetualTrading(address(trading));

        // FUND LENDING POOL (CRITICAL FIX)
        collateral.mint(address(lendingPool), 1000 ether);
        bytes32 messageId = keccak256("test");
        lendingPool.setCCIPReceiver(address(this));
        lendingPool.finalizeCrossChainDeposit(
            address(this),
            address(collateral),
            1000 ether,
            messageId
        );

        trading.setLendingPool(address(lendingPool));
        trading.addSupportedToken(address(collateral), feedId);
        trading.addMarket(assetPair, feedId, 10, 500);
        trading.setLiquidationBot(address(this));

        // Fund user
        collateral.mint(user, 10000 ether);
        vm.stopPrank();

        // **Approve lending pool to pull from PerpetualTrading**
        vm.startPrank(address(trading));
        collateral.approve(address(lendingPool), type(uint256).max);
        vm.stopPrank();

        // User deposits collateral
        vm.startPrank(user);
        collateral.approve(address(trading), 10000 ether);
        trading.depositCollateral(address(collateral), 10000 ether);
        vm.stopPrank();
    }

    function testFullFlow_Open_Liquidate() public {
        // Set initial price
        oracle.setPrice(feedId, 1000 ether, true); // $1000 per BTC

        // Open position (2x leverage long)
        vm.startPrank(user);
        trading.openPosition(
            assetPair,
            PerpetualTrading.PositionType.LONG,
            100 ether, // size
            2, // leverage
            address(collateral) // collateral token
        );
        vm.stopPrank();

        // Set liquidation price (drop below maintenance margin)
        oracle.setPrice(feedId, 400 ether, true); // 60% price drop

        // Liquidate position
        vm.prank(address(this)); // acting as liquidation bot
        trading.liquidatePosition(1); // positionId=1

        // Verify liquidation
        (, , , uint status, , , , , ) = trading.getpositions(1);
        assertEq(status, uint(PerpetualTrading.PositionStatus.LIQUIDATED));
    }
}
