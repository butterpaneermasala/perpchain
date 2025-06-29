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

contract DeployPerpetualTrading is Script {
    // Chainlink CCIP Router Addresses
    address constant SEPOLIA_CCIP_ROUTER =
        0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address constant MUMBAI_CCIP_ROUTER =
        0x1035CabC275068e0F4b745A29CEDf38E13aF41b1;

    // Testnet token addresses (example)
    address constant USDC_TESTNET = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address constant WETH_TESTNET = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Core Contracts
        DataStreamOracle oracle = new DataStreamOracle();
        CrossChainLendingPool lendingPool = new CrossChainLendingPool(SEPOLIA_CCIP_ROUTER);
        CrossChainVault vault = new CrossChainVault(SEPOLIA_CCIP_ROUTER);

        PerpetualTrading perpetual = new PerpetualTrading(
            deployer, // feeRecipient
            address(oracle),
            address(lendingPool)
        );

        CrossChainReceiver ccipReceiver = new CrossChainReceiver(
            SEPOLIA_CCIP_ROUTER,
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

        // 2. Configure Contracts
        // Set critical addresses
        lendingPool.setCCIPReceiver(address(ccipReceiver));
        lendingPool.setPerpetualTrading(address(perpetual));

        vault.setAuthorizedCaller(address(ccipReceiver), true);
        vault.addSupportedToken(USDC_TESTNET);
        vault.addSupportedToken(WETH_TESTNET);
        vault.addSupportedChain(16015286601757825753); // Arbitrum Sepolia chain selector

        perpetual.setCCIPReceiver(address(ccipReceiver));
        perpetual.setLiquidationBot(address(liquidationEngine));

        positionManager.setLiquidationEngine(address(liquidationEngine));

        liquidationEngine.updateContracts(
            address(positionManager),
            address(oracle),
            address(vault)
        );

        // 3. Configure Markets
        // Add BTC/USD market
        bytes32 btcFeedId = keccak256(abi.encodePacked("BTC/USD"));
        perpetual.addMarket(btcFeedId, btcFeedId, 50, 5000); // maxLeverage=50, maintenanceMargin=5000

        // Add ETH/USD market
        bytes32 ethFeedId = keccak256(abi.encodePacked("ETH/USD"));
        perpetual.addMarket(ethFeedId, ethFeedId, 100, 3000);

        // Add collateral tokens
        perpetual.addSupportedToken(
            USDC_TESTNET,
            keccak256(abi.encodePacked("USDC/USD"))
        );
        perpetual.addSupportedToken(
            WETH_TESTNET,
            keccak256(abi.encodePacked("ETH/USD"))
        );

        // 4. Configure Oracle
        oracle.addFeed(
            "BTC/USD",
            "BTC/USD",
            8, // decimals
            300, // heartbeat (seconds)
            100, // deviation threshold (basis points)
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43 // BTC/USD Sepolia feed
        );

        oracle.setAuthorizedUpdater(deployer, true);

        vm.stopBroadcast();

        // Log deployed addresses
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