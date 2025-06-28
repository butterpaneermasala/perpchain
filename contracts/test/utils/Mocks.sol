// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Client} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 ether);
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockRouter {
    function getFee(uint64, Client.EVM2AnyMessage memory) external pure returns (uint256) {
        return 0;
    }
    function ccipSend(uint64, Client.EVM2AnyMessage memory) external payable returns (bytes32) {
        // Do not revert, always succeed
        return keccak256(abi.encodePacked(block.timestamp, msg.sender));
    }
}

contract MockOracle {
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        bool isValid;
    }
    mapping(bytes32 => PriceData) public prices;
    function setPrice(bytes32 feedId, uint256 _price, bool _valid) external {
        prices[feedId] = PriceData({
            price: _price,
            timestamp: block.timestamp,
            isValid: _valid
        });
    }
    function setPriceWithTimestamp(bytes32 feedId, uint256 _price, bool _valid, uint256 _timestamp) external {
        prices[feedId] = PriceData({
            price: _price,
            timestamp: _timestamp,
            isValid: _valid
        });
    }
    function getLatestPrice(bytes32 feedId) external view returns (uint256, uint256, uint256) {
        PriceData memory data = prices[feedId];
        require(data.price > 0, "Price not set");
        return (data.price, data.timestamp, 1);
    }
    function getPriceWithValidation(bytes32 feedId) external view returns (uint256, bool) {
        PriceData memory data = prices[feedId];
        return (data.price, data.isValid);
    }
    function getValidatedPrice(bytes32 feedId) external view returns (uint256, uint256, bool) {
        PriceData memory data = prices[feedId];
        return (data.price, data.timestamp, data.isValid);
    }
}

contract MockPositionManager {
    struct Position {
        address trader;
        uint256 size;
        uint256 collateral;
        uint256 entryPrice;
        int256 unrealizedPnl;
        uint256 lastUpdateTime;
        bool isLong;
        bool isActive;
    }
    mapping(uint256 => Position) public positions;
    uint256[] public activePositions;
    function getPosition(uint256 positionId) external view returns (Position memory) {
        return positions[positionId];
    }
    function closePosition(uint256 positionId, uint256 price, address liquidator) external {
        positions[positionId].isActive = false;
        for (uint256 i = 0; i < activePositions.length; i++) {
            if (activePositions[i] == positionId) {
                activePositions[i] = activePositions[activePositions.length - 1];
                activePositions.pop();
                break;
            }
        }
    }
    function getAllActivePositions() external view returns (uint256[] memory) {
        return activePositions;
    }
    function updatePositionPnl(uint256 positionId, int256 pnl) external {
        positions[positionId].unrealizedPnl = pnl;
    }
    function addPosition(
        uint256 positionId,
        address trader,
        uint256 size,
        uint256 collateral,
        uint256 entryPrice,
        bool isLong
    ) external {
        positions[positionId] = Position({
            trader: trader,
            size: size,
            collateral: collateral,
            entryPrice: entryPrice,
            unrealizedPnl: 0,
            lastUpdateTime: block.timestamp,
            isLong: isLong,
            isActive: true
        });
        activePositions.push(positionId);
    }
}

contract MockVault {
    mapping(address => uint256) public balances;
    function getCollateralValue(address user, address token) external view returns (uint256) {
        return balances[user];
    }
    function liquidateCollateral(address user, uint256 amount, address liquidator) external {
        require(balances[user] >= amount, "Insufficient balance");
        balances[user] -= amount;
    }
    function getTotalCollateralUSD(address user) external view returns (uint256) {
        return balances[user];
    }
    function setBalance(address user, uint256 amount) external {
        balances[user] = amount;
    }
} 