// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { ManagedClStrategy } from "../src/strategies/ManagedClStrategy.sol";

contract TransferCitreaCandidateOwnership is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address finalOwner;
        address vaultFactoryAddress;
        address riskEngineAddress;
        address oracleRouterAddress;
        address vaultAddress;
        address strategyAddress;
    }

    function run() external {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("TransferCitreaCandidateOwnership must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        if (config.finalOwner == address(0) || config.finalOwner == config.broadcaster) {
            revert("TransferCitreaCandidateOwnership requires a distinct final owner");
        }

        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        RiskEngine riskEngine = RiskEngine(config.riskEngineAddress);
        OracleRouter oracleRouter = OracleRouter(config.oracleRouterAddress);
        HelixVault vault = HelixVault(payable(config.vaultAddress));
        ManagedClStrategy strategy = ManagedClStrategy(config.strategyAddress);

        if (
            vaultFactory.owner() != config.broadcaster || riskEngine.owner() != config.broadcaster
                || oracleRouter.owner() != config.broadcaster || vault.owner() != config.broadcaster
                || strategy.owner() != config.broadcaster
        ) {
            revert("Broadcaster must own all candidate contracts before transfer");
        }

        vm.startBroadcast(config.deployerKey);

        vaultFactory.transferOwnership(config.finalOwner);
        riskEngine.transferOwnership(config.finalOwner);
        oracleRouter.transferOwnership(config.finalOwner);
        vault.transferOwnership(config.finalOwner);
        strategy.transferOwnership(config.finalOwner);

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("Final owner:", config.finalOwner);
        console2.log("VaultFactory pending owner:", vaultFactory.pendingOwner());
        console2.log("RiskEngine pending owner:", riskEngine.pendingOwner());
        console2.log("OracleRouter pending owner:", oracleRouter.pendingOwner());
        console2.log("Vault pending owner:", vault.pendingOwner());
        console2.log("Strategy pending owner:", strategy.pendingOwner());
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envUint("PRIVATE_KEY");
        config.broadcaster = vm.addr(config.deployerKey);
        config.finalOwner = vm.envAddress("FINAL_OWNER");
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.riskEngineAddress = vm.envAddress("RISK_ENGINE_ADDRESS");
        config.oracleRouterAddress = vm.envAddress("ORACLE_ROUTER_ADDRESS");
        config.vaultAddress = vm.envAddress("VAULT_ADDRESS");
        config.strategyAddress = vm.envAddress("STRATEGY_ADDRESS");
    }
}
