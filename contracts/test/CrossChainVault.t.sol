// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CrossChainVault} from "../src/CrossChainVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract CrossChainVaultTest is Test {
    CrossChainVault vault;
    MockToken token;
    address user = address(0x123);

    function setUp() public {
        token = new MockToken();
        vault = new CrossChainVault(address(0x1));
        vault.addSupportedToken(address(token));
        token.transfer(user, 1000 ether);
        vm.startPrank(user);
        token.approve(address(vault), 1000 ether);
        vm.stopPrank();
    }

    function testDeposit() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        (uint256 totalDeposited,,) = vault.getUserBalanceInfo(user);
        assertEq(totalDeposited, 100 ether);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vault.withdraw(address(token), 50 ether);
        (,,uint256 locked) = vault.getUserBalanceInfo(user);
        assertEq(token.balanceOf(user), 950 ether);
        vm.stopPrank();
    }

    function testOnlySupportedToken() public {
        address fakeToken = address(0xdead);
        vm.startPrank(user);
        vm.expectRevert();
        vault.deposit(fakeToken, 10 ether);
        vm.stopPrank();
    }
}
