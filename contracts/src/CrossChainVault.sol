// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

/**
 * @title CrossChainVault
 * @dev Manages user assets across multiple blockchains using Chainlink CCIP
 */
contract CrossChainVault is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ============ STRUCTS ============

    struct UserBalance {
        uint256 totalDeposited;
        uint256 availableBalance;
        uint256 lockedBalance;
        mapping(address => uint256) tokenBalances;
    }

    struct CrossChainTransfer {
        bytes32 transferId;
        address user;
        address token;
        uint256 amount;
        uint64 destinationChainSelector;
        bool completed;
        uint256 timestamp;
    }

    // ============ STATE VARIABLES ============

    IRouterClient public router;
    mapping(address => UserBalance) public userBalances;
    mapping(bytes32 => CrossChainTransfer) public crossChainTransfers;
    mapping(address => bool) public supportedTokens;
    mapping(uint64 => bool) public supportedChains;
    mapping(address => bool) public authorizedCallers;

    // Security constants
    uint256 public constant MAX_TRANSFER_AMOUNT = 1000000 * 1e18; // 1M tokens max
    uint256 public constant MIN_TRANSFER_AMOUNT = 1e18; // 1 token min
    uint256 public constant TRANSFER_TIMEOUT = 24 hours;

    // ============ CONSTRUCTOR ============

    constructor(address _router) Ownable(msg.sender) {
        require(_router != address(0), "Invalid router address");
        router = IRouterClient(_router);
    }

    // ============ EVENTS ============

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event CrossChainTransferInitiated(
        bytes32 indexed transferId,
        address indexed user,
        address token,
        uint256 amount,
        uint64 destinationChainSelector
    );
    event CrossChainTransferCompleted(
        bytes32 indexed transferId,
        address indexed user,
        address token,
        uint256 amount
    );
    event CrossChainTransferReverted(
        bytes32 indexed transferId,
        address indexed user,
        address token,
        uint256 amount
    );

    // ============ MODIFIERS ============

    modifier onlySupportedToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }

    modifier onlySupportedChain(uint64 chainSelector) {
        require(supportedChains[chainSelector], "Chain not supported");
        _;
    }

    modifier onlyAuthorizedCaller() {
        require(
            authorizedCallers[msg.sender] || msg.sender == owner(),
            "Not authorized"
        );
        _;
    }

    // ============ CORE FUNCTIONS ============

    /**
     * @dev Deposit tokens into the vault
     * @param token Token address to deposit
     * @param amount Amount to deposit
     */
    function deposit(
        address token,
        uint256 amount
    ) external nonReentrant whenNotPaused onlySupportedToken(token) {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= MAX_TRANSFER_AMOUNT, "Amount exceeds maximum");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // FIX: Update userBalances mapping
        UserBalance storage balance = userBalances[msg.sender];
        balance.totalDeposited += amount;
        balance.availableBalance += amount;
        balance.tokenBalances[token] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(
        address token,
        uint256 amount
    ) external nonReentrant whenNotPaused onlySupportedToken(token) {
        require(amount > 0, "Amount must be greater than 0");
        UserBalance storage balance = userBalances[msg.sender];
        require(
            balance.availableBalance >= amount,
            "Insufficient available balance"
        );
        require(
            balance.tokenBalances[token] >= amount,
            "Insufficient token balance"
        );

        // FIX: Update balances BEFORE transfer
        balance.totalDeposited -= amount;
        balance.availableBalance -= amount;
        balance.tokenBalances[token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, token, amount);
    }

    /**
     * @dev Initiate cross-chain transfer
     * @param token Token address to transfer
     * @param amount Amount to transfer
     * @param destinationChainSelector Destination chain selector
     * @param receiver Receiver address on destination chain
     */
    function initiateCrossChainTransfer(
        address token,
        uint256 amount,
        uint64 destinationChainSelector,
        address receiver
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlySupportedToken(token)
        onlySupportedChain(destinationChainSelector)
    {
        require(amount >= MIN_TRANSFER_AMOUNT, "Amount below minimum");
        require(amount <= MAX_TRANSFER_AMOUNT, "Amount exceeds maximum");
        require(receiver != address(0), "Invalid receiver address");

        UserBalance storage balance = userBalances[msg.sender];
        require(
            balance.availableBalance >= amount,
            "Insufficient available balance"
        );
        require(
            balance.tokenBalances[token] >= amount,
            "Insufficient token balance"
        );

        // Lock user's balance before external call
        balance.availableBalance -= amount;
        balance.lockedBalance += amount;
        balance.tokenBalances[token] -= amount;

        // Create transfer record
        bytes32 transferId = keccak256(
            abi.encodePacked(
                msg.sender,
                token,
                amount,
                destinationChainSelector,
                block.timestamp,
                block.number
            )
        );

        crossChainTransfers[transferId] = CrossChainTransfer({
            transferId: transferId,
            user: msg.sender,
            token: token,
            amount: amount,
            destinationChainSelector: destinationChainSelector,
            completed: false,
            timestamp: block.timestamp
        });

        // Prepare CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(msg.sender, token, amount),
            tokenAmounts: new Client.EVMTokenAmount[](1),
            extraArgs: "",
            feeToken: address(0)
        });

        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: token,
            amount: amount
        });

        // Calculate and check fee
        uint256 fee = router.getFee(destinationChainSelector, message);
        require(msg.value >= fee, "Insufficient fee");

        // Send CCIP message
        router.ccipSend{value: fee}(destinationChainSelector, message);

        // Refund excess fee
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }

        emit CrossChainTransferInitiated(
            transferId,
            msg.sender,
            token,
            amount,
            destinationChainSelector
        );
    }

    /**
     * @dev Finalize a cross-chain transfer (called by authorized caller)
     * @param transferId The transfer ID
     */
    function finalizeCrossChainTransfer(
        bytes32 transferId
    ) external onlyAuthorizedCaller {
        CrossChainTransfer storage transfer = crossChainTransfers[transferId];
        require(!transfer.completed, "Transfer already completed");
        require(transfer.user != address(0), "Invalid transfer");

        UserBalance storage balance = userBalances[transfer.user];
        require(
            balance.lockedBalance >= transfer.amount,
            "Insufficient locked balance"
        );

        balance.lockedBalance -= transfer.amount;
        transfer.completed = true;

        emit CrossChainTransferCompleted(
            transferId,
            transfer.user,
            transfer.token,
            transfer.amount
        );
    }

    /**
     * @dev Revert a cross-chain transfer (in case of failure)
     * @param transferId The transfer ID
     */
    function revertCrossChainTransfer(
        bytes32 transferId
    ) external onlyAuthorizedCaller {
        CrossChainTransfer storage transfer = crossChainTransfers[transferId];
        require(!transfer.completed, "Transfer already completed");
        require(transfer.user != address(0), "Invalid transfer");

        UserBalance storage balance = userBalances[transfer.user];
        require(
            balance.lockedBalance >= transfer.amount,
            "Insufficient locked balance"
        );

        balance.lockedBalance -= transfer.amount;
        balance.availableBalance += transfer.amount;
        balance.tokenBalances[transfer.token] += transfer.amount;
        transfer.completed = true;

        emit CrossChainTransferReverted(
            transferId,
            transfer.user,
            transfer.token,
            transfer.amount
        );
    }

    /**
     * @dev Deposit from CCIP (called by authorized caller)
     */
    function depositFromCCIP(
        address user,
        address token,
        uint256 amount
    ) external onlyAuthorizedCaller onlySupportedToken(token) {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");

        UserBalance storage balance = userBalances[user];
        balance.totalDeposited += amount;
        balance.availableBalance += amount;
        balance.tokenBalances[token] += amount;

        emit Deposit(user, token, amount);
    }

    /**
     * @dev Withdraw to CCIP (called by authorized caller)
     */
    function withdrawToCCIP(
        address user,
        address token,
        uint256 amount
    ) external onlyAuthorizedCaller onlySupportedToken(token) {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");

        UserBalance storage balance = userBalances[user];
        require(
            balance.availableBalance >= amount,
            "Insufficient available balance"
        );
        require(
            balance.tokenBalances[token] >= amount,
            "Insufficient token balance"
        );

        balance.totalDeposited -= amount;
        balance.availableBalance -= amount;
        balance.tokenBalances[token] -= amount;

        IERC20(token).safeTransfer(user, amount);

        emit Withdraw(user, token, amount);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @dev Get user's token balance
     * @param user User address
     * @param token Token address
     * @return balance User's token balance
     */
    function getUserTokenBalance(
        address user,
        address token
    ) external view returns (uint256 balance) {
        return userBalances[user].tokenBalances[token];
    }

    /**
     * @dev Get user's total balance info
     * @param user User address
     * @return totalDeposited Total amount deposited
     * @return availableBalance Available balance
     * @return lockedBalance Locked balance
     */
    function getUserBalanceInfo(
        address user
    )
        external
        view
        returns (
            uint256 totalDeposited,
            uint256 availableBalance,
            uint256 lockedBalance
        )
    {
        UserBalance storage balance = userBalances[user];
        return (
            balance.totalDeposited,
            balance.availableBalance,
            balance.lockedBalance
        );
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @dev Add supported token
     * @param token Token address
     */
    function addSupportedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        supportedTokens[token] = true;
    }

    /**
     * @dev Remove supported token
     * @param token Token address
     */
    function removeSupportedToken(address token) external onlyOwner {
        supportedTokens[token] = false;
    }

    /**
     * @dev Add supported chain
     * @param chainSelector Chain selector
     */
    function addSupportedChain(uint64 chainSelector) external onlyOwner {
        require(chainSelector != 0, "Invalid chain selector");
        supportedChains[chainSelector] = true;
    }

    /**
     * @dev Remove supported chain
     * @param chainSelector Chain selector
     */
    function removeSupportedChain(uint64 chainSelector) external onlyOwner {
        supportedChains[chainSelector] = false;
    }

    /**
     * @dev Update router address
     * @param _router New router address
     */
    function updateRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router address");
        router = IRouterClient(_router);
    }

    /**
     * @dev Set authorized caller
     * @param caller Caller address
     * @param authorized Whether the caller is authorized
     */
    function setAuthorizedCaller(
        address caller,
        bool authorized
    ) external onlyOwner {
        require(caller != address(0), "Invalid caller address");
        authorizedCallers[caller] = authorized;
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency withdraw
     */
    function emergencyWithdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Receive function to accept ETH for CCIP fees
     */
    receive() external payable {}
}
