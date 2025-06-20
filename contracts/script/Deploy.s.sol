// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CrossChainVault} from "../src/CrossChainVault.sol";
import {PositionManager} from "../src/PositionManager.sol";
import {PerpetualTrading} from "../src/PerpetuaTrading.sol";
import {LiquidationEngine} from "../src/LiquidationEngine.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        CrossChainVault vault = new CrossChainVault(address(0x1));
        console2.log("CrossChainVault deployed at:", address(vault));
        PositionManager manager = new PositionManager();
        console2.log("PositionManager deployed at:", address(manager));
        address oracle = address(0xDEADBEEF); // TODO: set to real DataStreamOracle address
        PerpetualTrading trading = new PerpetualTrading(msg.sender, oracle);
        console2.log("PerpetualTrading deployed at:", address(trading));
        LiquidationEngine engine = new LiquidationEngine(address(manager), address(0x2), address(vault), msg.sender);
        console2.log("LiquidationEngine deployed at:", address(engine));
        vm.stopBroadcast();
    }
} 