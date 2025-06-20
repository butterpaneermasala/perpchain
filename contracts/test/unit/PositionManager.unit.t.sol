// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, stdError} from "forge-std/Test.sol";
import {PositionManager} from "../../src/PositionManager.sol";

contract PositionManager_Unit is Test {
    PositionManager internal manager;
    address internal trader = address(0x456);
    address internal asset = address(0xabc);

    function setUp() public {
        manager = new PositionManager();
    }

    function testOpenPositionEmitsEvent() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 margin = requiredMargin;
        vm.expectEmit(true, true, true, true);
        emit PositionManager.PositionOpened(0, trader, asset, size, entryPrice, margin, leverage, true);
        manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        vm.stopPrank();
    }

    function testOpenAndClosePosition() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 margin = requiredMargin;
        uint256 posId = manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        manager.closePosition(posId, 2100 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.isOpen, false);
        vm.stopPrank();
    }

    function testAddAndRemoveMargin() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 margin = requiredMargin;
        uint256 posId = manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        manager.addMargin(posId, 50 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.margin, margin + 50 ether);
        manager.removeMargin(posId, 50 ether);
        (PositionManager.Position memory pos2) = manager.getPosition(posId);
        assertEq(pos2.margin, margin);
        vm.stopPrank();
    }

    function testRemoveMarginRevertsIfInsufficient() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 margin = requiredMargin;
        uint256 posId = manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        vm.expectRevert();
        manager.removeMargin(posId, margin + 1 ether);
        vm.stopPrank();
    }

    function testOpenPositionRevertsIfMarginLow() public {
        vm.startPrank(trader);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 margin = 1 ether;
        vm.expectRevert();
        manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        vm.stopPrank();
    }
} 