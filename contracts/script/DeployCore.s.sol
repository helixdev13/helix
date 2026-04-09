// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { RiskEngine } from "../src/core/RiskEngine.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { HelixLens } from "../src/periphery/HelixLens.sol";

contract DeployCore is Script {
    uint256 internal constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run()
        external
        returns (
            RiskEngine riskEngine,
            OracleRouter oracleRouter,
            VaultFactory vaultFactory,
            HelixLens lens
        )
    {
        uint256 deployerKey = vm.envOr("PRIVATE_KEY", DEFAULT_ANVIL_PRIVATE_KEY);
        address broadcaster = vm.addr(deployerKey);

        address riskEngineOwner = vm.envOr("RISK_ENGINE_OWNER", broadcaster);
        address oracleRouterOwner = vm.envOr("ORACLE_ROUTER_OWNER", broadcaster);
        address vaultFactoryOwner = vm.envOr("VAULT_FACTORY_OWNER", broadcaster);
        bool deployLens = vm.envOr("DEPLOY_LENS", true);

        vm.startBroadcast(deployerKey);

        riskEngine = new RiskEngine(riskEngineOwner);
        oracleRouter = new OracleRouter(oracleRouterOwner);
        vaultFactory = new VaultFactory(riskEngine, vaultFactoryOwner);
        if (deployLens) {
            lens = new HelixLens();
        }

        vm.stopBroadcast();

        console2.log("RiskEngine:", address(riskEngine));
        console2.log("OracleRouter:", address(oracleRouter));
        console2.log("VaultFactory:", address(vaultFactory));
        console2.log("HelixLens:", address(lens));
    }
}
