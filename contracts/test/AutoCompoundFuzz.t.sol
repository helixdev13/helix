// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { AutoCompoundClStrategy } from "../src/strategies/AutoCompoundClStrategy.sol";
import { MockClAdapter } from "../src/adapters/MockClAdapter.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Types } from "../src/libraries/Types.sol";

contract AutoCompoundFuzzTest is Test {
    address internal constant VAULT = address(0xCAFE);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant FEE_RECIPIENT = address(0xFEE);
    address internal constant CALLER = address(0xCA11);
    uint256 internal constant INITIAL_SEED = 100e18;
    uint256 internal constant DEPLOY_AMOUNT = 60e18;
    uint256 internal constant INITIAL_IDLE = INITIAL_SEED - DEPLOY_AMOUNT;

    MockERC20 internal asset;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    MockClAdapter internal adapter;
    HLXToken internal hlx;
    address internal rewardDistributor;
    AutoCompoundClStrategy internal strategy;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 hours);

        adapter = new MockClAdapter(asset, 1 days);
        hlx = new HLXToken(address(this));
        rewardDistributor = address(0xD15);

        strategy = new AutoCompoundClStrategy(
            asset,
            VAULT,
            adapter,
            oracleRouter,
            address(this),
            STRATEGIST,
            GUARDIAN,
            FEE_RECIPIENT,
            hlx,
            rewardDistributor
        );

        hlx.grantRole(MINTER_ROLE, address(strategy));

        asset.mint(VAULT, 1000e18);
        vm.prank(VAULT);
        asset.approve(address(strategy), type(uint256).max);

        strategy.setCompoundCooldown(0);
        strategy.setHlxMintRate(1e18);
        vm.warp(1);
        oracle.setPrice(300e18);
    }

    function testFuzzFeeMath(uint256 profitAmount) public {
        vm.assume(profitAmount >= 1e6 && profitAmount <= 1_000_000e18);

        _seedStrategy(INITIAL_SEED);
        _deployToAdapter(DEPLOY_AMOUNT);
        _simulateProfit(profitAmount);

        vm.prank(CALLER);
        Types.CompoundReport memory report = strategy.compound();

        uint256 expectedPerformanceFee = profitAmount * 3000 / 10_000;
        uint256 expectedTreasuryFee = expectedPerformanceFee * 3000 / 10_000;
        uint256 expectedReinvestAmount = profitAmount - expectedPerformanceFee;
        uint256 expectedHlxPool = expectedPerformanceFee - expectedTreasuryFee;

        assertEq(report.profit, profitAmount);
        assertEq(report.performanceFee, expectedPerformanceFee);
        assertEq(report.treasuryFee, expectedTreasuryFee);
        assertEq(report.reinvestAmount, expectedReinvestAmount);
        assertEq(report.performanceFee, report.treasuryFee + report.hlxUserMint + report.bountyMint);
        assertEq(report.reinvestAmount + report.performanceFee, profitAmount);
        assertTrue(report.reinvested);

        assertEq(asset.balanceOf(FEE_RECIPIENT), expectedTreasuryFee);
        assertEq(asset.balanceOf(address(strategy)), INITIAL_IDLE + expectedHlxPool);
        assertEq(strategy.totalIdle(), INITIAL_IDLE + expectedHlxPool);
        assertEq(strategy.totalDeployedAssets(), DEPLOY_AMOUNT + expectedReinvestAmount);
        assertEq(hlx.balanceOf(address(rewardDistributor)), report.hlxUserMint);
        assertEq(hlx.balanceOf(CALLER), report.bountyMint);
        assertEq(hlx.totalSupply(), report.hlxUserMint + report.bountyMint);
        assertEq(asset.balanceOf(address(adapter)), DEPLOY_AMOUNT + expectedReinvestAmount);
    }

    function _seedStrategy(
        uint256 assetsToDeposit
    ) internal {
        vm.prank(VAULT);
        strategy.deposit(assetsToDeposit);
    }

    function _deployToAdapter(
        uint256 assetsToDeploy
    ) internal {
        Types.RebalanceIntent memory intent =
            _intent(assetsToDeploy, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = _limits(0, 0, intent.deadline);

        strategy.rebalance(intent, quote, limits);
    }

    function _simulateProfit(
        uint256 amount
    ) internal {
        asset.mint(address(adapter), amount);
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
        return Types.ExecutionLimits({
            minAssetsOut: minAssetsOut,
            maxLoss: maxLoss,
            deadline: deadline
        });
    }
}
