// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {PositionManager} from "../../src/PositionManager.sol";
import {DataStreamOracle} from "../../src/DataStreamOracle.sol";

// Mock fallback feed contract
contract MockAggregatorV3 {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, 1000e8, block.timestamp - 1000, block.timestamp - 1000, 1);
    }
}

contract PositionManagerIntegrationTest is Test {
    DataStreamOracle oracle;
    PositionManager pm;
    address asset = address(0xBEEF);
    bytes32 feedId;
    MockAggregatorV3 mockFallbackFeed;

    function setUp() public {
        oracle = new DataStreamOracle();
        mockFallbackFeed = new MockAggregatorV3();
        string memory assetSymbol = string(abi.encodePacked(asset));
        feedId = keccak256(abi.encodePacked(asset));
        
        // Use the mock fallback feed instead of address(0)
        oracle.addFeed(assetSymbol, assetSymbol, 18, 300, 500, address(mockFallbackFeed));
        oracle.setAuthorizedUpdater(address(this), true);
        oracle.setAuthorizedUpdater(address(this), true);
        oracle.setAuthorizedUpdater(asset, true);
        pm = new PositionManager(address(oracle));
        pm.stalenessThreshold(asset); // default is 0, so fallback to 300
    }

    function testOpenPositionWithFreshPrice() public {
        // Set a fresh price
        oracle.updatePrices(
            _toArray(feedId),
            _toArray(1000e8),
            _toArray(block.timestamp),
            _toArray(1)
        );
        uint256 minMargin = 100e18;
        uint256 posId = pm.openPosition(asset, 1e8, 1000e8, minMargin, 10, true);
        assertEq(posId, 0);
    }

    function testOpenPositionWithStalePriceReverts() public {
        // Use vm.warp to ensure we have a reasonable timestamp
        vm.warp(1000); // Set block.timestamp to 1000
        
        // Set a price in the past (600 seconds ago, which is > 300 second staleness threshold)
        oracle.updatePrices(
            _toArray(feedId),
            _toArray(1000e8),
            _toArray(400), // This is 600 seconds before current timestamp of 1000
            _toArray(1)
        );
        
        // Now expect "Stale price" error since we have a fallback feed
        vm.expectRevert("Stale price");
        pm.openPosition(asset, 1e8, 1000e8, 100e18, 10, true);
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
