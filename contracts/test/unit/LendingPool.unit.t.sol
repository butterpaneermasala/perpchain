// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {CrossChainLendingPool} from "../../src/LendingPool.sol";
import {MockERC20} from "../utils/Mocks.sol";

contract LendingPoolFactory {
    function deploy(address arg) external returns (address) {
        return address(new CrossChainLendingPool(arg));
    }

    function deployAndTransfer(
        address arg,
        address newOwner
    ) external returns (address) {
        CrossChainLendingPool pool = new CrossChainLendingPool(arg);
        pool.transferOwnership(newOwner);
        return address(pool);
    }
}

contract LendingPool_Unit is Test {
    CrossChainLendingPool internal pool;
    MockERC20 internal token;
    address internal testOwner;
    address internal ccipReceiver = address(0x1234);
    address internal perp = address(0xDEAD);
    address internal user = address(0xBEEF);
    bytes32 internal messageId = keccak256("msg1");

    function setUp() public {
        testOwner = makeAddr("testOwner");
        LendingPoolFactory factory = new LendingPoolFactory();
        address poolAddr = factory.deployAndTransfer(address(0x1), testOwner);
        pool = CrossChainLendingPool(payable(poolAddr));
        assertEq(pool.owner(), testOwner, "Owner not set");

        vm.startPrank(testOwner);
        token = new MockERC20("MockToken", "MTK");
        token.mint(address(pool), 1000 ether);
        pool.addSupportedToken(address(token), 500);
        pool.setCCIPReceiver(ccipReceiver);
        pool.setPerpetualTrading(perp);
        token.mint(testOwner, 1000 ether);
        token.approve(address(pool), 1000 ether);
        vm.stopPrank(); // End testOwner context

        // FIX: Call as CCIP receiver
        vm.prank(ccipReceiver);
        pool.finalizeCrossChainDeposit(
            testOwner,
            address(token),
            1000 ether,
            keccak256("setup")
        );

        // Ensure pool has real balance
        vm.prank(testOwner);
        token.transfer(address(pool), 1000 ether);
    }

    function testOnlyCCIPReceiverCanFinalizeDeposit() public {
        // Give pool enough tokens for the test
        token.mint(address(pool), 100 ether);
        vm.prank(ccipReceiver);
        pool.finalizeCrossChainDeposit(
            user,
            address(token),
            100 ether,
            messageId
        );
        vm.expectRevert();
        pool.finalizeCrossChainDeposit(
            user,
            address(token),
            100 ether,
            keccak256("msg2")
        );
    }

    function testReplayProtectionDeposit() public {
        token.mint(address(pool), 100 ether);
        vm.prank(ccipReceiver);
        pool.finalizeCrossChainDeposit(
            user,
            address(token),
            100 ether,
            messageId
        );
        vm.prank(ccipReceiver);
        vm.expectRevert();
        pool.finalizeCrossChainDeposit(
            user,
            address(token),
            100 ether,
            messageId
        );
    }

    function testOnlyCCIPReceiverCanFinalizeWithdrawal() public {
        // Give pool enough tokens for withdrawal
        token.mint(address(pool), 50 ether);
        vm.prank(ccipReceiver);
        pool.finalizeCrossChainWithdrawal(
            user,
            address(token),
            50 ether,
            messageId
        );
        vm.expectRevert();
        pool.finalizeCrossChainWithdrawal(
            user,
            address(token),
            50 ether,
            keccak256("msg2")
        );
    }

    function testReplayProtectionWithdrawal() public {
        token.mint(address(pool), 50 ether);
        vm.prank(ccipReceiver);
        pool.finalizeCrossChainWithdrawal(
            user,
            address(token),
            50 ether,
            messageId
        );
        vm.prank(ccipReceiver);
        vm.expectRevert();
        pool.finalizeCrossChainWithdrawal(
            user,
            address(token),
            50 ether,
            messageId
        );
    }

    function testOnlyPerpetualTradingCanBorrow() public {
        // Give pool enough tokens for borrowing
        token.mint(address(pool), 10 ether);
        vm.prank(perp);
        pool.borrow(address(token), 10 ether);
        vm.prank(user);
        vm.expectRevert();
        pool.borrow(address(token), 10 ether);
    }

    function testOnlyPerpetualTradingCanRepay() public {
        token.mint(address(pool), 10 ether);

        // Borrow as perpetual trading contract
        vm.prank(perp);
        pool.borrow(address(token), 10 ether);

        // Mint and approve tokens from perpetual trading contract's perspective
        token.mint(perp, 10 ether);
        vm.prank(perp);
        token.approve(address(pool), 10 ether);

        // Repay as perpetual trading contract
        vm.prank(perp);
        pool.repay(address(token), 10 ether); // Should succeed

        // Attempt repay as user (should fail)
        vm.prank(user);
        vm.expectRevert();
        pool.repay(address(token), 10 ether);
    }
}
