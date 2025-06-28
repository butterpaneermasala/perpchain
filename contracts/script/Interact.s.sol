// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {PerpetualTrading} from "../src/PerpetuaTrading.sol";
import {MockERC20} from "../test/utils/Mocks.sol";
import {Helpers} from "./Helpers.s.sol";

contract InteractScript is Script, Helpers {
    function run() external {
        vm.startBroadcast();
        // Assume contracts are already deployed and addresses are known
        address tradingAddr = vm.envAddress("PERPETUAL_TRADING");
        address collateralAddr = vm.envAddress("COLLATERAL_TOKEN");
        PerpetualTrading trading = PerpetualTrading(tradingAddr);
        MockERC20 collateral = MockERC20(collateralAddr);
        address user = msg.sender;
        fund(user, 1000 ether, collateral);
        collateral.approve(tradingAddr, 1000 ether);
        trading.depositCollateral(address(collateral), 100 ether);
        console2.log("Deposited collateral");
        // Open a position (example values)
        bytes32 assetPair = keccak256("BTC/USD");
        trading.openPosition(assetPair, PerpetualTrading.PositionType.LONG, 100 ether, 2, address(collateral));
        console2.log("Opened position");
        vm.stopBroadcast();
    }
} 