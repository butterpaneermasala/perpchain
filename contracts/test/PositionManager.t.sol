// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {PositionManager} from "../src/PositionManager.sol";

contract PositionManagerTest is Test {
    PositionManager manager;
    address trader = address(0x456);
    address asset = address(0xabc);

    function setUp() public {
        manager = new PositionManager();
    }

    function testOpenPosition() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 posId = manager.openPosition(asset, size, entryPrice, requiredMargin, leverage, true);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.trader, trader);
        assertEq(pos.size, size);
        assertEq(pos.isLong, true);
        vm.stopPrank();
    }

    function testClosePosition() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 posId = manager.openPosition(asset, size, entryPrice, requiredMargin, leverage, true);
        manager.closePosition(posId, 2100 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.isOpen, false);
        vm.stopPrank();
    }

    function testAddRemoveMargin() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 posId = manager.openPosition(asset, size, entryPrice, requiredMargin, leverage, true);
        manager.addMargin(posId, 50 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.margin, requiredMargin + 50 ether);
        manager.removeMargin(posId, 50 ether);
        (PositionManager.Position memory pos2) = manager.getPosition(posId);
        assertEq(pos2.margin, requiredMargin);
        vm.stopPrank();
    }
}
