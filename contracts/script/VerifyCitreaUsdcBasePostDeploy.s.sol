// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";

contract VerifyCitreaUsdcBasePostDeploy is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;

    struct Config {
        address finalOwner;
        address vaultFactoryAddress;
        address riskEngineAddress;
        address vaultAddress;
    }

    function run() external view {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("VerifyCitreaUsdcBasePostDeploy must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        RiskEngine riskEngine = RiskEngine(config.riskEngineAddress);
        HelixVault vault = HelixVault(payable(config.vaultAddress));

        if (
            vaultFactory.owner() != config.finalOwner || riskEngine.owner() != config.finalOwner
                || vault.owner() != config.finalOwner
        ) {
            revert("Base vault owner mismatch");
        }
        if (
            vaultFactory.pendingOwner() != address(0) || riskEngine.pendingOwner() != address(0)
                || vault.pendingOwner() != address(0)
        ) {
            revert("Base vault pending owner mismatch");
        }
        if (address(vault.strategy()) != address(0)) {
            revert("Base vault should remain strategy-free");
        }
        if (
            riskEngine.getMaxAllocationBps(address(vault)) != 0
                || riskEngine.isPaused(address(vault))
                || riskEngine.isWithdrawOnly(address(vault))
        ) {
            revert("Base vault risk state mismatch");
        }

        console2.log("Chain ID:", block.chainid);
        console2.log("Final owner:", config.finalOwner);
        console2.log("VaultFactory owner:", vaultFactory.owner());
        console2.log("RiskEngine owner:", riskEngine.owner());
        console2.log("Vault owner:", vault.owner());
        console2.log("Vault pending owner:", vault.pendingOwner());
        console2.log("Strategy attached:", address(vault.strategy()));
        console2.log("Max allocation bps:", riskEngine.getMaxAllocationBps(address(vault)));
        console2.log("Paused:", riskEngine.isPaused(address(vault)));
        console2.log("Withdraw only:", riskEngine.isWithdrawOnly(address(vault)));
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.finalOwner = vm.envAddress("FINAL_OWNER");
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.riskEngineAddress = vm.envAddress("RISK_ENGINE_ADDRESS");
        config.vaultAddress = vm.envAddress("VAULT_ADDRESS");
    }
}
