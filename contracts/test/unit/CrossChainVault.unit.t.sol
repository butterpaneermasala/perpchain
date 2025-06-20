// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, stdError} from "forge-std/Test.sol";
import {CrossChainVault} from "../../src/CrossChainVault.sol";
import {MockERC20} from "../utils/Mocks.sol";

contract CrossChainVault_Unit is Test {
    CrossChainVault internal vault;
    MockERC20 internal token;
    address internal user = address(0x123);

    function setUp() public {
        token = new MockERC20("MockToken", "MTK");
        vault = new CrossChainVault(address(0x1));
        vault.addSupportedToken(address(token));
        token.mint(user, 1000 ether);
        vm.startPrank(user);
        token.approve(address(vault), 1000 ether);
        vm.stopPrank();
    }

    function testDepositEmitsEvent() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit CrossChainVault.Deposit(user, address(token), 100 ether);
        vault.deposit(address(token), 100 ether);
        vm.stopPrank();
    }

    function testDepositUpdatesBalance() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        (uint256 totalDeposited,,) = vault.getUserBalanceInfo(user);
        assertEq(totalDeposited, 100 ether);
        vm.stopPrank();
    }

    function testWithdrawUpdatesBalance() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vault.withdraw(address(token), 50 ether);
        (uint256 totalDeposited,,) = vault.getUserBalanceInfo(user);
        assertEq(totalDeposited, 50 ether);
        vm.stopPrank();
    }

    function testOnlySupportedTokenReverts() public {
        address fakeToken = address(0xdead);
        vm.startPrank(user);
        vm.expectRevert();
        vault.deposit(fakeToken, 10 ether);
        vm.stopPrank();
    }

    function testWithdrawRevertsIfInsufficientBalance() public {
        vm.startPrank(user);
        vault.deposit(address(token), 10 ether);
        vm.expectRevert();
        vault.withdraw(address(token), 20 ether);
        vm.stopPrank();
    }
} 