// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CrossChainVault} from "../src/CrossChainVault.sol";
import {PositionManager} from "../src/PositionManager.sol";
import {PerpetualTrading} from "../src/PerpetuaTrading.sol";
import {LiquidationEngine} from "../src/LiquidationEngine.sol";
import {DataStreamOracle} from "../src/DataStreamOracle.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {CrossChainLendingPool} from "../src/LendingPool.sol";
import {CrossChainReceiver} from "../src/CCIPReceiver.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        ERC20Mock collateral = new ERC20Mock();
        console2.log("Mock ERC20 deployed at:", address(collateral));
        DataStreamOracle oracle = new DataStreamOracle();
        console2.log("DataStreamOracle deployed at:", address(oracle));
        // Add BTC/USD feed (8 decimals, 5 min heartbeat, 5% deviation, no fallback)
        oracle.addFeed("BTC/USD", "BTC/USD", 8, 300, 500, address(0));
        // Set deployer as authorized updater
        oracle.setAuthorizedUpdater(msg.sender, true);
        CrossChainVault vault = new CrossChainVault(address(0x1));
        console2.log("CrossChainVault deployed at:", address(vault));
        PositionManager manager = new PositionManager(address(oracle));
        console2.log("PositionManager deployed at:", address(manager));
        CrossChainLendingPool lendingPool = new CrossChainLendingPool(msg.sender);
        PerpetualTrading trading = new PerpetualTrading(msg.sender, address(oracle), address(lendingPool));
        console2.log("PerpetualTrading deployed at:", address(trading));
        LiquidationEngine engine = new LiquidationEngine(address(manager), address(oracle), address(vault), msg.sender);
        console2.log("LiquidationEngine deployed at:", address(engine));
        CrossChainReceiver receiver = new CrossChainReceiver(address(0x1), address(vault), address(trading), address(lendingPool));
        console2.log("CrossChainReceiver deployed at:", address(receiver));
        vm.stopBroadcast();
    }
}