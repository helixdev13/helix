// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { ManagedAllocatorStrategy } from "../src/strategies/ManagedAllocatorStrategy.sol";
import { MockAllocatorAdapter } from "../src/adapters/MockAllocatorAdapter.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { AllocatorTypes } from "../src/libraries/AllocatorTypes.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract ManagedAllocatorStrategyTest is Test {
    address internal constant VAULT = address(0xCAFE);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant OTHER = address(0xBAD);
    address internal constant RECEIVER = address(0xA11CE);

    MockERC20 internal asset;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    ManagedAllocatorStrategy internal strategy;
    MockAllocatorAdapter internal healthyAdapter;
    MockAllocatorAdapter internal secondaryAdapter;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 hours);

        strategy = new ManagedAllocatorStrategy(
            asset, VAULT, oracleRouter, address(this), STRATEGIST, GUARDIAN
        );

        healthyAdapter = new MockAllocatorAdapter(asset);
        secondaryAdapter = new MockAllocatorAdapter(asset);

        strategy.addAdapter(address(healthyAdapter), 10_000);
        strategy.addAdapter(address(secondaryAdapter), 10_000);
        strategy.setGlobalAllocationCapBps(10_000);
        strategy.setIdleFloorBps(0);
        strategy.setAllocationPaused(false);

        asset.mint(VAULT, 1_000e18);
        vm.prank(VAULT);
        asset.approve(address(strategy), type(uint256).max);
    }

    function testAllocateHappyPath() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 60e18);

        assertEq(strategy.totalIdle(), 40e18);
        assertEq(strategy.totalDeployedAssets(), 60e18);
        assertEq(asset.balanceOf(address(healthyAdapter)), 60e18);
        assertEq(strategy.totalAssets(), 100e18);
    }

    function testDirectDeallocateReturnsAssetsToIdle() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 60e18);

        vm.prank(STRATEGIST);
        strategy.deallocateFromAdapter(address(healthyAdapter), 20e18);

        assertEq(strategy.totalIdle(), 60e18);
        assertEq(asset.balanceOf(address(healthyAdapter)), 40e18);
        assertEq(strategy.totalAssets(), 100e18);
    }

    function testWithdrawUsesHealthyThenDegradedAdapters() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 40e18);
        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(secondaryAdapter), 40e18);

        vm.prank(address(strategy));
        secondaryAdapter.setHealthState(AllocatorTypes.HealthState.Degraded);
        vm.prank(address(strategy));
        healthyAdapter.setWithdrawableLiquidity(10e18);
        vm.prank(address(strategy));
        secondaryAdapter.setWithdrawableLiquidity(50e18);

        vm.prank(VAULT);
        strategy.withdraw(60e18, RECEIVER);

        assertEq(asset.balanceOf(RECEIVER), 60e18);
        assertEq(strategy.totalIdle(), 0);
        assertEq(asset.balanceOf(address(healthyAdapter)), 30e18);
        assertEq(asset.balanceOf(address(secondaryAdapter)), 10e18);
        assertEq(strategy.totalAssets(), 40e18);
    }

    function testBlockedAdapterSkippedDuringWithdraw() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 40e18);
        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(secondaryAdapter), 40e18);

        vm.prank(address(strategy));
        secondaryAdapter.setHealthState(AllocatorTypes.HealthState.Blocked);

        vm.prank(VAULT);
        strategy.withdraw(50e18, RECEIVER);

        assertEq(asset.balanceOf(RECEIVER), 50e18);
        assertEq(strategy.totalIdle(), 0);
        assertEq(asset.balanceOf(address(healthyAdapter)), 10e18);
        assertEq(asset.balanceOf(address(secondaryAdapter)), 40e18);
    }

    function testLowLiquidityWithdrawalFailsConservatively() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 40e18);
        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(secondaryAdapter), 40e18);

        vm.prank(address(strategy));
        healthyAdapter.setWithdrawableLiquidity(10e18);
        vm.prank(address(strategy));
        secondaryAdapter.setHealthState(AllocatorTypes.HealthState.Blocked);

        vm.prank(VAULT);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientLiquidAssets.selector, 30e18, 60e18
            )
        );
        strategy.withdraw(60e18, RECEIVER);
    }

    function testStaleOracleBlocksAllocation() public {
        _seedStrategy(100e18);

        vm.warp(block.timestamp + 2 hours);

        vm.prank(STRATEGIST);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StalePrice.selector,
                address(asset),
                uint256(1),
                block.timestamp,
                uint256(1 hours)
            )
        );
        strategy.allocateToAdapter(address(healthyAdapter), 20e18);
    }

    function testDegradedAdapterBlocksAllocation() public {
        _seedStrategy(100e18);

        vm.prank(address(strategy));
        healthyAdapter.setHealthState(AllocatorTypes.HealthState.Degraded);

        vm.prank(STRATEGIST);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.AdapterNotHealthy.selector,
                address(healthyAdapter),
                uint8(AllocatorTypes.HealthState.Degraded)
            )
        );
        strategy.allocateToAdapter(address(healthyAdapter), 20e18);
    }

    function testOnlyOwnerOrStrategistCanAllocate() public {
        _seedStrategy(100e18);

        vm.expectRevert(Errors.OnlyOwnerOrStrategist.selector);
        vm.prank(OTHER);
        strategy.allocateToAdapter(address(healthyAdapter), 20e18);
    }

    function testAllocationPausedBlocksAllocation() public {
        _seedStrategy(100e18);

        strategy.setAllocationPaused(true);

        vm.prank(STRATEGIST);
        vm.expectRevert(Errors.RebalancePaused.selector);
        strategy.allocateToAdapter(address(healthyAdapter), 20e18);
    }

    function testCapEnforcementBlocksOversizedAllocation() public {
        _seedStrategy(100e18);

        strategy.setAdapterMaxAllocationBps(address(healthyAdapter), 5_000);

        vm.prank(STRATEGIST);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AllocationCapExceeded.selector, 60e18, 50e18)
        );
        strategy.allocateToAdapter(address(healthyAdapter), 60e18);
    }

    function testHarvestAggregatesRewards() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 60e18);

        asset.mint(address(healthyAdapter), 10e18);
        vm.prank(address(strategy));
        healthyAdapter.setHealthState(AllocatorTypes.HealthState.Degraded);

        vm.prank(VAULT);
        strategy.harvest();

        assertEq(strategy.totalIdle(), 50e18);
        assertEq(strategy.totalPendingRewards(), 0);
        assertEq(strategy.totalDeployedAssets(), 60e18);
        assertEq(strategy.totalAssets(), 110e18);
    }

    function testEmergencyUnwindRecoversFromPartialLiquidity() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 80e18);

        asset.mint(address(healthyAdapter), 5e18);
        vm.prank(address(strategy));
        healthyAdapter.setHealthState(AllocatorTypes.HealthState.Blocked);
        vm.prank(address(strategy));
        healthyAdapter.setWithdrawableLiquidity(10e18);

        vm.prank(VAULT);
        strategy.unwindAll();

        assertEq(asset.balanceOf(VAULT), 1_005e18);
        assertEq(strategy.totalIdle(), 0);
        assertEq(asset.balanceOf(address(healthyAdapter)), 0);
        assertEq(strategy.totalAssets(), 0);
    }

    function testAllocatorStateReportsMixedHealth() public {
        _seedStrategy(100e18);

        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(healthyAdapter), 40e18);
        vm.prank(STRATEGIST);
        strategy.allocateToAdapter(address(secondaryAdapter), 20e18);

        asset.mint(address(secondaryAdapter), 10e18);
        vm.prank(address(strategy));
        secondaryAdapter.setHealthState(AllocatorTypes.HealthState.Blocked);
        vm.prank(address(strategy));
        healthyAdapter.setValuationHaircutBps(1000);

        AllocatorTypes.AllocatorState memory state = strategy.allocatorState();
        AllocatorTypes.AdapterState memory healthyState = strategy.adapterState(address(healthyAdapter));
        AllocatorTypes.AdapterState memory blockedState = strategy.adapterState(address(secondaryAdapter));

        assertEq(state.totalIdleAssets, 40e18);
        assertEq(state.totalDeployedAssets, 70e18);
        assertEq(state.totalPendingRewards, 10e18);
        assertEq(state.totalConservativeAssets, 106e18);
        assertEq(state.totalLiveAssets, 110e18);
        assertEq(uint256(uint8(state.healthState)), uint256(uint8(AllocatorTypes.HealthState.Blocked)));
        assertEq(state.adapterCount, 2);
        assertEq(state.activeAdapterCount, 2);

        assertEq(healthyState.adapter, address(healthyAdapter));
        assertEq(healthyState.config.maxAllocationBps, 10_000);
        assertEq(
            uint256(uint8(healthyState.healthState)),
            uint256(uint8(AllocatorTypes.HealthState.Healthy))
        );
        assertEq(healthyState.valuation.grossAssets, 40e18);
        assertEq(healthyState.valuation.deployedAssets, 40e18);
        assertEq(healthyState.valuation.pendingRewards, 0);
        assertEq(healthyState.valuation.haircutAmount, 4e18);
        assertEq(healthyState.valuation.netAssets, 36e18);

        assertEq(blockedState.adapter, address(secondaryAdapter));
        assertEq(
            uint256(uint8(blockedState.healthState)),
            uint256(uint8(AllocatorTypes.HealthState.Blocked))
        );
        assertEq(blockedState.valuation.grossAssets, 30e18);
        assertEq(blockedState.valuation.pendingRewards, 10e18);
    }

    function testRepeatedAllocateAndDeallocateCyclesStayConsistent() public {
        _seedStrategy(100e18);

        for (uint256 i = 0; i < 3; ++i) {
            vm.prank(STRATEGIST);
            strategy.allocateToAdapter(address(healthyAdapter), 10e18);
            vm.prank(STRATEGIST);
            strategy.deallocateFromAdapter(address(healthyAdapter), 10e18);
        }

        assertEq(strategy.totalIdle(), 100e18);
        assertEq(strategy.totalDeployedAssets(), 0);
        assertEq(strategy.totalAssets(), 100e18);
        assertEq(asset.balanceOf(address(healthyAdapter)), 0);
    }

    function _seedStrategy(
        uint256 assetsToDeposit
    ) internal {
        vm.prank(VAULT);
        strategy.deposit(assetsToDeposit);
    }
}
