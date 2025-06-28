// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {PositionManager} from "../src/PositionManager.sol";
import {DataStreamOracle} from "../src/DataStreamOracle.sol";

contract PositionManagerTest is Test {
    PositionManager manager;
    address trader = address(0x456);
    address asset = address(0xabc);
    bytes32 feedId;
    DataStreamOracle oracle;

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

    function testOpenPosition() public {
        vm.startPrank(trader);
        setOraclePrice(2000 ether, block.timestamp, 1);
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
        setOraclePrice(2000 ether, block.timestamp, 1);
        uint256 size = 1000 ether;
        uint256 entryPrice = 2000 ether;
        uint256 leverage = 10;
        uint256 requiredMargin = (size * entryPrice) / leverage;
        uint256 posId = manager.openPosition(asset, size, entryPrice, requiredMargin, leverage, true);
        setOraclePrice(2100 ether, block.timestamp, 2);
        manager.closePosition(posId, 2100 ether);
        (PositionManager.Position memory pos) = manager.getPosition(posId);
        assertEq(pos.isOpen, false);
        vm.stopPrank();
    }

    function testAddRemoveMargin() public {
        vm.startPrank(trader);
        setOraclePrice(2000 ether, block.timestamp, 1);
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
