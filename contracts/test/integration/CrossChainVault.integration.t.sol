// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CrossChainVault} from "../../src/CrossChainVault.sol";
import {MockERC20, MockRouter} from "../utils/Mocks.sol";
import {PerpetualTrading} from "../../src/PerpetuaTrading.sol";
import {LiquidationEngine} from "../../src/LiquidationEngine.sol";
import {MockOracle, MockPositionManager, MockVault} from "../utils/Mocks.sol";

contract CrossChainVault_Integration is Test {
    CrossChainVault internal vault;
    MockERC20 internal token;
    MockRouter internal router;
    address internal user = address(0x123);
    address internal receiver = address(0x456);
    uint64 internal destChain = 137;

    function setUp() public {
        router = new MockRouter();
        token = new MockERC20("MockToken", "MTK");
        vault = new CrossChainVault(address(router));
        vault.addSupportedToken(address(token));
        vault.addSupportedChain(destChain);
        token.mint(user, 1000 ether);
        vm.startPrank(user);
        token.approve(address(vault), 1000 ether);
        vm.stopPrank();
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vault.withdraw(address(token), 50 ether);
        (uint256 totalDeposited,,) = vault.getUserBalanceInfo(user);
        assertEq(totalDeposited, 50 ether);
        vm.stopPrank();
    }

    function testInitiateCrossChainTransfer() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        // This should not revert, but in a real test, you'd check router.ccipSend is called
        vault.initiateCrossChainTransfer(address(token), 10 ether, destChain, receiver);
        vm.stopPrank();
    }
}

contract PerpetualTrading_Liquidation_Integration is Test {
    PerpetualTrading internal trading;
    LiquidationEngine internal engine;
    MockERC20 internal collateral;
    MockOracle internal oracle;
    address internal user = address(0xBEEF);
    bytes32 internal assetPair = keccak256("BTC/USD");
    bytes32 internal feedId = keccak256("BTC/USD");

    function setUp() public {
        oracle = new MockOracle();
        trading = new PerpetualTrading(address(0xCAFE), address(oracle));
        collateral = new MockERC20("Mock Collateral", "MCK");
        trading.addSupportedToken(address(collateral), feedId);
        trading.addMarket(assetPair, feedId, 10, 500);
        collateral.mint(user, 1000 ether);
        vm.startPrank(user);
        collateral.approve(address(trading), 1000 ether);
        trading.depositCollateral(address(collateral), 1000 ether);
        vm.stopPrank();
        oracle.setPrice(2000 ether, true);
        // Deploy a dummy PositionManager and Vault for LiquidationEngine
        engine = new LiquidationEngine(address(new MockPositionManager()), address(oracle), address(new MockVault()), address(0xFEE));
    }

    function testFullFlow_Open_Liquidate() public {
        vm.startPrank(user);
        trading.openPosition(assetPair, PerpetualTrading.PositionType.LONG, 100 ether, 2, address(collateral));
        vm.stopPrank();
        // Simulate price drop below liquidation price
        oracle.setPrice(500 ether, true);
        vm.startPrank(address(trading.liquidationBot()));
        trading.liquidatePosition(1);
        vm.stopPrank();
    }
} 