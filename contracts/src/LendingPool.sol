// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

contract CrossChainLendingPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct PoolInfo {
        uint256 totalDeposits;
        uint256 totalBorrows;
        uint256 totalInterest;
        uint256 lastInterestUpdate;
        uint256 interestRate; // Annualized in basis points (500 = 5%)
    }

    // CCIP Router for cross-chain messaging
    IRouterClient public ccipRouter;
    address public ccipReceiver;
    address public perpetualTrading;

    mapping(address => PoolInfo) public pools;
    mapping(address => mapping(address => uint256)) public userDeposits;
    mapping(bytes32 => bool) public processedMessages;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event Borrow(address indexed trader, address indexed token, uint256 amount);
    event Repay(
        address indexed trader,
        address indexed token,
        uint256 amount,
        uint256 interest
    );
    event CrossChainDepositInitiated(
        address indexed user,
        address token,
        uint256 amount,
        uint64 destinationChain
    );
    event CrossChainWithdrawInitiated(
        address indexed user,
        address token,
        uint256 amount,
        uint64 sourceChain
    );

    modifier onlySupportedToken(address token) {
        require(pools[token].interestRate > 0, "Token not supported");
        _;
    }

    modifier onlyCCIPReceiver() {
        require(msg.sender == ccipReceiver, "Not authorized");
        _;
    }
    modifier onlyPerpetualTrading() {
        require(msg.sender == perpetualTrading, "Not authorized");
        _;
    }

    constructor(address _ccipRouter) Ownable(msg.sender) {
        ccipRouter = IRouterClient(_ccipRouter);
    }

    // ========== CCIP Configuration ==========
    function setCCIPReceiver(address _receiver) external onlyOwner {
        ccipReceiver = _receiver;
    }

    function setPerpetualTrading(address _perp) external onlyOwner {
        perpetualTrading = _perp;
    }

    // ========== Cross-Chain Deposit ==========
    function initiateCrossChainDeposit(
        uint64 destinationChainSelector,
        address token,
        uint256 amount
    ) external payable nonReentrant onlySupportedToken(token) {
        require(amount > 0, "Amount must be > 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Build CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(ccipReceiver),
            data: abi.encode(msg.sender, token, amount, "DEPOSIT"),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        // Pay CCIP fees
        uint256 fee = ccipRouter.getFee(destinationChainSelector, message);
        require(msg.value >= fee, "Insufficient CCIP fee");

        // Send message
        bytes32 messageId = ccipRouter.ccipSend{value: fee}(
            destinationChainSelector,
            message
        );

        emit CrossChainDepositInitiated(
            msg.sender,
            token,
            amount,
            destinationChainSelector
        );
    }

    // Called by CCIP Receiver on destination chain
    function finalizeCrossChainDeposit(
        address user,
        address token,
        uint256 amount,
        bytes32 messageId
    ) external onlySupportedToken(token) onlyCCIPReceiver {
        require(!processedMessages[messageId], "Message already processed");
        processedMessages[messageId] = true;
        pools[token].totalDeposits += amount;
        userDeposits[user][token] += amount;
        emit Deposit(user, token, amount);
    }

    // ========== Cross-Chain Withdrawal ==========
    function initiateCrossChainWithdrawal(
        uint64 sourceChainSelector,
        address token,
        uint256 amount
    ) external payable nonReentrant onlySupportedToken(token) {
        require(
            userDeposits[msg.sender][token] >= amount,
            "Insufficient deposit"
        );
        _updateInterest(token);
        userDeposits[msg.sender][token] -= amount;
        pools[token].totalDeposits -= amount;

        // Build CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(ccipReceiver),
            data: abi.encode(msg.sender, token, amount, "WITHDRAW"),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        // Pay CCIP fees
        uint256 fee = ccipRouter.getFee(sourceChainSelector, message);
        require(msg.value >= fee, "Insufficient CCIP fee");

        // Send message
        bytes32 messageId = ccipRouter.ccipSend{value: fee}(
            sourceChainSelector,
            message
        );

        emit CrossChainWithdrawInitiated(
            msg.sender,
            token,
            amount,
            sourceChainSelector
        );
    }

    // Called by CCIP Receiver on source chain
    function finalizeCrossChainWithdrawal(
        address user,
        address token,
        uint256 amount,
        bytes32 messageId
    ) external onlySupportedToken(token) onlyCCIPReceiver {
        require(!processedMessages[messageId], "Message already processed");
        processedMessages[messageId] = true;
        IERC20(token).safeTransfer(user, amount);
        emit Withdraw(user, token, amount);
    }

    // ========== Core Lending Logic ==========
    function addSupportedToken(
        address token,
        uint256 interestRate
    ) external onlyOwner {
        require(interestRate > 0, "Interest rate must be positive");
        pools[token] = PoolInfo({
            totalDeposits: 0,
            totalBorrows: 0,
            totalInterest: 0,
            lastInterestUpdate: block.timestamp,
            interestRate: interestRate
        });
    }

    function borrow(
        address token,
        uint256 amount
    ) external onlyPerpetualTrading onlySupportedToken(token) {
        require(amount > 0, "Amount must be > 0");
        require(
            pools[token].totalDeposits - pools[token].totalBorrows >= amount,
            "Insufficient liquidity"
        );
        _updateInterest(token);
        pools[token].totalBorrows += amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, token, amount);
    }

    function repay(
        address token,
        uint256 amount
    ) external onlyPerpetualTrading onlySupportedToken(token) {
        require(amount > 0, "Amount must be > 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _updateInterest(token);
        uint256 interest = (amount * pools[token].interestRate) / 10000 / 365;
        pools[token].totalBorrows -= amount;
        pools[token].totalInterest += interest;
        emit Repay(msg.sender, token, amount, interest);
    }

    // ========== Internal Functions ==========
    function _updateInterest(address token) internal {
        PoolInfo storage pool = pools[token];
        uint256 timeElapsed = block.timestamp - pool.lastInterestUpdate;
        if (timeElapsed > 0 && pool.totalBorrows > 0) {
            uint256 accrued = (pool.totalBorrows *
                pool.interestRate *
                timeElapsed) / (10000 * 365 days);
            pool.totalInterest += accrued;
            pool.lastInterestUpdate = block.timestamp;
        }
    }

    // ========== View Functions ==========
    function getAvailableLiquidity(
        address token
    ) external view returns (uint256) {
        return pools[token].totalDeposits - pools[token].totalBorrows;
    }

    function getUserDeposit(
        address user,
        address token
    ) external view returns (uint256) {
        return userDeposits[user][token];
    }
}
