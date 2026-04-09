// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { ManagedClStrategy } from "../src/strategies/ManagedClStrategy.sol";
import { MockClAdapter } from "../src/adapters/MockClAdapter.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Errors } from "../src/libraries/Errors.sol";
import { Types } from "../src/libraries/Types.sol";

contract ManagedClStrategyTest is Test {
    address internal constant VAULT = address(0xCAFE);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant OTHER = address(0xBAD);
    address internal constant RECEIVER = address(0xA11CE);

    MockERC20 internal asset;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    MockClAdapter internal adapter;
    ManagedClStrategy internal strategy;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 hours);

        adapter = new MockClAdapter(asset, 1 days);
        strategy = new ManagedClStrategy(
            asset, VAULT, adapter, oracleRouter, address(this), STRATEGIST, GUARDIAN
        );

        asset.mint(VAULT, 1000e18);
        vm.prank(VAULT);
        asset.approve(address(strategy), type(uint256).max);
    }

    function testOnlyVaultCanCallStrategyLifecycleMethods() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.deposit(1e18);

        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.withdraw(1e18, RECEIVER);

        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.harvest();

        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.unwindAll();
    }

    function testOnlyOwnerOrStrategistCanRebalance() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = _limits(0, 0, intent.deadline);

        vm.expectRevert(Errors.OnlyOwnerOrStrategist.selector);
        vm.prank(OTHER);
        strategy.rebalance(intent, quote, limits);

        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, limits);

        assertEq(asset.balanceOf(address(adapter)), 60e18);
        assertEq(strategy.totalIdle(), 40e18);
    }

    function testQuoteValidateExecuteHappyPath() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);

        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(0, 0, intent.deadline));

        assertEq(strategy.totalIdle(), 40e18);
        assertEq(strategy.totalDeployedAssets(), 60e18);
        assertEq(adapter.valuation().grossAssets, 60e18);
    }

    function testStaleQuoteBlocksRebalance() public {
        _seedStrategy(100e18);
        vm.prank(address(strategy));
        adapter.setQuoteValidity(30 minutes);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 2 days));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);

        vm.warp(uint256(quote.validUntil) + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.QuoteExpired.selector,
                uint256(quote.validUntil) + 1,
                uint256(quote.validUntil)
            )
        );
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(0, 0, intent.deadline));
    }

    function testStaleOracleBlocksRebalance() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 2 days));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);

        vm.warp(block.timestamp + 2 hours);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StalePrice.selector,
                address(asset),
                uint256(1),
                block.timestamp,
                uint256(1 hours)
            )
        );
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(0, 0, intent.deadline));
    }

    function testSlippageBoundBlocksRebalance() public {
        _seedStrategy(100e18);

        vm.prank(address(strategy));
        adapter.setExecutionLossBps(500);

        Types.RebalanceIntent memory intent =
            _intent(50e18, 10e18, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.LossExceeded.selector, quote.estimatedLoss, 2e18)
        );
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(10e18, 2e18, intent.deadline));
    }

    function testTamperedEstimatedLossIsRejected() public {
        _seedStrategy(100e18);

        vm.prank(address(strategy));
        adapter.setExecutionLossBps(500);

        Types.RebalanceIntent memory intent =
            _intent(50e18, 10e18, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        quote.estimatedLoss -= 1;

        vm.expectRevert(Errors.QuoteFactsMismatch.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(10e18, 5e18, intent.deadline));
    }

    function testTamperedExpectedAssetsOutIsRejected() public {
        _seedStrategy(100e18);

        vm.prank(address(strategy));
        adapter.setExecutionLossBps(500);

        Types.RebalanceIntent memory intent =
            _intent(50e18, 10e18, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        quote.expectedAssetsOut -= 1;

        vm.expectRevert(Errors.QuoteFactsMismatch.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(9e18, 5e18, intent.deadline));
    }

    function testTamperedAdapterAssetsBeforeIsRejected() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        quote.adapterAssetsBefore = 1;

        vm.expectRevert(Errors.QuoteFactsMismatch.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(0, 0, intent.deadline));
    }

    function testTamperedExpectedAdapterAssetsAfterIsRejected() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        quote.expectedAdapterAssetsAfter -= 1;

        vm.expectRevert(Errors.QuoteFactsMismatch.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(0, 0, intent.deadline));
    }

    function testPartialWithdrawUsesIdleThenAdapter() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(80e18, 0, uint64(block.timestamp + 1 hours));
        vm.prank(STRATEGIST);
        strategy.rebalance(
            intent, strategy.previewRebalance(intent), _limits(0, 0, intent.deadline)
        );

        vm.prank(VAULT);
        strategy.withdraw(60e18, RECEIVER);

        assertEq(asset.balanceOf(RECEIVER), 60e18);
        assertEq(strategy.totalIdle(), 0);
        assertEq(asset.balanceOf(address(adapter)), 40e18);
        assertEq(strategy.totalAssets(), 40e18);
    }

    function testHarvestMovesPendingFeesIntoIdle() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        vm.prank(STRATEGIST);
        strategy.rebalance(
            intent, strategy.previewRebalance(intent), _limits(0, 0, intent.deadline)
        );

        asset.mint(address(adapter), 10e18);

        vm.prank(VAULT);
        strategy.harvest();

        assertEq(strategy.totalIdle(), 50e18);
        assertEq(adapter.valuation().pendingFees, 0);
        assertEq(strategy.totalAssets(), 110e18);
    }

    function testFullUnwindReturnsEverythingToVault() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(70e18, 0, uint64(block.timestamp + 1 hours));
        vm.prank(STRATEGIST);
        strategy.rebalance(
            intent, strategy.previewRebalance(intent), _limits(0, 0, intent.deadline)
        );

        asset.mint(address(adapter), 5e18);

        vm.prank(VAULT);
        strategy.unwindAll();

        assertEq(asset.balanceOf(VAULT), 1005e18);
        assertEq(strategy.totalIdle(), 0);
        assertEq(asset.balanceOf(address(adapter)), 0);
    }

    function testValuationIsAuditable() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        vm.prank(STRATEGIST);
        strategy.rebalance(
            intent, strategy.previewRebalance(intent), _limits(0, 0, intent.deadline)
        );

        asset.mint(address(adapter), 10e18);
        vm.prank(address(strategy));
        adapter.setValuationHaircutBps(1000);

        Types.Valuation memory value = strategy.adapterValuation();

        assertEq(value.grossAssets, 70e18);
        assertEq(value.deployedAssets, 60e18);
        assertEq(value.pendingFees, 10e18);
        assertEq(value.haircutAmount, 7e18);
        assertEq(value.netAssets, 63e18);
        assertEq(strategy.totalIdle(), 40e18);
        assertEq(strategy.totalDeployedAssets(), 70e18);
        assertEq(strategy.totalConservativeAssets(), 103e18);
        assertEq(strategy.totalAssets(), strategy.totalIdle() + strategy.totalDeployedAssets());
        assertEq(strategy.totalAssets(), 110e18);
    }

    function testGuardianCanPauseRebalancesButOnlyOwnerCanUnpause() public {
        _seedStrategy(100e18);

        vm.prank(GUARDIAN);
        strategy.setRebalancePaused(true);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);

        vm.expectRevert(Errors.RebalancePaused.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(0, 0, intent.deadline));

        vm.expectRevert(Errors.OnlyOwnerCanDisableRebalancePause.selector);
        vm.prank(GUARDIAN);
        strategy.setRebalancePaused(false);

        strategy.setRebalancePaused(false);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, _limits(0, 0, intent.deadline));
    }

    function _seedStrategy(
        uint256 assetsToDeposit
    ) internal {
        vm.prank(VAULT);
        strategy.deposit(assetsToDeposit);
    }

    function _intent(
        uint256 assetsToDeploy,
        uint256 assetsToWithdraw,
        uint64 deadline
    ) internal pure returns (Types.RebalanceIntent memory) {
        return Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
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
