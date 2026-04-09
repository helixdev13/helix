// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { HelixLens } from "../src/periphery/HelixLens.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { MockClStrategy } from "../src/strategies/MockClStrategy.sol";

contract IntegrationFlowTest is Test {
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);

    function testEndToEndOperatorFlow() public {
        RiskEngine riskEngine = new RiskEngine(address(this));
        OracleRouter oracleRouter = new OracleRouter(address(this));
        VaultFactory factory = new VaultFactory(riskEngine, address(this));
        HelixLens lens = new HelixLens();

        MockERC20 asset = new MockERC20("Mock Asset", "MA", 18);
        MockOracle oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 days);

        HelixVault vault = factory.createVault(asset, address(this), GUARDIAN, "Helix Vault", "HLX");
        MockClStrategy strategy = new MockClStrategy(asset, address(vault));

        vault.setStrategy(strategy);
        riskEngine.setConfig(address(vault), 1_000_000e18, 8000, false, false);

        asset.mint(ALICE, 100e18);
        asset.mint(BOB, 50e18);

        vm.prank(ALICE);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(BOB);
        asset.approve(address(vault), type(uint256).max);

        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vm.prank(BOB);
        vault.deposit(50e18, BOB);

        vault.allocateToStrategy(90e18);
        asset.mint(address(strategy), 10e18);

        HelixLens.VaultView memory beforeLoss = lens.getVaultView(vault);
        assertEq(beforeLoss.totalAssets, 160e18);
        assertEq(beforeLoss.totalIdle, 60e18);
        assertEq(beforeLoss.totalStrategyAssets, 100e18);
        assertEq(beforeLoss.strategy, address(strategy));
        assertEq(beforeLoss.depositCap, 1_000_000e18);

        vm.prank(ALICE);
        vault.withdraw(40e18, ALICE, ALICE);

        assertEq(vault.totalAssets(), 120e18);

        deal(address(asset), address(strategy), 70e18, true);
        assertEq(vault.totalAssets(), 90e18);
        assertEq(vault.totalAssets(), vault.totalIdle() + vault.totalStrategyAssets());

        vm.prank(GUARDIAN);
        vault.emergencyPause();

        assertEq(vault.totalIdle(), 90e18);
        assertEq(vault.totalStrategyAssets(), 0);
        assertTrue(vault.withdrawOnly());

        uint256 bobShares = vault.balanceOf(BOB);
        vm.prank(BOB);
        uint256 bobAssets = vault.redeem(bobShares, BOB, BOB);

        uint256 aliceShares = vault.balanceOf(ALICE);
        vm.prank(ALICE);
        uint256 aliceAssets = vault.redeem(aliceShares, ALICE, ALICE);

        assertEq(bobAssets, 40e18);
        assertEq(aliceAssets, 50e18);
        assertEq(vault.totalAssets(), 0);
        assertEq(asset.balanceOf(ALICE), 90e18);
        assertEq(asset.balanceOf(BOB), 40e18);
    }
}
