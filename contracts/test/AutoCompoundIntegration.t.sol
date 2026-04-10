// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { AutoCompoundClStrategy } from "../src/strategies/AutoCompoundClStrategy.sol";
import { MockClAdapter } from "../src/adapters/MockClAdapter.sol";
import { HelixVault } from "../src/HelixVault.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { RewardDistributor } from "../src/periphery/RewardDistributor.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Types } from "../src/libraries/Types.sol";

contract AutoCompoundIntegrationTest is Test {
    uint16 internal constant MAX_ALLOCATION_BPS = 8000;
    uint256 internal constant DEPOSIT_AMOUNT = 1_000e6;
    uint256 internal constant DEPLOY_AMOUNT = 600e6;
    uint256 internal constant PROFIT_AMOUNT = 100e6;
    uint256 internal constant REWARD_AMOUNT = 7 days * 1e18;
    uint256 internal constant HLX_MINT_RATE = 1e30;
    uint256 internal constant INITIAL_USER_BALANCE = 10_000e6;
    uint256 internal constant TREASURY_FEE = 9e6;
    uint256 internal constant STRATEGY_IDLE_REMAINDER = 21e6;
    uint256 internal constant USER_BOUNTY = 3e17;
    uint256 internal constant STRATEGY_HLX_MINT = 20_700_000_000_000_000_000;
    uint256 internal constant USER_FINAL_HLX = REWARD_AMOUNT + USER_BOUNTY;
    uint256 internal constant FINAL_VAULT_ASSETS = 1_091e6;

    address internal constant ALICE = address(0xA11CE);
    address internal constant TREASURY = address(0xFEE);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant GUARDIAN = address(0xBEEF);

    function testFullAutoCompoundLifecycle() public {
        Stack memory stack = _deployFullStack();

        vm.warp(1);

        vm.prank(ALICE);
        uint256 shares = stack.vault.deposit(DEPOSIT_AMOUNT, ALICE);

        stack.vault.allocateToStrategy(DEPLOY_AMOUNT);
        _rebalanceToAdapter(stack.strategy);

        assertEq(stack.vault.totalIdle(), DEPOSIT_AMOUNT - DEPLOY_AMOUNT);
        assertEq(stack.vault.totalStrategyAssets(), DEPLOY_AMOUNT);
        assertEq(stack.vault.totalAssets(), DEPOSIT_AMOUNT);

        stack.asset.mint(address(stack.adapter), PROFIT_AMOUNT);

        vm.prank(ALICE);
        Types.CompoundReport memory report = stack.strategy.compound();

        assertEq(report.profit, PROFIT_AMOUNT);
        assertEq(report.performanceFee, 30e6);
        assertEq(report.treasuryFee, TREASURY_FEE);
        assertEq(report.reinvestAmount, 70e6);
        assertEq(report.hlxUserMint, STRATEGY_HLX_MINT);
        assertEq(report.bountyMint, USER_BOUNTY);
        assertTrue(report.reinvested);

        assertEq(stack.asset.balanceOf(TREASURY), TREASURY_FEE);
        assertEq(stack.hlx.balanceOf(address(stack.rewardDistributor)), STRATEGY_HLX_MINT);
        assertEq(stack.hlx.balanceOf(ALICE), USER_BOUNTY);
        assertEq(stack.strategy.totalIdle(), STRATEGY_IDLE_REMAINDER);
        assertEq(stack.strategy.totalDeployedAssets(), 670e6);
        assertEq(stack.strategy.totalAssets(), 691e6);
        assertEq(stack.vault.totalIdle(), 400e6);
        assertEq(stack.vault.totalStrategyAssets(), 691e6);
        assertEq(stack.vault.totalAssets(), FINAL_VAULT_ASSETS);
        assertEq(stack.adapter.positionState().principalAssets, 670e6);
        assertTrue(stack.adapter.positionState().active);

        vm.prank(ALICE);
        stack.vault.approve(address(stack.rewardDistributor), shares);
        vm.prank(ALICE);
        stack.rewardDistributor.stake(shares);

        assertEq(stack.rewardDistributor.balanceOf(ALICE), shares);
        assertEq(stack.rewardDistributor.totalSupply(), shares);

        stack.hlx.mint(address(this), REWARD_AMOUNT);
        stack.hlx.approve(address(stack.rewardDistributor), REWARD_AMOUNT);
        stack.rewardDistributor.notifyRewardAmount(REWARD_AMOUNT);

        vm.warp(block.timestamp + 7 days);

        vm.prank(ALICE);
        stack.rewardDistributor.claimRewards();

        assertEq(stack.hlx.balanceOf(ALICE), USER_FINAL_HLX);

        vm.prank(ALICE);
        stack.rewardDistributor.withdraw(shares);

        assertEq(stack.rewardDistributor.balanceOf(ALICE), 0);
        assertEq(stack.rewardDistributor.totalSupply(), 0);
        assertEq(stack.vault.balanceOf(ALICE), shares);

        vm.prank(ALICE);
        uint256 assetsOut = stack.vault.redeem(shares, ALICE, ALICE);

        assertEq(assetsOut, FINAL_VAULT_ASSETS);
        assertEq(stack.asset.balanceOf(ALICE), INITIAL_USER_BALANCE - DEPOSIT_AMOUNT + FINAL_VAULT_ASSETS);
        assertEq(stack.asset.balanceOf(TREASURY), TREASURY_FEE);
        assertEq(stack.hlx.balanceOf(ALICE), USER_FINAL_HLX);
        assertEq(stack.vault.totalAssets(), 0);
        assertEq(stack.asset.balanceOf(address(stack.vault)), 0);
        assertEq(stack.asset.balanceOf(address(stack.strategy)), 0);
        assertEq(stack.asset.balanceOf(address(stack.adapter)), 0);
    }

    struct Stack {
        MockERC20 asset;
        RiskEngine riskEngine;
        OracleRouter oracleRouter;
        VaultFactory vaultFactory;
        HelixVault vault;
        MockClAdapter adapter;
        HLXToken hlx;
        RewardDistributor rewardDistributor;
        AutoCompoundClStrategy strategy;
    }

    function _deployFullStack() internal returns (Stack memory stack) {
        stack.asset = new MockERC20("Mock USDC.e", "USDC.e", 6);
        stack.riskEngine = new RiskEngine(address(this));
        stack.oracleRouter = new OracleRouter(address(this));
        MockOracle oracle = new MockOracle(address(this), 1e18);
        stack.oracleRouter.setOracle(address(stack.asset), address(oracle), 1 days);

        stack.vaultFactory = new VaultFactory(stack.riskEngine, address(this));
        stack.vault =
            stack.vaultFactory.createVault(stack.asset, address(this), GUARDIAN, "Helix USDC.e", "HLX");
        stack.adapter = new MockClAdapter(stack.asset, 1 days);
        stack.hlx = new HLXToken(address(this));
        stack.rewardDistributor = new RewardDistributor(address(stack.vault), address(stack.hlx), address(this));

        stack.strategy = new AutoCompoundClStrategy(
            stack.asset,
            address(stack.vault),
            stack.adapter,
            stack.oracleRouter,
            address(this),
            STRATEGIST,
            GUARDIAN,
            TREASURY,
            stack.hlx,
            address(stack.rewardDistributor)
        );

        stack.vault.setStrategy(stack.strategy);
        stack.riskEngine.setConfig(address(stack.vault), 25_000e6, MAX_ALLOCATION_BPS, false, false);
        stack.hlx.grantRole(MINTER_ROLE, address(stack.strategy));
        stack.strategy.setCompoundCooldown(0);
        stack.strategy.setHlxMintRate(HLX_MINT_RATE);

        stack.asset.mint(ALICE, INITIAL_USER_BALANCE);
        vm.prank(ALICE);
        stack.asset.approve(address(stack.vault), type(uint256).max);
    }

    function _rebalanceToAdapter(
        AutoCompoundClStrategy strategy
    ) internal {
        Types.RebalanceIntent memory intent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: DEPLOY_AMOUNT,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 1 days)
        });

        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = Types.ExecutionLimits({
            minAssetsOut: 0,
            maxLoss: 0,
            deadline: intent.deadline
        });

        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, limits);
    }
}
