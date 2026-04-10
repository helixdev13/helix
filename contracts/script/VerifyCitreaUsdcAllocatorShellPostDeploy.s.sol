// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { ManagedAllocatorStrategy } from "../src/strategies/ManagedAllocatorStrategy.sol";

contract VerifyCitreaUsdcAllocatorShellPostDeploy is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;

    struct Config {
        address finalOwner;
        address vaultFactoryAddress;
        address riskEngineAddress;
        address vaultAddress;
        address strategyAddress;
    }

    function run() external view {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("VerifyCitreaUsdcAllocatorShellPostDeploy must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        RiskEngine riskEngine = RiskEngine(config.riskEngineAddress);
        HelixVault vault = HelixVault(payable(config.vaultAddress));
        ManagedAllocatorStrategy strategy = ManagedAllocatorStrategy(config.strategyAddress);

        if (
            vaultFactory.owner() != config.finalOwner || riskEngine.owner() != config.finalOwner
                || vault.owner() != config.finalOwner || strategy.owner() != config.finalOwner
        ) {
            revert("Allocator shell owner mismatch");
        }
        if (
            vaultFactory.pendingOwner() != address(0) || riskEngine.pendingOwner() != address(0)
                || vault.pendingOwner() != address(0) || strategy.pendingOwner() != address(0)
        ) {
            revert("Allocator shell pending owner mismatch");
        }
        if (
            address(vault.strategy()) != config.strategyAddress
                || strategy.vault() != address(vault)
                || strategy.adapterCount() != 0
                || strategy.totalDeployedAssets() != 0
        ) {
            revert("Allocator shell strategy mismatch");
        }
        if (
            riskEngine.getMaxAllocationBps(address(vault)) != 0
                || riskEngine.isPaused(address(vault))
                || riskEngine.isWithdrawOnly(address(vault))
        ) {
            revert("Allocator shell risk state mismatch");
        }
        if (
            !strategy.rebalancePaused() || strategy.globalAllocationCapBps() != 0
                || strategy.totalIdle() != 0
        ) {
            revert("Allocator shell strategy state mismatch");
        }

        console2.log("Chain ID:", block.chainid);
        console2.log("Final owner:", config.finalOwner);
        console2.log("VaultFactory owner:", vaultFactory.owner());
        console2.log("RiskEngine owner:", riskEngine.owner());
        console2.log("Vault owner:", vault.owner());
        console2.log("Strategy owner:", strategy.owner());
        console2.log("Strategy attached:", address(vault.strategy()));
        console2.log("Strategy paused:", strategy.rebalancePaused());
        console2.log("Global allocation cap bps:", strategy.globalAllocationCapBps());
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.finalOwner = vm.envAddress("FINAL_OWNER");
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.riskEngineAddress = vm.envAddress("RISK_ENGINE_ADDRESS");
        config.vaultAddress = vm.envAddress("VAULT_ADDRESS");
        config.strategyAddress = vm.envAddress("STRATEGY_ADDRESS");
    }
}
