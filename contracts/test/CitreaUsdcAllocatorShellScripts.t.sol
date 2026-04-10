// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { DeployCitreaCore } from "../script/DeployCitreaCore.s.sol";
import { DeployCitreaUsdcAllocatorShell } from "../script/DeployCitreaUsdcAllocatorShell.s.sol";
import { TransferCitreaUsdcAllocatorShellOwnership } from "../script/TransferCitreaUsdcAllocatorShellOwnership.s.sol";
import { AcceptCitreaUsdcAllocatorShellOwnership } from "../script/AcceptCitreaUsdcAllocatorShellOwnership.s.sol";
import { VerifyCitreaUsdcAllocatorShellPostDeploy } from "../script/VerifyCitreaUsdcAllocatorShellPostDeploy.s.sol";
import { HelixVault } from "../src/HelixVault.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { ManagedAllocatorStrategy } from "../src/strategies/ManagedAllocatorStrategy.sol";
import { AllocatorTypes } from "../src/libraries/AllocatorTypes.sol";

contract CitreaUsdcAllocatorShellScriptsTest is Test {
    uint256 internal constant CITREA_MAINNET_CHAIN_ID = 4114;
    address internal constant CITREA_USDCE = 0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839;
    uint256 internal constant DEPLOYER_KEY = 0xA11CE;
    uint256 internal constant FINAL_OWNER_KEY = 0xB0B;
    address internal constant FINAL_OWNER_ADDRESS =
        0x0376AAc07Ad725E01357B1725B5ceC61aE10473c;
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant STRATEGIST = address(0xB0B0);

    struct ShellContext {
        address broadcaster;
        address finalOwner;
        address vaultFactory;
        address oracleRouter;
        address riskEngine;
        address vault;
        address strategy;
    }

    function testAllocatorShellScriptsRehearsalFlow() public {
        ShellContext memory ctx = _deployShell();
        _transferShellOwnership(ctx);
        _acceptShellOwnership(ctx);
        _verifyShellPostDeploy(ctx);
    }

    function _deployShell() internal returns (ShellContext memory ctx) {
        vm.chainId(CITREA_MAINNET_CHAIN_ID);

        ctx.broadcaster = vm.addr(DEPLOYER_KEY);
        ctx.finalOwner = vm.addr(FINAL_OWNER_KEY);

        MockERC20 usdce = new MockERC20("Citrea USDC.e", "USDC.e", 6);
        vm.etch(CITREA_USDCE, address(usdce).code);

        vm.setEnv("PRIVATE_KEY", vm.toString(DEPLOYER_KEY));
        vm.setEnv("RISK_ENGINE_OWNER", vm.toString(ctx.broadcaster));
        vm.setEnv("ORACLE_ROUTER_OWNER", vm.toString(ctx.broadcaster));
        vm.setEnv("VAULT_FACTORY_OWNER", vm.toString(ctx.broadcaster));
        vm.setEnv("DEPLOY_LENS", "true");

        DeployCitreaCore deployCore = new DeployCitreaCore();
        (RiskEngine riskEngine, OracleRouter oracleRouter, VaultFactory vaultFactory,) =
            deployCore.run();

        ctx.vaultFactory = address(vaultFactory);
        ctx.oracleRouter = address(oracleRouter);
        ctx.riskEngine = address(riskEngine);

        MockOracle oracle = new MockOracle(address(this), 300e18);
        vm.prank(ctx.broadcaster);
        oracleRouter.setOracle(CITREA_USDCE, address(oracle), 1 days);

        vm.setEnv("VAULT_FACTORY_ADDRESS", vm.toString(ctx.vaultFactory));
        vm.setEnv("ORACLE_ROUTER_ADDRESS", vm.toString(ctx.oracleRouter));
        vm.setEnv("FINAL_OWNER", vm.toString(FINAL_OWNER_ADDRESS));
        vm.setEnv("GUARDIAN", vm.toString(GUARDIAN));
        vm.setEnv("STRATEGIST", vm.toString(STRATEGIST));

        DeployCitreaUsdcAllocatorShell deployShell = new DeployCitreaUsdcAllocatorShell();
        (HelixVault vault, ManagedAllocatorStrategy strategy, RiskEngine shellRiskEngine) =
            deployShell.run();

        ctx.vault = address(vault);
        ctx.strategy = address(strategy);

        assertEq(address(shellRiskEngine), ctx.riskEngine);
        assertEq(vault.owner(), ctx.broadcaster);
        assertEq(vault.guardian(), GUARDIAN);
        assertEq(address(vault.strategy()), ctx.strategy);
        assertEq(riskEngine.getMaxAllocationBps(ctx.vault), 0);
        assertTrue(strategy.rebalancePaused());
        assertEq(strategy.globalAllocationCapBps(), 0);
        assertEq(strategy.adapterCount(), 0);
        assertEq(strategy.totalIdle(), 0);
        assertEq(strategy.totalDeployedAssets(), 0);

        return ctx;
    }

    function _transferShellOwnership(
        ShellContext memory ctx
    ) internal {
        vm.setEnv("PRIVATE_KEY", vm.toString(DEPLOYER_KEY));
        vm.setEnv("VAULT_FACTORY_ADDRESS", vm.toString(ctx.vaultFactory));
        vm.setEnv("RISK_ENGINE_ADDRESS", vm.toString(ctx.riskEngine));
        vm.setEnv("ORACLE_ROUTER_ADDRESS", vm.toString(ctx.oracleRouter));
        vm.setEnv("VAULT_ADDRESS", vm.toString(ctx.vault));
        vm.setEnv("STRATEGY_ADDRESS", vm.toString(ctx.strategy));
        vm.setEnv("FINAL_OWNER", vm.toString(FINAL_OWNER_ADDRESS));

        TransferCitreaUsdcAllocatorShellOwnership transfer =
            new TransferCitreaUsdcAllocatorShellOwnership();
        transfer.run();

        assertEq(VaultFactory(ctx.vaultFactory).pendingOwner(), ctx.finalOwner);
        assertEq(RiskEngine(ctx.riskEngine).pendingOwner(), ctx.finalOwner);
        assertEq(OracleRouter(ctx.oracleRouter).pendingOwner(), ctx.finalOwner);
        assertEq(HelixVault(payable(ctx.vault)).pendingOwner(), ctx.finalOwner);
        assertEq(ManagedAllocatorStrategy(ctx.strategy).pendingOwner(), ctx.finalOwner);
    }

    function _acceptShellOwnership(
        ShellContext memory ctx
    ) internal {
        vm.setEnv("PRIVATE_KEY", vm.toString(FINAL_OWNER_KEY));
        vm.setEnv("VAULT_FACTORY_ADDRESS", vm.toString(ctx.vaultFactory));
        vm.setEnv("RISK_ENGINE_ADDRESS", vm.toString(ctx.riskEngine));
        vm.setEnv("ORACLE_ROUTER_ADDRESS", vm.toString(ctx.oracleRouter));
        vm.setEnv("VAULT_ADDRESS", vm.toString(ctx.vault));
        vm.setEnv("STRATEGY_ADDRESS", vm.toString(ctx.strategy));

        AcceptCitreaUsdcAllocatorShellOwnership accept =
            new AcceptCitreaUsdcAllocatorShellOwnership();
        accept.run();

        assertEq(VaultFactory(ctx.vaultFactory).owner(), ctx.finalOwner);
        assertEq(RiskEngine(ctx.riskEngine).owner(), ctx.finalOwner);
        assertEq(OracleRouter(ctx.oracleRouter).owner(), ctx.finalOwner);
        assertEq(HelixVault(payable(ctx.vault)).owner(), ctx.finalOwner);
        assertEq(ManagedAllocatorStrategy(ctx.strategy).owner(), ctx.finalOwner);
        assertEq(VaultFactory(ctx.vaultFactory).pendingOwner(), address(0));
        assertEq(RiskEngine(ctx.riskEngine).pendingOwner(), address(0));
        assertEq(OracleRouter(ctx.oracleRouter).pendingOwner(), address(0));
        assertEq(HelixVault(payable(ctx.vault)).pendingOwner(), address(0));
        assertEq(ManagedAllocatorStrategy(ctx.strategy).pendingOwner(), address(0));
    }

    function _verifyShellPostDeploy(
        ShellContext memory ctx
    ) internal {
        vm.setEnv("FINAL_OWNER", vm.toString(FINAL_OWNER_ADDRESS));
        vm.setEnv("VAULT_FACTORY_ADDRESS", vm.toString(ctx.vaultFactory));
        vm.setEnv("RISK_ENGINE_ADDRESS", vm.toString(ctx.riskEngine));
        vm.setEnv("VAULT_ADDRESS", vm.toString(ctx.vault));
        vm.setEnv("STRATEGY_ADDRESS", vm.toString(ctx.strategy));

        VerifyCitreaUsdcAllocatorShellPostDeploy verify =
            new VerifyCitreaUsdcAllocatorShellPostDeploy();
        verify.run();

        ManagedAllocatorStrategy strategy = ManagedAllocatorStrategy(ctx.strategy);
        AllocatorTypes.AllocatorState memory state = strategy.allocatorState();
        assertEq(uint256(state.adapterCount), 0);
        assertEq(uint256(state.activeAdapterCount), 0);
        assertEq(uint256(state.totalIdleAssets), 0);
        assertEq(uint256(state.totalDeployedAssets), 0);
        assertEq(uint256(state.totalConservativeAssets), 0);
        assertEq(strategy.globalAllocationCapBps(), 0);
        assertTrue(strategy.rebalancePaused());
    }
}
