// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { ManagedClStrategy } from "../src/strategies/ManagedClStrategy.sol";
import { MockClAdapter } from "../src/adapters/MockClAdapter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Types } from "../src/libraries/Types.sol";

contract ManagedClIntegrationTest is Test {
    uint256 internal constant CAP = 1_000_000e18;

    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xBAD);

    MockERC20 internal asset;
    RiskEngine internal riskEngine;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    HelixVault internal vault;
    MockClAdapter internal adapter;
    ManagedClStrategy internal strategy;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        riskEngine = new RiskEngine(address(this));
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 days);

        vault = new HelixVault(asset, riskEngine, address(this), GUARDIAN, "Helix Vault", "HLX");
        adapter = new MockClAdapter(asset, 1 days);
        strategy = new ManagedClStrategy(
            asset, address(vault), adapter, oracleRouter, address(this), STRATEGIST, GUARDIAN
        );

        vault.setStrategy(strategy);
        riskEngine.setConfig(address(vault), CAP, 8000, false, false);

        asset.mint(ALICE, 1000e18);
        asset.mint(BOB, 1000e18);

        vm.prank(ALICE);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(BOB);
        asset.approve(address(vault), type(uint256).max);
    }

    function testVaultFlowWithManagedStrategySocializesLoss() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vm.prank(BOB);
        vault.deposit(100e18, BOB);

        vault.allocateToStrategy(160e18);

        Types.RebalanceIntent memory intent = _intent(160e18, 0, uint64(block.timestamp + 1 days));
        vm.prank(STRATEGIST);
        strategy.rebalance(
            intent, strategy.previewRebalance(intent), _limits(0, 0, intent.deadline)
        );

        deal(address(asset), address(adapter), 120e18, true);

        assertEq(vault.totalAssets(), 160e18);
        assertEq(vault.totalStrategyAssets(), 120e18);
        assertEq(vault.maxWithdraw(ALICE), 80e18);
        assertEq(vault.maxWithdraw(BOB), 80e18);

        vm.prank(ALICE);
        vault.withdraw(80e18, ALICE, ALICE);
        vm.prank(BOB);
        vault.withdraw(80e18, BOB, BOB);

        assertEq(asset.balanceOf(ALICE), 980e18);
        assertEq(asset.balanceOf(BOB), 980e18);
        assertEq(vault.totalAssets(), 0);
    }

    function testEmergencyPauseUnwindsManagedStrategyBackToVault() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);

        vault.allocateToStrategy(80e18);

        Types.RebalanceIntent memory intent = _intent(80e18, 0, uint64(block.timestamp + 1 days));
        vm.prank(STRATEGIST);
        strategy.rebalance(
            intent, strategy.previewRebalance(intent), _limits(0, 0, intent.deadline)
        );

        vm.prank(GUARDIAN);
        vault.emergencyPause();

        assertEq(asset.balanceOf(address(adapter)), 0);
        assertEq(strategy.totalIdle(), 0);
        assertEq(vault.totalIdle(), 100e18);
        assertEq(vault.totalStrategyAssets(), 0);
        assertTrue(vault.withdrawOnly());

        vm.prank(ALICE);
        vault.withdraw(100e18, ALICE, ALICE);

        assertEq(asset.balanceOf(ALICE), 1000e18);
        assertEq(vault.totalAssets(), 0);
    }

    function testHaircutDoesNotStrandAssetsOnFullExit() public {
        vm.prank(ALICE);
        uint256 shares = vault.deposit(100e18, ALICE);

        vault.allocateToStrategy(80e18);

        Types.RebalanceIntent memory intent = _intent(80e18, 0, uint64(block.timestamp + 1 days));
        vm.prank(STRATEGIST);
        strategy.rebalance(
            intent, strategy.previewRebalance(intent), _limits(0, 0, intent.deadline)
        );

        asset.mint(address(adapter), 10e18);
        vm.prank(address(strategy));
        adapter.setValuationHaircutBps(1000);

        assertEq(strategy.totalDeployedAssets(), 90e18);
        assertEq(strategy.totalAssets(), 90e18);
        assertEq(strategy.totalConservativeAssets(), 81e18);
        assertLt(strategy.totalConservativeAssets(), strategy.totalAssets());
        assertEq(vault.totalAssets(), 110e18);

        vm.prank(ALICE);
        uint256 assetsOut = vault.redeem(shares, ALICE, ALICE);

        assertEq(assetsOut, 110e18);
        assertEq(vault.totalAssets(), 0);
        assertEq(asset.balanceOf(address(vault)), 0);
        assertEq(asset.balanceOf(address(strategy)), 0);
        assertEq(asset.balanceOf(address(adapter)), 0);
        assertEq(asset.balanceOf(ALICE), 1010e18);
    }

    function _intent(
        uint256 assetsToDeploy,
        uint256 assetsToWithdraw,
        uint64 deadline
    ) internal pure returns (Types.RebalanceIntent memory) {
        return Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 2000,
            assetsToDeploy: assetsToDeploy,
            assetsToWithdraw: assetsToWithdraw,
            deadline: deadline
        });
    }

    function _limits(
        uint256 minAssetsOut,
        uint256 maxLoss,
        uint64 deadline
    ) internal pure returns (Types.ExecutionLimits memory) {
        return
            Types.ExecutionLimits({
                minAssetsOut: minAssetsOut, maxLoss: maxLoss, deadline: deadline
            });
    }
}
