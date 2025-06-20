// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {LiquidationEngine} from "../../src/LiquidationEngine.sol";
import {MockPositionManager, MockOracle, MockVault} from "../utils/Mocks.sol";

contract LiquidationEngine_Unit is Test {
    LiquidationEngine internal engine;
    MockPositionManager internal positionManager;
    MockOracle internal oracle;
    MockVault internal vault;
    address internal owner = address(this);
    address internal feeRecipient = address(0xFEE);

    function setUp() public {
        positionManager = new MockPositionManager();
        oracle = new MockOracle();
        vault = new MockVault();
        engine = new LiquidationEngine(address(positionManager), address(oracle), address(vault), feeRecipient);
    }

    function testConstructorSetsState() public {
        assertEq(address(engine.positionManager()), address(positionManager));
        assertEq(address(engine.oracle()), address(oracle));
        assertEq(address(engine.vault()), address(vault));
        assertEq(engine.feeRecipient(), feeRecipient);
    }

    function testSetLiquidationInterval() public {
        engine.setLiquidationInterval(60);
        assertEq(engine.liquidationInterval(), 60);
    }

    function testSetMaxPositionsPerCheck() public {
        engine.setMaxPositionsPerCheck(100);
        assertEq(engine.maxPositionsPerCheck(), 100);
    }

    function testSetLiquidationFee() public {
        engine.setLiquidationFee(200);
        assertEq(engine.liquidationFee(), 200);
    }

    function testSetFeeRecipient() public {
        address newRecipient = address(0xBEEF);
        engine.setFeeRecipient(newRecipient);
        assertEq(engine.feeRecipient(), newRecipient);
    }

    function testToggleEmergencyMode() public {
        bool before = engine.emergencyMode();
        engine.toggleEmergencyMode();
        assertEq(engine.emergencyMode(), !before);
    }
} 