// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {DataStreamOracle} from "../../src/DataStreamOracle.sol";

contract DataStreamOracleIntegrationTest is Test {
    DataStreamOracle oracle;
    address owner = address(this);
    bytes32 feedId;

    function setUp() public {
        oracle = new DataStreamOracle();
        feedId = keccak256(abi.encodePacked("BTC/USD"));
        oracle.addFeed("BTC/USD", "BTC/USD", 8, 300, 500, address(0));
        oracle.setAuthorizedUpdater(owner, true);
    }

    function testTWAPWindowConfig() public {
        // Set custom TWAP window
        oracle.setTWAPWindowSize(feedId, 600);
        // Update price and check TWAP
        oracle.updatePrices(
            _toArray(feedId),
            _toArray(50000e8),
            _toArray(block.timestamp),
            _toArray(1)
        );
        uint256 twap = oracle.getTWAPPrice(feedId);
        assertEq(twap, 50000e8);
    }

    function testCircuitBreakerParams() public {
        // Set circuit breaker params
        oracle.setCircuitBreakerParams(feedId, 100, 60, true);
        // First update
        oracle.updatePrices(
            _toArray(feedId),
            _toArray(50000e8),
            _toArray(block.timestamp),
            _toArray(1)
        );
        // Second update triggers circuit breaker
        vm.expectRevert();
        oracle.updatePrices(
            _toArray(feedId),
            _toArray(60000e8),
            _toArray(block.timestamp + 1),
            _toArray(2)
        );
    }

    function testPerFeedStaleness() public {
        // Update price
        oracle.updatePrices(
            _toArray(feedId),
            _toArray(50000e8),
            _toArray(block.timestamp),
            _toArray(1)
        );
        // Warp past heartbeat
        vm.warp(block.timestamp + 301);
        vm.expectRevert();
        oracle.getLatestPrice(feedId);
    }

    function _toArray(bytes32 v) internal pure returns (bytes32[] memory arr) {
        arr = new bytes32[](1);
        arr[0] = v;
    }
    function _toArray(uint256 v) internal pure returns (uint256[] memory arr) {
        arr = new uint256[](1);
        arr[0] = v;
    }
} 