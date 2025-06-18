// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

/**
 * @title CrossChainVault
 * @dev Manages user assets across multiple blockchains using Chainlink CCIP
 */
contract CrossChainVault is ReentrancyGuard, Ownable {
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
    }
    
    // ============ STATE VARIABLES ============
    
    IRouterClient public router;
    mapping(address => UserBalance) public userBalances;
    mapping(bytes32 => CrossChainTransfer) public crossChainTransfers;
    mapping(address => bool) public supportedTokens;
    mapping(uint64 => bool) public supportedChains;
    
    // ============ CONSTRUCTOR ============
    
    constructor(address _router) Ownable(msg.sender) {
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
    
    // ============ MODIFIERS ============
    
    modifier onlySupportedToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }
    
    modifier onlySupportedChain(uint64 chainSelector) {
        require(supportedChains[chainSelector], "Chain not supported");
        _;
    }
    
    // ============ CORE FUNCTIONS ============
    
    /**
     * @dev Deposit tokens into the vault
     * @param token Token address to deposit
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount) 
        external 
        nonReentrant 
        onlySupportedToken(token) 
    {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from user to vault
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Update user balance
        UserBalance storage balance = userBalances[msg.sender];
        balance.totalDeposited += amount;
        balance.availableBalance += amount;
        balance.tokenBalances[token] += amount;
        
        emit Deposit(msg.sender, token, amount);
    }
    
    /**
     * @dev Withdraw tokens from the vault
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function withdraw(address token, uint256 amount) 
        external 
        nonReentrant 
        onlySupportedToken(token) 
    {
        require(amount > 0, "Amount must be greater than 0");
        
        UserBalance storage balance = userBalances[msg.sender];
        require(balance.availableBalance >= amount, "Insufficient available balance");
        require(balance.tokenBalances[token] >= amount, "Insufficient token balance");
        
        // Update user balance
        balance.totalDeposited -= amount;
        balance.availableBalance -= amount;
        balance.tokenBalances[token] -= amount;
        
        // Transfer tokens to user
        IERC20(token).transfer(msg.sender, amount);
        
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
        nonReentrant 
        onlySupportedToken(token)
        onlySupportedChain(destinationChainSelector)
    {
        require(amount > 0, "Amount must be greater than 0");
        
        UserBalance storage balance = userBalances[msg.sender];
        require(balance.availableBalance >= amount, "Insufficient available balance");
        require(balance.tokenBalances[token] >= amount, "Insufficient token balance");
        
        // Lock user's balance
        balance.availableBalance -= amount;
        balance.lockedBalance += amount;
        balance.tokenBalances[token] -= amount;
        
        // Create transfer record
        bytes32 transferId = keccak256(abi.encodePacked(
            msg.sender,
            token,
            amount,
            destinationChainSelector,
            block.timestamp
        ));
        
        crossChainTransfers[transferId] = CrossChainTransfer({
            transferId: transferId,
            user: msg.sender,
            token: token,
            amount: amount,
            destinationChainSelector: destinationChainSelector,
            completed: false
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
        
        // Send CCIP message
        router.ccipSend(destinationChainSelector, message);
        
        emit CrossChainTransferInitiated(
            transferId,
            msg.sender,
            token,
            amount,
            destinationChainSelector
        );
    }
    
    // ============ VIEW FUNCTIONS ============
    
    /**
     * @dev Get user's token balance
     * @param user User address
     * @param token Token address
     * @return balance User's token balance
     */
    function getUserTokenBalance(address user, address token) 
        external 
        view 
        returns (uint256 balance) 
    {
        return userBalances[user].tokenBalances[token];
    }
    
    /**
     * @dev Get user's total balance info
     * @param user User address
     * @return totalDeposited Total amount deposited
     * @return availableBalance Available balance
     * @return lockedBalance Locked balance
     */
    function getUserBalanceInfo(address user) 
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
        router = IRouterClient(_router);
    }
} 