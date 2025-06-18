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
        uint256 posId = manager.openPosition(asset, 1000 ether, 2000 ether, 200 ether, 10, true);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.trader, trader);
        assertEq(pos.size, 1000 ether);
        assertEq(pos.isLong, true);
        vm.stopPrank();
    }

    function testClosePosition() public {
        vm.startPrank(trader);
        uint256 posId = manager.openPosition(asset, 1000 ether, 2000 ether, 200 ether, 10, true);
        manager.closePosition(posId, 2100 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.isOpen, false);
        vm.stopPrank();
    }

    function testAddRemoveMargin() public {
        vm.startPrank(trader);
        uint256 posId = manager.openPosition(asset, 1000 ether, 2000 ether, 200 ether, 10, true);
        manager.addMargin(posId, 50 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.margin, 250 ether);
        manager.removeMargin(posId, 50 ether);
        (PositionManager.Position memory pos2) = manager.getPosition(posId);
        assertEq(pos2.margin, 200 ether);
        vm.stopPrank();
    }
}
