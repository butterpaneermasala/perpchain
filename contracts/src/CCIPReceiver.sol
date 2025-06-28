// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// Add missing interface for lending pool
interface ICrossChainLendingPool {
    // Define any required functions here, or leave empty if not used directly
}

interface ICrossChainVault {
    function depositFromCCIP(
        address user,
        address token,
        uint256 amount
    ) external;

    function withdrawToCCIP(
        address user,
        address token,
        uint256 amount
    ) external;

    function updateUserBalance(
        address user,
        address token,
        uint256 amount,
        bool isDeposit
    ) external;
}

interface IPerpetualTrading {
    function updatePositionFromCCIP(
        address user,
        bytes32 positionId,
        uint256 size,
        uint256 collateral,
        bool isLong,
        uint256 entryPrice
    ) external;

    function liquidatePositionFromCCIP(
        bytes32 positionId,
        address liquidator
    ) external;
}

/**
 * @title CrossChainReceiver
 * @dev Handles incoming cross-chain messages for the perpetual trading platform
 * @notice This contract receives and processes cross-chain asset transfers and position updates
 */
contract CrossChainReceiver is
    CCIPReceiver,
    ReentrancyGuard,
    Pausable,
    AccessControl
{
    using SafeERC20 for IERC20;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Message types
    enum MessageType {
        ASSET_DEPOSIT,
        ASSET_WITHDRAWAL,
        POSITION_UPDATE,
        POSITION_LIQUIDATION,
        EMERGENCY_STOP
    }

    // Structs for different message types
    struct AssetMessage {
        address user;
        address token;
        uint256 amount;
        uint256 nonce;
    }

    struct PositionMessage {
        address user;
        bytes32 positionId;
        uint256 size;
        uint256 collateral;
        bool isLong;
        uint256 entryPrice;
        uint256 nonce;
    }

    struct LiquidationMessage {
        bytes32 positionId;
        address liquidator;
        uint256 nonce;
    }

    // Contract interfaces
    ICrossChainVault public immutable vault;
    IPerpetualTrading public immutable perpetualTrading;
    ICrossChainLendingPool public lendingPool;

    // State variables
    mapping(uint64 => bool) public allowedSourceChains;
    mapping(address => bool) public allowedSenders;
    mapping(bytes32 => bool) public processedMessages;
    mapping(address => uint256) public userNonces;

    // Security constants
    uint256 public constant MAX_MESSAGE_AGE = 1 hours;
    uint256 public constant MIN_CONFIRMATION_DELAY = 10 minutes;

    // Events
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address indexed sender,
        MessageType messageType
    );

    event AssetProcessed(
        address indexed user,
        address indexed token,
        uint256 amount,
        bool isDeposit,
        uint256 nonce
    );

    event PositionUpdated(
        address indexed user,
        bytes32 indexed positionId,
        uint256 size,
        uint256 collateral,
        uint256 nonce
    );

    event PositionLiquidated(
        bytes32 indexed positionId,
        address indexed liquidator,
        uint256 nonce
    );

    event ChainAllowlistUpdated(uint64 chainSelector, bool allowed);
    event SenderAllowlistUpdated(address sender, bool allowed);

    // Errors
    error InvalidSourceChain(uint64 sourceChainSelector);
    error InvalidSender(address sender);
    error MessageAlreadyProcessed(bytes32 messageId);
    error InvalidMessageType();
    error InvalidNonce(uint256 expected, uint256 received);
    error InsufficientTokens(
        address token,
        uint256 required,
        uint256 available
    );
    error InvalidMessageData();
    error MessageTooOld();
    error ZeroAddress();

    /**
     * @dev Constructor
     * @param _router CCIP router address
     * @param _vault CrossChainVault contract address
     * @param _perpetualTrading PerpetualTrading contract address
     */
    constructor(
        address _router,
        address _vault,
        address _perpetualTrading,
        address _lendingPool
    ) CCIPReceiver(_router) {
        if (_vault == address(0)) revert ZeroAddress();
        if (_perpetualTrading == address(0)) revert ZeroAddress();

        vault = ICrossChainVault(_vault);
        perpetualTrading = IPerpetualTrading(_perpetualTrading);
        lendingPool = ICrossChainLendingPool(_lendingPool);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    //

    /**
     * @dev Receives and processes cross-chain messages
     * @param any2EvmMessage The CCIP message
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override nonReentrant whenNotPaused {
        // Validate source chain
        if (!allowedSourceChains[any2EvmMessage.sourceChainSelector]) {
            revert InvalidSourceChain(any2EvmMessage.sourceChainSelector);
        }

        // Validate sender
        address sender = abi.decode(any2EvmMessage.sender, (address));
        if (!allowedSenders[sender]) {
            revert InvalidSender(sender);
        }

        // Check for message replay
        bytes32 messageId = any2EvmMessage.messageId;
        if (processedMessages[messageId]) {
            revert MessageAlreadyProcessed(messageId);
        }

        // Mark message as processed immediately to prevent reentrancy
        processedMessages[messageId] = true;

        // Decode message type
        (MessageType messageType, bytes memory messageData) = abi.decode(
            any2EvmMessage.data,
            (MessageType, bytes)
        );

        // Process based on message type
        if (messageType == MessageType.ASSET_DEPOSIT) {
            _processAssetDeposit(messageData, any2EvmMessage.destTokenAmounts);
        } else if (messageType == MessageType.ASSET_WITHDRAWAL) {
            _processAssetWithdrawal(messageData);
        } else if (messageType == MessageType.POSITION_UPDATE) {
            _processPositionUpdate(messageData);
        } else if (messageType == MessageType.POSITION_LIQUIDATION) {
            _processPositionLiquidation(messageData);
        } else if (messageType == MessageType.EMERGENCY_STOP) {
            _processEmergencyStop();
        } else {
            revert InvalidMessageType();
        }

        emit MessageReceived(
            messageId,
            any2EvmMessage.sourceChainSelector,
            sender,
            messageType
        );
    }

    /**
     * @dev Processes asset deposit messages
     */
    function _processAssetDeposit(
        bytes memory messageData,
        Client.EVMTokenAmount[] memory tokenAmounts
    ) internal {
        AssetMessage memory assetMsg = abi.decode(messageData, (AssetMessage));

        // Validate nonce
        uint256 expectedNonce = userNonces[assetMsg.user] + 1;
        if (assetMsg.nonce != expectedNonce) {
            revert InvalidNonce(expectedNonce, assetMsg.nonce);
        }

        // Validate token amounts
        if (tokenAmounts.length != 1) {
            revert InvalidMessageData();
        }

        Client.EVMTokenAmount memory tokenAmount = tokenAmounts[0];
        if (
            tokenAmount.token != assetMsg.token ||
            tokenAmount.amount != assetMsg.amount
        ) {
            revert InvalidMessageData();
        }

        // Update user nonce before external call
        userNonces[assetMsg.user] = assetMsg.nonce;

        // Process deposit in vault
        vault.depositFromCCIP(assetMsg.user, assetMsg.token, assetMsg.amount);

        emit AssetProcessed(
            assetMsg.user,
            assetMsg.token,
            assetMsg.amount,
            true,
            assetMsg.nonce
        );
    }

    /**
     * @dev Processes asset withdrawal messages
     */
    function _processAssetWithdrawal(bytes memory messageData) internal {
        AssetMessage memory assetMsg = abi.decode(messageData, (AssetMessage));

        // Validate nonce
        uint256 expectedNonce = userNonces[assetMsg.user] + 1;
        if (assetMsg.nonce != expectedNonce) {
            revert InvalidNonce(expectedNonce, assetMsg.nonce);
        }

        // Update user nonce before external call
        userNonces[assetMsg.user] = assetMsg.nonce;

        // Process withdrawal from vault
        vault.withdrawToCCIP(assetMsg.user, assetMsg.token, assetMsg.amount);

        emit AssetProcessed(
            assetMsg.user,
            assetMsg.token,
            assetMsg.amount,
            false,
            assetMsg.nonce
        );
    }

    /**
     * @dev Processes position update messages
     */
    function _processPositionUpdate(bytes memory messageData) internal {
        PositionMessage memory posMsg = abi.decode(
            messageData,
            (PositionMessage)
        );

        // Validate nonce
        uint256 expectedNonce = userNonces[posMsg.user] + 1;
        if (posMsg.nonce != expectedNonce) {
            revert InvalidNonce(expectedNonce, posMsg.nonce);
        }

        // Update user nonce before external call
        userNonces[posMsg.user] = posMsg.nonce;

        // Update position in perpetual trading contract
        perpetualTrading.updatePositionFromCCIP(
            posMsg.user,
            posMsg.positionId,
            posMsg.size,
            posMsg.collateral,
            posMsg.isLong,
            posMsg.entryPrice
        );

        emit PositionUpdated(
            posMsg.user,
            posMsg.positionId,
            posMsg.size,
            posMsg.collateral,
            posMsg.nonce
        );
    }

    /**
     * @dev Processes position liquidation messages
     */
    function _processPositionLiquidation(bytes memory messageData) internal {
        LiquidationMessage memory liqMsg = abi.decode(
            messageData,
            (LiquidationMessage)
        );

        // Process liquidation
        perpetualTrading.liquidatePositionFromCCIP(
            liqMsg.positionId,
            liqMsg.liquidator
        );

        emit PositionLiquidated(
            liqMsg.positionId,
            liqMsg.liquidator,
            liqMsg.nonce
        );
    }

    /**
     * @dev Processes emergency stop messages
     */
    function _processEmergencyStop() internal {
        _pause();
    }

    /**
     * @dev Allows or disallows a source chain
     * @param chainSelector Chain selector to update
     * @param allowed Whether the chain is allowed
     */
    function setAllowedSourceChain(
        uint64 chainSelector,
        bool allowed
    ) external onlyRole(ADMIN_ROLE) {
        allowedSourceChains[chainSelector] = allowed;
        emit ChainAllowlistUpdated(chainSelector, allowed);
    }

    /**
     * @dev Allows or disallows a sender address
     * @param sender Sender address to update
     * @param allowed Whether the sender is allowed
     */
    function setAllowedSender(
        address sender,
        bool allowed
    ) external onlyRole(ADMIN_ROLE) {
        if (sender == address(0)) revert ZeroAddress();
        allowedSenders[sender] = allowed;
        emit SenderAllowlistUpdated(sender, allowed);
    }

    /**
     * @dev Pauses the contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Emergency token recovery
     * @param token Token address to recover
     * @param amount Amount to recover
     * @param to Address to send tokens to
     */
    function emergencyTokenRecovery(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(ADMIN_ROLE) {
        if (to == address(0)) revert ZeroAddress();
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Gets the current nonce for a user
     * @param user User address
     * @return Current nonce
     */
    function getUserNonce(address user) external view returns (uint256) {
        return userNonces[user];
    }

    /**
     * @dev Checks if a message has been processed
     * @param messageId Message ID to check
     * @return Whether the message has been processed
     */
    function isMessageProcessed(
        bytes32 messageId
    ) external view returns (bool) {
        return processedMessages[messageId];
    }

    /**
     * @dev Checks if a source chain is allowed
     * @param chainSelector Chain selector to check
     * @return Whether the chain is allowed
     */
    function isSourceChainAllowed(
        uint64 chainSelector
    ) external view returns (bool) {
        return allowedSourceChains[chainSelector];
    }

    /**
     * @dev Checks if a sender is allowed
     * @param sender Sender address to check
     * @return Whether the sender is allowed
     */
    function isSenderAllowed(address sender) external view returns (bool) {
        return allowedSenders[sender];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, CCIPReceiver) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            CCIPReceiver.supportsInterface(interfaceId);
    }
}
