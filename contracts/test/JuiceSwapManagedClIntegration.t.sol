// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { ManagedClStrategy } from "../src/strategies/ManagedClStrategy.sol";
import { JuiceSwapClAdapter } from "../src/adapters/JuiceSwapClAdapter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Types } from "../src/libraries/Types.sol";
import {
    MockJuiceSwapFactory,
    MockJuiceSwapPool,
    MockJuiceSwapPositionManager,
    MockJuiceSwapSwapRouter
} from "./utils/juiceswap/MockJuiceSwapVenue.sol";

contract JuiceSwapManagedClIntegrationTest is Test {
    uint160 internal constant SQRT_PRICE_X96 = 79_228_162_514_264_337_593_543_950_336;
    uint24 internal constant POOL_FEE = 3000;
    uint256 internal constant CAP = 250_000e6;
    uint256 internal constant WCBTC_PRICE = 1_000_000_000_000e18;

    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xBAD);

    MockERC20 internal ctusd;
    MockERC20 internal wcbtc;
    RiskEngine internal riskEngine;
    OracleRouter internal oracleRouter;
    MockOracle internal ctusdOracle;
    MockOracle internal wcbtcOracle;
    HelixVault internal vault;
    MockJuiceSwapFactory internal factory;
    MockJuiceSwapPool internal pool;
    MockJuiceSwapPositionManager internal positionManager;
    MockJuiceSwapSwapRouter internal swapRouter;
    JuiceSwapClAdapter internal adapter;
    ManagedClStrategy internal strategy;

    function setUp() public {
        ctusd = new MockERC20("Citrea USD", "ctUSD", 6);
        wcbtc = new MockERC20("Wrapped cBTC", "wcBTC", 18);
        riskEngine = new RiskEngine(address(this));
        oracleRouter = new OracleRouter(address(this));
        ctusdOracle = new MockOracle(address(this), 1e18);
        wcbtcOracle = new MockOracle(address(this), WCBTC_PRICE);
        oracleRouter.setOracle(address(ctusd), address(ctusdOracle), 1 days);
        oracleRouter.setOracle(address(wcbtc), address(wcbtcOracle), 1 days);

        factory = new MockJuiceSwapFactory();
        pool = factory.deployPool(address(ctusd), address(wcbtc), POOL_FEE, SQRT_PRICE_X96, 0);
        positionManager = new MockJuiceSwapPositionManager(factory);
        swapRouter = new MockJuiceSwapSwapRouter(factory);

        vault = new HelixVault(ctusd, riskEngine, address(this), GUARDIAN, "Helix Vault", "HLX");
        adapter = new JuiceSwapClAdapter(
            ctusd,
            wcbtc,
            factory,
            positionManager,
            swapRouter,
            oracleRouter,
            POOL_FEE,
            1 days,
            500,
            500
        );
        strategy = new ManagedClStrategy(
            ctusd, address(vault), adapter, oracleRouter, address(this), STRATEGIST, GUARDIAN
        );

        vault.setStrategy(strategy);
        riskEngine.setConfig(address(vault), CAP, 8000, false, false);

        ctusd.mint(ALICE, 80_000e6);
        ctusd.mint(BOB, 80_000e6);

        vm.prank(ALICE);
        ctusd.approve(address(vault), type(uint256).max);
        vm.prank(BOB);
        ctusd.approve(address(vault), type(uint256).max);
    }

    function testVaultWithdrawPullsThroughJuiceSwapAdapter() public {
        vm.prank(ALICE);
        vault.deposit(30_000e6, ALICE);
        vm.prank(BOB);
        vault.deposit(20_000e6, BOB);

        vault.allocateToStrategy(40_000e6);

        Types.RebalanceIntent memory intent = _intent(40_000e6, 0, 1_000_000_000_000);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, strategy.previewRebalance(intent), _limits(0, 10_000e6));

        assertGt(vault.totalStrategyAssets(), 0);
        assertTrue(adapter.positionState().active);

        positionManager.addFees(
            adapter.positionTokenId(),
            adapter.ASSET_IS_TOKEN0() ? 1000e6 : 250e6,
            adapter.ASSET_IS_TOKEN0() ? 250e6 : 1000e6
        );
        vault.harvestStrategy();
        assertGt(vault.totalAssets(), 50_000e6);

        vm.prank(ALICE);
        vault.withdraw(10_000e6, ALICE, ALICE);

        assertEq(ctusd.balanceOf(ALICE), 60_000e6);
        assertGt(vault.totalAssets(), 0);
        assertEq(strategy.totalAssets(), adapter.valuation().grossAssets + strategy.totalIdle());
    }

    function testEmergencyPauseFullyUnwindsJuiceSwapAdapter() public {
        vm.prank(ALICE);
        vault.deposit(25_000e6, ALICE);

        vault.allocateToStrategy(20_000e6);

        Types.RebalanceIntent memory intent = _intent(20_000e6, 0, 1_000_000_000_000);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, strategy.previewRebalance(intent), _limits(0, 10_000e6));

        vm.prank(GUARDIAN);
        vault.emergencyPause();

        assertEq(adapter.positionTokenId(), 0);
        assertFalse(adapter.positionState().active);
        assertEq(vault.totalStrategyAssets(), 0);
        assertEq(vault.totalIdle(), vault.totalAssets());
        assertTrue(vault.withdrawOnly());
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
