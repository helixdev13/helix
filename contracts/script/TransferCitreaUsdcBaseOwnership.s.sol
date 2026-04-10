// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";

contract TransferCitreaUsdcBaseOwnership is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address finalOwner;
        address vaultFactoryAddress;
        address riskEngineAddress;
        address vaultAddress;
    }

    function run() external {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("TransferCitreaUsdcBaseOwnership must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        if (config.finalOwner == address(0) || config.finalOwner == config.broadcaster) {
            revert("TransferCitreaUsdcBaseOwnership requires a distinct final owner");
        }

        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        RiskEngine riskEngine = RiskEngine(config.riskEngineAddress);
        HelixVault vault = HelixVault(payable(config.vaultAddress));

        if (
            vaultFactory.owner() != config.broadcaster
                || riskEngine.owner() != config.broadcaster
                || vault.owner() != config.broadcaster
        ) {
            revert("Broadcaster must own all base-vault contracts before transfer");
        }

        vm.startBroadcast(config.deployerKey);

        vaultFactory.transferOwnership(config.finalOwner);
        riskEngine.transferOwnership(config.finalOwner);
        vault.transferOwnership(config.finalOwner);

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("Final owner:", config.finalOwner);
        console2.log("VaultFactory pending owner:", vaultFactory.pendingOwner());
        console2.log("RiskEngine pending owner:", riskEngine.pendingOwner());
        console2.log("Vault pending owner:", vault.pendingOwner());
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envUint("PRIVATE_KEY");
        config.broadcaster = vm.addr(config.deployerKey);
        config.finalOwner = vm.envAddress("FINAL_OWNER");
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.riskEngineAddress = vm.envAddress("RISK_ENGINE_ADDRESS");
        config.vaultAddress = vm.envAddress("VAULT_ADDRESS");
    }
}
