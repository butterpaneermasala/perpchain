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
    function ccipSend(uint64, Client.EVM2AnyMessage memory) external payable returns (bytes32) {
        return bytes32(0);
    }
}

contract MockOracle {
    uint256 public price;
    bool public valid;
    uint256 public timestamp;
    function setPrice(uint256 _price, bool _valid) external {
        price = _price;
        valid = _valid;
        timestamp = block.timestamp;
    }
    function setPriceWithTimestamp(uint256 _price, bool _valid, uint256 _timestamp) external {
        price = _price;
        valid = _valid;
        timestamp = _timestamp;
    }
    function getLatestPrice(bytes32) external view returns (uint256, uint256) {
        return (price, timestamp);
    }
    function getPriceWithValidation(bytes32) external view returns (uint256, bool) {
        return (price, valid);
    }
}

contract MockPositionManager {
    error NotImplemented();
    // Add minimal interface for integration
}

contract MockVault {
    error NotImplemented();
    // Add minimal interface for integration
} 