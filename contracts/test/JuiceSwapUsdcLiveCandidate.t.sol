// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { ManagedClStrategy } from "../src/strategies/ManagedClStrategy.sol";
import { JuiceSwapClAdapter } from "../src/adapters/JuiceSwapClAdapter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
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

contract JuiceSwapUsdcLiveCandidateTest is Test {
    uint160 internal constant SQRT_PRICE_X96 = 79_228_162_514_264_337_593_543_950_336;
    uint24 internal constant APPROVED_POOL_FEE = 3000;
    uint24 internal constant ALTERNATE_POOL_FEE = 10_000;
    uint48 internal constant ORACLE_HEARTBEAT = 1 days;
    uint16 internal constant INITIAL_MAX_ALLOCATION_BPS = 0;
    uint256 internal constant DEPOSIT_CAP = 25_000e6;
    uint256 internal constant WCBTC_PRICE = 1_000_000_000_000e18;

    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant ALICE = address(0xA11CE);

    MockERC20 internal usdce;
    MockERC20 internal wcbtc;
    RiskEngine internal riskEngine;
    OracleRouter internal oracleRouter;
    MockOracle internal usdceOracle;
    MockOracle internal wcbtcOracle;
    HelixVault internal vault;
    MockJuiceSwapFactory internal factory;
    MockJuiceSwapPool internal approvedPool;
    MockJuiceSwapPool internal alternatePool;
    MockJuiceSwapPositionManager internal positionManager;
    MockJuiceSwapSwapRouter internal swapRouter;
    JuiceSwapClAdapter internal adapter;
    ManagedClStrategy internal strategy;

    function setUp() public {
        usdce = new MockERC20("Bridged USDC", "USDC.e", 6);
        wcbtc = new MockERC20("Wrapped cBTC", "wcBTC", 18);
        riskEngine = new RiskEngine(address(this));
        oracleRouter = new OracleRouter(address(this));
        usdceOracle = new MockOracle(address(this), 1e18);
        wcbtcOracle = new MockOracle(address(this), WCBTC_PRICE);
        oracleRouter.setOracle(address(usdce), address(usdceOracle), ORACLE_HEARTBEAT);
        oracleRouter.setOracle(address(wcbtc), address(wcbtcOracle), ORACLE_HEARTBEAT);

        factory = new MockJuiceSwapFactory();
        approvedPool = factory.deployPool(
            address(usdce), address(wcbtc), APPROVED_POOL_FEE, SQRT_PRICE_X96, 0
        );
        alternatePool = factory.deployPool(
            address(usdce), address(wcbtc), ALTERNATE_POOL_FEE, SQRT_PRICE_X96, 0
        );
        positionManager = new MockJuiceSwapPositionManager(factory);
        swapRouter = new MockJuiceSwapSwapRouter(factory);

        vault = new HelixVault(usdce, riskEngine, address(this), GUARDIAN, "Helix USDC.e", "HLX-U");
        adapter = new JuiceSwapClAdapter(
            usdce,
            wcbtc,
            factory,
            positionManager,
            swapRouter,
            oracleRouter,
            APPROVED_POOL_FEE,
            ORACLE_HEARTBEAT,
            500,
            500
        );
        strategy = new ManagedClStrategy(
            usdce, address(vault), adapter, oracleRouter, address(this), STRATEGIST, GUARDIAN
        );

        vault.setStrategy(strategy);
        riskEngine.setConfig(address(vault), DEPOSIT_CAP, INITIAL_MAX_ALLOCATION_BPS, false, false);

        usdce.mint(ALICE, 20_000e6);
        vm.prank(ALICE);
        usdce.approve(address(vault), type(uint256).max);
    }

    function testLiveCandidateUsesApprovedPairAndFeeTier() public view {
        assertEq(usdce.decimals(), 6);
        assertEq(wcbtc.decimals(), 18);
        assertEq(vault.asset(), address(usdce));
        assertEq(adapter.asset(), address(usdce));
        assertEq(address(adapter.PAIR_TOKEN()), address(wcbtc));
        assertEq(address(adapter.POOL()), address(approvedPool));
        assertEq(adapter.POOL_FEE(), APPROVED_POOL_FEE);
        assertTrue(address(alternatePool) != address(adapter.POOL()));
    }

    function testLaunchCandidateStartsDisabledForProductiveAllocation() public {
        vm.prank(ALICE);
        vault.deposit(5000e6, ALICE);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.AllocationCapExceeded.selector, 1000e6, uint256(0))
        );
        vault.allocateToStrategy(1000e6);
    }

    function testMissingPairOracleBlocksLiveCandidatePreview() public {
        OracleRouter pairMissingRouter = new OracleRouter(address(this));
        pairMissingRouter.setOracle(address(usdce), address(usdceOracle), ORACLE_HEARTBEAT);

        HelixVault pairMissingVault =
            new HelixVault(usdce, riskEngine, address(this), GUARDIAN, "Pair Missing", "PAIR");
        JuiceSwapClAdapter pairMissingAdapter = new JuiceSwapClAdapter(
            usdce,
            wcbtc,
            factory,
            positionManager,
            swapRouter,
            pairMissingRouter,
            APPROVED_POOL_FEE,
            ORACLE_HEARTBEAT,
            500,
            500
        );
        ManagedClStrategy pairMissingStrategy = new ManagedClStrategy(
            usdce,
            address(pairMissingVault),
            pairMissingAdapter,
            pairMissingRouter,
            address(this),
            STRATEGIST,
            GUARDIAN
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOracle.selector, address(wcbtc)));
        pairMissingStrategy.previewRebalance(_intent(5000e6, 0, 1_000_000_000_000));
    }

    function testStaleBaseOracleBlocksLiveCandidatePreview() public {
        vm.warp(ORACLE_HEARTBEAT + 2);
        wcbtcOracle.setPrice(WCBTC_PRICE);
        uint48 staleAt = uint48(block.timestamp - ORACLE_HEARTBEAT - 1);
        usdceOracle.setPriceWithTimestamp(1e18, staleAt);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StalePrice.selector,
                address(usdce),
                staleAt,
                block.timestamp,
                ORACLE_HEARTBEAT
            )
        );
        strategy.previewRebalance(_intent(5000e6, 0, 1_000_000_000_000));
    }

    function testSixDecimalLiveCandidateCanRebalanceWhenEnabled() public {
        riskEngine.setMaxAllocationBps(address(vault), 2000);

        vm.prank(ALICE);
        vault.deposit(10_000e6, ALICE);

        vault.allocateToStrategy(2000e6);

        Types.RebalanceIntent memory intent = _intent(2000e6, 0, 100_000_000_000);

        vm.prank(STRATEGIST);
        strategy.rebalance(intent, strategy.previewRebalance(intent), _limits(0, 1000e6));

        assertTrue(adapter.positionState().active);
        assertGt(vault.totalStrategyAssets(), 0);
        assertEq(vault.totalIdle(), 8000e6);
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
