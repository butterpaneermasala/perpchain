// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, stdError} from "forge-std/Test.sol";
import {PositionManager} from "../../src/PositionManager.sol";
import {DataStreamOracle} from "../../src/DataStreamOracle.sol";

contract PositionManager_Unit is Test {
    PositionManager internal manager;
    address internal trader = address(0x456);
    address internal asset = address(0xabc);
    DataStreamOracle oracle;
    bytes32 feedId;

    function setUp() public {
        oracle = new DataStreamOracle();
        string memory assetSymbol = string(abi.encodePacked(asset));
        feedId = keccak256(abi.encodePacked(asset));
        oracle.addFeed(assetSymbol, assetSymbol, 18, 300, 500, address(0));
        oracle.setAuthorizedUpdater(address(this), true);
        oracle.setAuthorizedUpdater(trader, true);
        manager = new PositionManager(address(oracle));
        setOraclePrice(2000 ether, block.timestamp, 1);
    }

    function setOraclePrice(uint256 price, uint256 timestamp, uint256 roundId) internal {
        bytes32[] memory feedIds = new bytes32[](1);
        uint256[] memory prices = new uint256[](1);
        uint256[] memory timestamps = new uint256[](1);
        uint256[] memory roundIds = new uint256[](1);
        feedIds[0] = feedId;
        prices[0] = price;
        timestamps[0] = timestamp;
        roundIds[0] = roundId;
        oracle.updatePrices(feedIds, prices, timestamps, roundIds);
    }

    function testOpenPositionEmitsEvent() public {
        vm.startPrank(trader);
        setOraclePrice(2000 ether, block.timestamp, 1);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 margin = (size * entryPrice) / leverage;
        vm.expectEmit(true, true, true, true);
        emit PositionManager.PositionOpened(0, trader, asset, size, entryPrice, margin, leverage, true);
        manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        vm.stopPrank();
    }

    function testOpenAndClosePosition() public {
        vm.startPrank(trader);
        setOraclePrice(2000 ether, block.timestamp, 1);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 margin = (size * entryPrice) / leverage;
        uint256 posId = manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        setOraclePrice(2100 ether, block.timestamp, 2);
        manager.closePosition(posId, 2100 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.isOpen, false);
        vm.stopPrank();
    }

    function testAddAndRemoveMargin() public {
        vm.startPrank(trader);
        setOraclePrice(2000 ether, block.timestamp, 1);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 margin = (size * entryPrice) / leverage;
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
        setOraclePrice(2000 ether, block.timestamp, 1);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 margin = (size * entryPrice) / leverage;
        uint256 posId = manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        vm.expectRevert();
        manager.removeMargin(posId, margin + 1 ether);
        vm.stopPrank();
    }

    function testOpenPositionRevertsIfMarginLow() public {
        vm.startPrank(trader);
        setOraclePrice(2000 ether, block.timestamp, 1);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 margin = 1 ether;
        vm.expectRevert();
        manager.openPosition(asset, size, entryPrice, margin, leverage, true);
        vm.stopPrank();
    }
}