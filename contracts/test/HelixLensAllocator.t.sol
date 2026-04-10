// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { HelixLens } from "../src/periphery/HelixLens.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { MockAllocatorAdapter } from "../src/adapters/MockAllocatorAdapter.sol";
import { ManagedAllocatorStrategy } from "../src/strategies/ManagedAllocatorStrategy.sol";
import { AllocatorTypes } from "../src/libraries/AllocatorTypes.sol";

contract HelixLensAllocatorTest is Test {
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant RECEIVER = address(0xA11CE);

    MockERC20 internal asset;
    RiskEngine internal riskEngine;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    HelixVault internal vault;
    MockAllocatorAdapter internal adapter;
    ManagedAllocatorStrategy internal strategy;
    HelixLens internal lens;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        riskEngine = new RiskEngine(address(this));
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 days);

        vault = new HelixVault(asset, riskEngine, address(this), GUARDIAN, "Allocator Vault", "aHLX");
        adapter = new MockAllocatorAdapter(asset);
        strategy = new ManagedAllocatorStrategy(
            asset, address(vault), oracleRouter, address(this), STRATEGIST, GUARDIAN
        );
        lens = new HelixLens();

        strategy.addAdapter(address(adapter), 10_000);
        strategy.setGlobalAllocationCapBps(9_000);
        strategy.setIdleFloorBps(500);
        strategy.setAllocationPaused(false);

        vault.setStrategy(strategy);
        riskEngine.setConfig(address(vault), 1_000_000e18, 10_000, false, false);

        asset.mint(address(this), 500e18);
        asset.approve(address(vault), type(uint256).max);
    }

    function testGetAllocatorStrategyViewReturnsCorrectValues() public {
        vault.deposit(200e18, address(this));
        vault.allocateToStrategy(200e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(adapter), 100e18);
        asset.mint(address(adapter), 10e18);
        vm.prank(address(strategy));
        adapter.setHealthState(AllocatorTypes.HealthState.Degraded);
        vm.prank(address(strategy));
        adapter.setWithdrawableLiquidity(50e18);

        HelixLens.AllocatorStrategyView memory view_ = lens.getAllocatorStrategyView(vault);

        AllocatorTypes.AllocatorState memory state = strategy.allocatorState();

        assertEq(view_.vault, address(vault));
        assertEq(view_.strategy, address(strategy));
        assertEq(view_.asset, address(asset));
        assertEq(view_.oracleRouter, address(oracleRouter));
        assertEq(view_.strategist, STRATEGIST);
        assertEq(view_.guardian, GUARDIAN);
        assertEq(uint256(uint8(view_.healthState)), uint256(uint8(state.healthState)));
        assertEq(view_.allocationPaused, state.allocationPaused);
        assertEq(view_.idleFloorBps, state.idleFloorBps);
        assertEq(view_.globalAllocationCapBps, state.globalAllocationCapBps);
        assertEq(view_.totalIdleAssets, state.totalIdleAssets);
        assertEq(view_.totalDeployedAssets, state.totalDeployedAssets);
        assertEq(view_.totalWithdrawableAssets, state.totalWithdrawableAssets);
        assertEq(view_.totalPendingRewards, state.totalPendingRewards);
        assertEq(view_.totalLiveAssets, state.totalLiveAssets);
        assertEq(view_.totalConservativeAssets, state.totalConservativeAssets);
        assertEq(view_.adapterCount, state.adapterCount);
        assertEq(view_.activeAdapterCount, state.activeAdapterCount);
        assertEq(strategy.totalIdle(), 100e18);
        assertEq(strategy.totalDeployedAssets(), 110e18);
        assertEq(strategy.totalPendingRewards(), 10e18);
    }

    function testGetAllocatorStrategyViewReturnsEmptyStructWhenNoStrategyAttached() public {
        HelixVault emptyVault = new HelixVault(
            asset, riskEngine, address(this), GUARDIAN, "Empty Allocator Vault", "eHLX"
        );

        HelixLens.AllocatorStrategyView memory view_ = lens.getAllocatorStrategyView(emptyVault);

        assertEq(view_.vault, address(0));
        assertEq(view_.strategy, address(0));
        assertEq(view_.asset, address(0));
        assertEq(view_.oracleRouter, address(0));
        assertEq(view_.strategist, address(0));
        assertEq(view_.guardian, address(0));
        assertEq(uint256(uint8(view_.healthState)), uint256(uint8(AllocatorTypes.HealthState.Healthy)));
        assertFalse(view_.allocationPaused);
        assertEq(view_.idleFloorBps, 0);
        assertEq(view_.globalAllocationCapBps, 0);
        assertEq(view_.totalIdleAssets, 0);
        assertEq(view_.totalDeployedAssets, 0);
        assertEq(view_.totalWithdrawableAssets, 0);
        assertEq(view_.totalPendingRewards, 0);
        assertEq(view_.totalLiveAssets, 0);
        assertEq(view_.totalConservativeAssets, 0);
        assertEq(view_.adapterCount, 0);
        assertEq(view_.activeAdapterCount, 0);
    }
}
