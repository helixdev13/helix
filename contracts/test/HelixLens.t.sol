// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { HelixLens } from "../src/periphery/HelixLens.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { MockClAdapter } from "../src/adapters/MockClAdapter.sol";
import { AutoCompoundClStrategy } from "../src/strategies/AutoCompoundClStrategy.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { Types } from "../src/libraries/Types.sol";

contract HelixLensTest is Test {
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant FEE_RECIPIENT = address(0xFEE);
    address internal constant REWARD_DISTRIBUTOR = address(0xD15);

    MockERC20 internal asset;
    RiskEngine internal riskEngine;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    HelixVault internal vault;
    MockClAdapter internal adapter;
    HLXToken internal hlx;
    AutoCompoundClStrategy internal strategy;
    HelixLens internal lens;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        riskEngine = new RiskEngine(address(this));
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 days);

        vault = new HelixVault(asset, riskEngine, address(this), GUARDIAN, "Helix Vault", "HLX");
        adapter = new MockClAdapter(asset, 1 days);
        hlx = new HLXToken(address(this));
        lens = new HelixLens();

        strategy = new AutoCompoundClStrategy(
            asset,
            address(vault),
            adapter,
            oracleRouter,
            address(this),
            STRATEGIST,
            GUARDIAN,
            FEE_RECIPIENT,
            hlx,
            REWARD_DISTRIBUTOR
        );

        hlx.grantRole(MINTER_ROLE, address(strategy));

        vault.setStrategy(strategy);
        riskEngine.setConfig(address(vault), 1_000_000e18, 8000, false, false);

        asset.mint(address(this), 500e18);
        asset.approve(address(vault), type(uint256).max);
    }

    function testGetVaultViewStillWorks() public {
        vault.deposit(200e18, address(this));
        vault.allocateToStrategy(120e18);
        _deployToAdapter(90e18);

        HelixLens.VaultView memory view_ = lens.getVaultView(vault);

        assertEq(view_.vault, address(vault));
        assertEq(view_.asset, address(asset));
        assertEq(view_.guardian, GUARDIAN);
        assertEq(view_.strategy, address(strategy));
        assertEq(view_.riskEngine, address(riskEngine));
        assertEq(view_.totalAssets, 200e18);
        assertEq(view_.totalIdle, 80e18);
        assertEq(view_.totalStrategyAssets, 120e18);
        assertEq(view_.depositCap, 1_000_000e18);
        assertEq(view_.maxAllocationBps, 8000);
        assertFalse(view_.paused);
        assertFalse(view_.withdrawOnly);
    }

    function testGetCompoundStrategyViewReturnsCorrectValues() public {
        vault.deposit(200e18, address(this));
        vault.allocateToStrategy(120e18);
        _deployToAdapter(90e18);

        HelixLens.CompoundStrategyView memory view_ = lens.getCompoundStrategyView(vault);

        Types.CompoundConfig memory config = strategy.compoundConfig();

        assertEq(view_.vault, address(vault));
        assertEq(view_.strategy, address(strategy));
        assertEq(view_.adapter, address(adapter));
        assertEq(view_.performanceFeeBps, config.performanceFeeBps);
        assertEq(view_.rewardRatioBps, config.rewardRatioBps);
        assertEq(view_.bountyBps, config.bountyBps);
        assertEq(view_.hlxMintRate, config.hlxMintRate);
        assertEq(view_.minimumProfitThreshold, config.minimumProfitThreshold);
        assertEq(view_.compoundCooldown, config.compoundCooldown);
        assertEq(view_.lastCompoundTimestamp, 0);
        assertEq(view_.feeRecipient, config.feeRecipient);
        assertEq(view_.hlxToken, config.hlxToken);
        assertEq(view_.rewardDistributor, config.rewardDistributor);
        assertEq(view_.totalIdle, 30e18);
        assertEq(view_.totalDeployedAssets, 90e18);
        assertEq(view_.totalAssets, 120e18);
        assertFalse(view_.rebalancePaused);
    }

    function testGetCompoundStrategyViewReturnsEmptyStructWhenNoStrategyAttached() public {
        HelixVault emptyVault =
            new HelixVault(asset, riskEngine, address(this), GUARDIAN, "Empty Vault", "eHLX");

        HelixLens.CompoundStrategyView memory view_ = lens.getCompoundStrategyView(emptyVault);

        assertEq(view_.vault, address(0));
        assertEq(view_.strategy, address(0));
        assertEq(view_.adapter, address(0));
        assertEq(view_.performanceFeeBps, 0);
        assertEq(view_.rewardRatioBps, 0);
        assertEq(view_.bountyBps, 0);
        assertEq(view_.hlxMintRate, 0);
        assertEq(view_.minimumProfitThreshold, 0);
        assertEq(view_.compoundCooldown, 0);
        assertEq(view_.lastCompoundTimestamp, 0);
        assertEq(view_.feeRecipient, address(0));
        assertEq(view_.hlxToken, address(0));
        assertEq(view_.rewardDistributor, address(0));
        assertEq(view_.totalIdle, 0);
        assertEq(view_.totalDeployedAssets, 0);
        assertEq(view_.totalAssets, 0);
        assertFalse(view_.rebalancePaused);
    }

    function _deployToAdapter(
        uint256 assetsToDeploy
    ) internal {
        Types.RebalanceIntent memory intent =
            _intent(assetsToDeploy, 0, uint64(block.timestamp + 1 days));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = _limits(0, 0, intent.deadline);

        strategy.rebalance(intent, quote, limits);
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
