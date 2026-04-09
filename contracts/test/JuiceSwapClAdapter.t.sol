// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { JuiceSwapClAdapter } from "../src/adapters/JuiceSwapClAdapter.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { Errors } from "../src/libraries/Errors.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Types } from "../src/libraries/Types.sol";
import {
    MockJuiceSwapFactory,
    MockJuiceSwapPool,
    MockJuiceSwapPositionManager,
    MockJuiceSwapSwapRouter
} from "./utils/juiceswap/MockJuiceSwapVenue.sol";

contract JuiceSwapClAdapterTest is Test {
    uint160 internal constant SQRT_PRICE_X96 = 79_228_162_514_264_337_593_543_950_336;
    uint24 internal constant POOL_FEE = 3000;
    uint256 internal constant WCBTC_PRICE = 1_000_000_000_000e18;
    uint48 internal constant ORACLE_HEARTBEAT = 1 days;

    address internal constant RECEIVER = address(0xA11CE);

    MockERC20 internal ctusd;
    MockERC20 internal wcbtc;
    OracleRouter internal oracleRouter;
    MockOracle internal ctusdOracle;
    MockOracle internal wcbtcOracle;
    MockJuiceSwapFactory internal factory;
    MockJuiceSwapPool internal pool;
    MockJuiceSwapPositionManager internal positionManager;
    MockJuiceSwapSwapRouter internal swapRouter;
    JuiceSwapClAdapter internal adapter;

    function setUp() public {
        ctusd = new MockERC20("Citrea USD", "ctUSD", 6);
        wcbtc = new MockERC20("Wrapped cBTC", "wcBTC", 18);
        oracleRouter = new OracleRouter(address(this));
        ctusdOracle = new MockOracle(address(this), 1e18);
        wcbtcOracle = new MockOracle(address(this), WCBTC_PRICE);
        oracleRouter.setOracle(address(ctusd), address(ctusdOracle), ORACLE_HEARTBEAT);
        oracleRouter.setOracle(address(wcbtc), address(wcbtcOracle), ORACLE_HEARTBEAT);

        factory = new MockJuiceSwapFactory();
        pool = factory.deployPool(address(ctusd), address(wcbtc), POOL_FEE, SQRT_PRICE_X96, 0);
        positionManager = new MockJuiceSwapPositionManager(factory);
        swapRouter = new MockJuiceSwapSwapRouter(factory);

        adapter = new JuiceSwapClAdapter(
            ctusd,
            wcbtc,
            factory,
            positionManager,
            swapRouter,
            oracleRouter,
            POOL_FEE,
            ORACLE_HEARTBEAT,
            500,
            500
        );
        adapter.bindStrategy(address(this));

        ctusd.mint(address(this), 100_000e6);
        ctusd.approve(address(adapter), type(uint256).max);
    }

    function testQuoteAndExecuteHappyPath() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        Types.RebalanceQuote memory quote = adapter.quoteRebalance(intent);

        Types.ExecutionReport memory report =
            adapter.executeRebalance(intent, quote, _limits(0, 5000e6));

        Types.PositionState memory position = adapter.positionState();
        Types.Valuation memory value = adapter.valuation();

        assertEq(report.assetsIn, 20_000e6);
        assertEq(report.assetsOut, 0);
        assertEq(report.lossInAssets, quote.estimatedLoss);
        assertEq(report.adapterAssetsAfter, quote.expectedAdapterAssetsAfter);
        assertEq(report.adapterAssetsAfter, value.grossAssets);
        assertEq(report.positionVersion, adapter.positionState().version);
        assertEq(position.lowerTick, -120);
        assertEq(position.upperTick, 120);
        assertTrue(position.active);
        assertGt(position.liquidity, 0);
        assertLt(value.netAssets, value.grossAssets);
    }

    function testWithdrawToUnwindsAndReopensPosition() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(intent, adapter.quoteRebalance(intent), _limits(0, 5000e6));

        uint64 versionBefore = adapter.positionState().version;
        uint256 grossBefore = adapter.valuation().grossAssets;

        uint256 withdrawn = adapter.withdrawTo(RECEIVER, 5000e6);

        Types.PositionState memory positionAfter = adapter.positionState();
        assertEq(withdrawn, 5000e6);
        assertEq(ctusd.balanceOf(RECEIVER), 5000e6);
        assertTrue(positionAfter.active);
        assertGt(positionAfter.liquidity, 0);
        assertGt(positionAfter.version, versionBefore);
        assertLt(adapter.valuation().grossAssets, grossBefore);
    }

    function testHarvestToCollectsFeesInBaseAsset() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(intent, adapter.quoteRebalance(intent), _limits(0, 5000e6));

        uint256 tokenId = adapter.positionTokenId();
        (uint256 amount0Fee, uint256 amount1Fee) =
            adapter.ASSET_IS_TOKEN0() ? (750e6, 250e6) : (250e6, 750e6);
        positionManager.addFees(tokenId, amount0Fee, amount1Fee);

        uint256 pendingBefore = adapter.valuation().pendingFees;
        uint256 harvested = adapter.harvestTo(RECEIVER);

        assertGt(pendingBefore, 0);
        assertGt(harvested, 0);
        assertEq(ctusd.balanceOf(RECEIVER), harvested);
        assertEq(adapter.valuation().pendingFees, 0);
    }

    function testPendingFeesAccumulateAcrossMultipleFeeGrowthUpdates() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(intent, adapter.quoteRebalance(intent), _limits(0, 5000e6));

        uint256 tokenId = adapter.positionTokenId();
        (uint256 amount0Fee, uint256 amount1Fee) =
            adapter.ASSET_IS_TOKEN0() ? (400e6, 125e6) : (125e6, 400e6);
        positionManager.addFees(tokenId, amount0Fee, amount1Fee);
        uint256 pendingAfterFirstAccrual = adapter.valuation().pendingFees;

        positionManager.addFees(tokenId, amount0Fee, amount1Fee);
        uint256 pendingAfterSecondAccrual = adapter.valuation().pendingFees;

        assertGt(pendingAfterFirstAccrual, 0);
        assertGt(pendingAfterSecondAccrual, pendingAfterFirstAccrual);
    }

    function testHarvestToRevertsWhenLiquidationOutputViolatesOracleBound() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(intent, adapter.quoteRebalance(intent), _limits(0, 5000e6));

        uint256 tokenId = adapter.positionTokenId();
        (uint256 amount0Fee, uint256 amount1Fee) =
            adapter.ASSET_IS_TOKEN0() ? (750e6, 250e6) : (250e6, 750e6);
        positionManager.addFees(tokenId, amount0Fee, amount1Fee);
        swapRouter.setExactInputOutBps(9000);

        vm.expectRevert(bytes("MIN_OUT"));
        adapter.harvestTo(RECEIVER);
    }

    function testHarvestToRevertsWhenBaseOracleIsStale() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(intent, adapter.quoteRebalance(intent), _limits(0, 5000e6));

        uint256 tokenId = adapter.positionTokenId();
        positionManager.addFees(
            tokenId, adapter.ASSET_IS_TOKEN0() ? 0 : 250e6, adapter.ASSET_IS_TOKEN0() ? 250e6 : 0
        );

        vm.warp(ORACLE_HEARTBEAT + 2);
        wcbtcOracle.setPrice(WCBTC_PRICE);
        uint48 staleAt = uint48(block.timestamp - ORACLE_HEARTBEAT - 1);
        ctusdOracle.setPriceWithTimestamp(1e18, staleAt);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StalePrice.selector,
                address(ctusd),
                staleAt,
                block.timestamp,
                ORACLE_HEARTBEAT
            )
        );
        adapter.harvestTo(RECEIVER);
    }

    function testQuoteRebalanceRevertsWhenPairOracleIsMissing() public {
        OracleRouter pairMissingRouter = new OracleRouter(address(this));
        pairMissingRouter.setOracle(address(ctusd), address(ctusdOracle), ORACLE_HEARTBEAT);

        JuiceSwapClAdapter pairMissingAdapter = new JuiceSwapClAdapter(
            ctusd,
            wcbtc,
            factory,
            positionManager,
            swapRouter,
            pairMissingRouter,
            POOL_FEE,
            ORACLE_HEARTBEAT,
            500,
            500
        );
        pairMissingAdapter.bindStrategy(address(this));

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOracle.selector, address(wcbtc)));
        pairMissingAdapter.quoteRebalance(_intent(20_000e6, 0, 1_000_000_000_000));
    }

    function testQuoteRebalanceRevertsWhenPairOracleIsStale() public {
        vm.warp(ORACLE_HEARTBEAT + 2);
        ctusdOracle.setPrice(1e18);
        uint48 staleAt = uint48(block.timestamp - ORACLE_HEARTBEAT - 1);
        wcbtcOracle.setPriceWithTimestamp(WCBTC_PRICE, staleAt);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StalePrice.selector,
                address(wcbtc),
                staleAt,
                block.timestamp,
                ORACLE_HEARTBEAT
            )
        );
        adapter.quoteRebalance(_intent(20_000e6, 0, 1_000_000_000_000));
    }

    function testQuoteRebalanceRevertsOnPoolPriceDeviation() public {
        pool.setPrice(SQRT_PRICE_X96 * 2, 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.PoolPriceDeviation.selector, 250_000, 1_000_000, 7500, 500
            )
        );
        adapter.quoteRebalance(_intent(20_000e6, 0, 1_000_000_000_000));
    }

    function testUnwindAllReturnsBaseOnly() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(intent, adapter.quoteRebalance(intent), _limits(0, 5000e6));

        positionManager.addFees(
            adapter.positionTokenId(),
            adapter.ASSET_IS_TOKEN0() ? 500e6 : 100e6,
            adapter.ASSET_IS_TOKEN0() ? 100e6 : 500e6
        );

        uint256 returned = adapter.unwindAllTo(RECEIVER);

        assertGt(returned, 0);
        assertEq(wcbtc.balanceOf(address(adapter)), 0);
        assertEq(adapter.positionTokenId(), 0);
        assertFalse(adapter.positionState().active);
        assertEq(ctusd.balanceOf(RECEIVER), returned);
    }

    function testExecuteRebalanceRevertsWhenCollapseOutputViolatesOracleBound() public {
        Types.RebalanceIntent memory initialIntent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(
            initialIntent, adapter.quoteRebalance(initialIntent), _limits(0, 5000e6)
        );

        swapRouter.setExactInputOutBps(9000);

        Types.RebalanceIntent memory collapseIntent = _intent(0, 0, 0);
        Types.RebalanceQuote memory collapseQuote = adapter.quoteRebalance(collapseIntent);

        vm.expectRevert(bytes("MIN_OUT"));
        adapter.executeRebalance(collapseIntent, collapseQuote, _limits(0, 5000e6));
    }

    function testUnwindAllToWithoutPositionReturnsZero() public {
        uint256 returned = adapter.unwindAllTo(RECEIVER);

        assertEq(returned, 0);
        assertEq(ctusd.balanceOf(RECEIVER), 0);
        assertEq(adapter.positionTokenId(), 0);
        assertFalse(adapter.positionState().active);
    }

    function testWithdrawToWithNearEmptyRemainderDoesNotLeaveQuoteDust() public {
        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        adapter.executeRebalance(intent, adapter.quoteRebalance(intent), _limits(0, 5000e6));

        uint256 grossAssets = adapter.valuation().grossAssets;
        uint256 remainingDust = 1;
        uint256 withdrawn = adapter.withdrawTo(RECEIVER, grossAssets - remainingDust);

        Types.PositionState memory positionAfter = adapter.positionState();
        assertEq(withdrawn, grossAssets - remainingDust);
        assertEq(wcbtc.balanceOf(address(adapter)), 0);
        assertEq(ctusd.balanceOf(address(adapter)), remainingDust);
        assertEq(positionAfter.liquidity, 0);
        assertFalse(positionAfter.active);
    }

    function _intent(
        uint256 assetsToDeploy,
        uint256 assetsToWithdraw,
        uint128 targetLiquidity
    ) internal view returns (Types.RebalanceIntent memory) {
        return Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: targetLiquidity,
            assetsToDeploy: assetsToDeploy,
            assetsToWithdraw: assetsToWithdraw,
            deadline: uint64(block.timestamp + 1 days)
        });
    }

    function _limits(
        uint256 minAssetsOut,
        uint256 maxLoss
    ) internal view returns (Types.ExecutionLimits memory) {
        return Types.ExecutionLimits({
            minAssetsOut: minAssetsOut, maxLoss: maxLoss, deadline: uint64(block.timestamp + 1 days)
        });
    }
}
