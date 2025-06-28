// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, stdError} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {CrossChainVault} from "../../src/CrossChainVault.sol";
import {MockERC20, MockRouter} from "../utils/Mocks.sol";

contract CrossChainVault_Unit is Test {
    CrossChainVault internal vault;
    MockERC20 internal token;
    MockRouter internal router;
    address internal user = address(0x123);

    function setUp() public {
        token = new MockERC20("MockToken", "MTK");
        router = new MockRouter();
        vault = new CrossChainVault(address(router));
        vm.startPrank(address(this));
        vault.addSupportedToken(address(token));
        vault.addSupportedChain(1);
        vault.setAuthorizedCaller(address(this), true);
        vm.stopPrank();
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

    function _getLastTransferId() internal returns (bytes32) {
        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = entries.length; i > 0; i--) {
            Vm.Log memory entry = entries[i - 1];
            // keccak256("CrossChainTransferInitiated(bytes32,address,address,uint256,uint64)")
            if (entry.topics[0] == keccak256("CrossChainTransferInitiated(bytes32,address,address,uint256,uint64)")) {
                return bytes32(entry.topics[1]);
            }
        }
        revert("No CrossChainTransferInitiated event found");
    }

    function testInitiateCrossChainTransferLocksFunds() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vm.recordLogs();
        vault.initiateCrossChainTransfer{value: 0}(address(token), 60 ether, 1, address(0x456));
        bytes32 transferId = _getLastTransferId();
        (, uint256 available, uint256 locked) = vault.getUserBalanceInfo(user);
        assertEq(available, 40 ether);
        assertEq(locked, 60 ether);
        // Cannot withdraw locked funds
        vm.expectRevert();
        vault.withdraw(address(token), 50 ether);
        vm.stopPrank();
    }

    function testFinalizeCrossChainTransferUnlocksFunds() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vm.recordLogs();
        vault.initiateCrossChainTransfer{value: 0}(address(token), 60 ether, 1, address(0x456));
        bytes32 transferId = _getLastTransferId();
        vm.stopPrank();
        // Finalize as owner
        vm.startPrank(address(this));
        vault.finalizeCrossChainTransfer(transferId);
        vm.stopPrank();
        (, uint256 available, uint256 locked) = vault.getUserBalanceInfo(user);
        assertEq(locked, 0);
    }

    function testRevertCrossChainTransferReturnsFunds() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vm.recordLogs();
        vault.initiateCrossChainTransfer{value: 0}(address(token), 60 ether, 1, address(0x456));
        bytes32 transferId = _getLastTransferId();
        vm.stopPrank();
        // Revert as owner
        vm.startPrank(address(this));
        vault.revertCrossChainTransfer(transferId);
        vm.stopPrank();
        (, uint256 available, uint256 locked) = vault.getUserBalanceInfo(user);
        assertEq(available, 100 ether);
        assertEq(locked, 0);
    }

    function testCannotFinalizeOrRevertTwice() public {
        vm.startPrank(user);
        vault.deposit(address(token), 100 ether);
        vm.recordLogs();
        vault.initiateCrossChainTransfer{value: 0}(address(token), 60 ether, 1, address(0x456));
        bytes32 transferId = _getLastTransferId();
        vm.stopPrank();
        vm.startPrank(address(this));
        vault.finalizeCrossChainTransfer(transferId);
        vm.expectRevert();
        vault.finalizeCrossChainTransfer(transferId);
        vm.expectRevert();
        vault.revertCrossChainTransfer(transferId);
        vm.stopPrank();
    }
} 