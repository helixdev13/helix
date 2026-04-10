// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { RewardDistributor } from "../src/periphery/RewardDistributor.sol";
import { AutoCompoundClStrategy } from "../src/strategies/AutoCompoundClStrategy.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";

contract TransferCitreaAutoCompoundVaultOwnership is Script {
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
        address rewardDistributorAddress;
        address hlxTokenAddress;
    }

    function run() external {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("TransferCitreaAutoCompoundVaultOwnership must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        if (config.finalOwner == address(0) || config.finalOwner == config.broadcaster) {
            revert("TransferCitreaAutoCompoundVaultOwnership requires a distinct final owner");
        }

        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        RiskEngine riskEngine = RiskEngine(config.riskEngineAddress);
        OracleRouter oracleRouter = OracleRouter(config.oracleRouterAddress);
        HelixVault vault = HelixVault(payable(config.vaultAddress));
        AutoCompoundClStrategy strategy = AutoCompoundClStrategy(config.strategyAddress);
        RewardDistributor rewardDistributor = RewardDistributor(config.rewardDistributorAddress);
        HLXToken hlxToken = HLXToken(config.hlxTokenAddress);

        if (
            vaultFactory.owner() != config.broadcaster || riskEngine.owner() != config.broadcaster
                || oracleRouter.owner() != config.broadcaster || vault.owner() != config.broadcaster
                || strategy.owner() != config.broadcaster
                || rewardDistributor.owner() != config.broadcaster
        ) {
            revert("Broadcaster must own all auto-compound contracts before transfer");
        }
        if (
            !hlxToken.hasRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.broadcaster)
                || !hlxToken.hasRole(MINTER_ROLE, config.broadcaster)
        ) {
            revert("Broadcaster must control HLX before transfer");
        }

        vm.startBroadcast(config.deployerKey);

        vaultFactory.transferOwnership(config.finalOwner);
        riskEngine.transferOwnership(config.finalOwner);
        oracleRouter.transferOwnership(config.finalOwner);
        vault.transferOwnership(config.finalOwner);
        strategy.transferOwnership(config.finalOwner);
        rewardDistributor.transferOwnership(config.finalOwner);

        hlxToken.grantRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.finalOwner);
        hlxToken.grantRole(MINTER_ROLE, address(strategy));
        hlxToken.revokeRole(MINTER_ROLE, config.broadcaster);
        hlxToken.revokeRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.broadcaster);

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("Final owner:", config.finalOwner);
        console2.log("VaultFactory pending owner:", vaultFactory.pendingOwner());
        console2.log("RiskEngine pending owner:", riskEngine.pendingOwner());
        console2.log("OracleRouter pending owner:", oracleRouter.pendingOwner());
        console2.log("Vault pending owner:", vault.pendingOwner());
        console2.log("Strategy pending owner:", strategy.pendingOwner());
        console2.log("RewardDistributor pending owner:", rewardDistributor.pendingOwner());
        console2.log("HLX admin final owner:", hlxToken.hasRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.finalOwner));
        console2.log("HLX admin broadcaster:", hlxToken.hasRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.broadcaster));
        console2.log("HLX minter strategy:", hlxToken.hasRole(MINTER_ROLE, address(strategy)));
        console2.log("HLX minter broadcaster:", hlxToken.hasRole(MINTER_ROLE, config.broadcaster));
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
        config.rewardDistributorAddress = vm.envAddress("REWARD_DISTRIBUTOR_ADDRESS");
        config.hlxTokenAddress = vm.envAddress("HLX_TOKEN_ADDRESS");
    }
}
