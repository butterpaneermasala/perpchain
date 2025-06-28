// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MockERC20} from "../test/utils/Mocks.sol";
import {Script} from "forge-std/Script.sol";
 
contract Helpers is Script {
    function fund(address to, uint256 amount, MockERC20 token) public {
        token.mint(to, amount);
    }
} 