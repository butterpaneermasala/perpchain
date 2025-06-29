// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {DataStreamOracle} from "../src/DataStreamOracle.sol";
import {CrossChainLendingPool} from "../src/LendingPool.sol";
import {CrossChainVault} from "../src/CrossChainVault.sol";
import {PerpetualTrading} from "../src/PerpetuaTrading.sol";
import {CrossChainReceiver} from "../src/CCIPReceiver.sol";
import {LiquidationEngine} from "../src/LiquidationEngine.sol";
import {PositionManager} from "../src/PositionManager.sol";
import {MockERC20} from "contracts/lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/forge-std/src/mocks/MockERC20.sol"; // Add mock token

contract DeployPerpetualTrading is Script {
    // Local Anvil environment addresses
    address constant ANVIL_CCIP_ROUTER =
        0x5FbDB2315678afecb367f032d93F642f64180aa3; // Anvil's first default address

    // Mock token contracts
    MockERC20 public usdc;
    MockERC20 public weth;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy mock tokens (USDC and WETH)
        usdc = new MockERC20("USD Coin", "USDC", 6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);

        // 2. Deploy Core Contracts
        DataStreamOracle oracle = new DataStreamOracle();
        CrossChainLendingPool lendingPool = new CrossChainLendingPool(
            ANVIL_CCIP_ROUTER
        );
        CrossChainVault vault = new CrossChainVault(ANVIL_CCIP_ROUTER);

        PerpetualTrading perpetual = new PerpetualTrading(
            deployer, // feeRecipient
            address(oracle),
            address(lendingPool)
        );

        CrossChainReceiver ccipReceiver = new CrossChainReceiver(
            ANVIL_CCIP_ROUTER,
            address(vault),
            address(perpetual),
            address(lendingPool)
        );

        PositionManager positionManager = new PositionManager(address(oracle));
        LiquidationEngine liquidationEngine = new LiquidationEngine(
            address(positionManager),
            address(oracle),
            address(vault),
            deployer // feeRecipient
        );

        // 3. Configure Contracts
        lendingPool.setCCIPReceiver(address(ccipReceiver));
        lendingPool.setPerpetualTrading(address(perpetual));

        vault.setAuthorizedCaller(address(ccipReceiver), true);
        vault.addSupportedToken(address(usdc));
        vault.addSupportedToken(address(weth));
        vault.addSupportedChain(1); // Local chain selector (dummy value)

        perpetual.setCCIPReceiver(address(ccipReceiver));
        perpetual.setLiquidationBot(address(liquidationEngine));

        positionManager.setLiquidationEngine(address(liquidationEngine));

        liquidationEngine.updateContracts(
            address(positionManager),
            address(oracle),
            address(vault)
        );

        // 4. Configure Markets
        // Add BTC/USD market
        bytes32 btcFeedId = keccak256(abi.encodePacked("BTC/USD"));
        perpetual.addMarket(btcFeedId, btcFeedId, 50, 5000); // maxLeverage=50, maintenanceMargin=5000

        // Add ETH/USD market
        bytes32 ethFeedId = keccak256(abi.encodePacked("ETH/USD"));
        perpetual.addMarket(ethFeedId, ethFeedId, 100, 3000);

        // Add collateral tokens
        perpetual.addSupportedToken(
            address(usdc),
            keccak256(abi.encodePacked("USDC/USD"))
        );
        perpetual.addSupportedToken(
            address(weth),
            keccak256(abi.encodePacked("ETH/USD"))
        );

        // 5. Configure Oracle with mock prices
        oracle.addFeed(
            "BTC/USD",
            "BTC/USD",
            8, // decimals
            300, // heartbeat (seconds)
            100, // deviation threshold (basis points)
            address(0) // No aggregator needed for local
        );
        oracle.addFeed(
            "ETH/USD",
            "ETH/USD",
            8, // decimals
            300, // heartbeat
            100, // deviation threshold
            address(0)
        );

        // Set initial prices
        oracle.emergencyUpdatePrice(
            btcFeedId,
            60_000 * 10 ** 8,
            block.timestamp
        );
        oracle.emergencyUpdatePrice(
            ethFeedId,
            3_000 * 10 ** 8,
            block.timestamp
        );
        oracle.setAuthorizedUpdater(deployer, true);

        vm.stopBroadcast();

        // Log deployed addresses
        console2.log("USDC deployed at:", address(usdc));
        console2.log("WETH deployed at:", address(weth));
        console2.log("DataStreamOracle deployed at:", address(oracle));
        console2.log("LendingPool deployed at:", address(lendingPool));
        console2.log("CrossChainVault deployed at:", address(vault));
        console2.log("PerpetualTrading deployed at:", address(perpetual));
        console2.log("CCIPReceiver deployed at:", address(ccipReceiver));
        console2.log("PositionManager deployed at:", address(positionManager));
        console2.log(
            "LiquidationEngine deployed at:",
            address(liquidationEngine)
        );
    }
}
