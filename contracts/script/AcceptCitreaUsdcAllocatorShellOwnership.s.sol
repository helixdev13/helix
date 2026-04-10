// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { ManagedAllocatorStrategy } from "../src/strategies/ManagedAllocatorStrategy.sol";

contract AcceptCitreaUsdcAllocatorShellOwnership is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;

    struct Config {
        uint256 ownerKey;
        address finalOwner;
        address vaultFactoryAddress;
        address riskEngineAddress;
        address oracleRouterAddress;
        address vaultAddress;
        address strategyAddress;
    }

    function run() external {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("AcceptCitreaUsdcAllocatorShellOwnership must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        RiskEngine riskEngine = RiskEngine(config.riskEngineAddress);
        OracleRouter oracleRouter = OracleRouter(config.oracleRouterAddress);
        HelixVault vault = HelixVault(payable(config.vaultAddress));
        ManagedAllocatorStrategy strategy = ManagedAllocatorStrategy(config.strategyAddress);

        if (
            vaultFactory.pendingOwner() != config.finalOwner
                || riskEngine.pendingOwner() != config.finalOwner
                || oracleRouter.pendingOwner() != config.finalOwner
                || vault.pendingOwner() != config.finalOwner
                || strategy.pendingOwner() != config.finalOwner
        ) {
            revert("Final owner must be the pending owner on all allocator shell contracts");
        }

        vm.startBroadcast(config.ownerKey);

        vaultFactory.acceptOwnership();
        riskEngine.acceptOwnership();
        oracleRouter.acceptOwnership();
        vault.acceptOwnership();
        strategy.acceptOwnership();

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("Final owner:", config.finalOwner);
        console2.log("VaultFactory owner:", vaultFactory.owner());
        console2.log("RiskEngine owner:", riskEngine.owner());
        console2.log("OracleRouter owner:", oracleRouter.owner());
        console2.log("Vault owner:", vault.owner());
        console2.log("Strategy owner:", strategy.owner());
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.ownerKey = vm.envUint("PRIVATE_KEY");
        config.finalOwner = vm.addr(config.ownerKey);
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.riskEngineAddress = vm.envAddress("RISK_ENGINE_ADDRESS");
        config.oracleRouterAddress = vm.envAddress("ORACLE_ROUTER_ADDRESS");
        config.vaultAddress = vm.envAddress("VAULT_ADDRESS");
        config.strategyAddress = vm.envAddress("STRATEGY_ADDRESS");
    }
}
