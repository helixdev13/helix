// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { ManagedAllocatorStrategy } from "../src/strategies/ManagedAllocatorStrategy.sol";

contract DeployCitreaUsdcAllocatorShell is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;
    address public constant CITREA_USDCE = 0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839;
    uint8 public constant CITREA_USDCE_DECIMALS = 6;
    uint16 public constant INITIAL_MAX_ALLOCATION_BPS = 0;
    uint16 public constant INITIAL_GLOBAL_ALLOCATION_CAP_BPS = 0;
    uint256 public constant DEFAULT_DEPOSIT_CAP = 25_000e6;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address vaultFactoryAddress;
        address oracleRouterAddress;
        address finalOwner;
        address guardian;
        address strategist;
        string vaultName;
        string vaultSymbol;
        uint256 depositCap;
    }

    function run()
        external
        returns (HelixVault vault, ManagedAllocatorStrategy strategy, RiskEngine riskEngine)
    {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("DeployCitreaUsdcAllocatorShell must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        OracleRouter oracleRouter = OracleRouter(config.oracleRouterAddress);
        riskEngine = RiskEngine(address(vaultFactory.RISK_ENGINE()));

        _validateLaunchSurface(vaultFactory, riskEngine, oracleRouter, config);

        vm.startBroadcast(config.deployerKey);

        vault = vaultFactory.createVault(
            IERC20(CITREA_USDCE),
            config.broadcaster,
            config.guardian,
            config.vaultName,
            config.vaultSymbol
        );

        riskEngine.setConfig(
            address(vault), config.depositCap, INITIAL_MAX_ALLOCATION_BPS, false, false
        );

        strategy = new ManagedAllocatorStrategy(
            IERC20(CITREA_USDCE),
            address(vault),
            oracleRouter,
            config.broadcaster,
            config.strategist,
            config.guardian
        );
        strategy.setGlobalAllocationCapBps(INITIAL_GLOBAL_ALLOCATION_CAP_BPS);

        vault.setStrategy(strategy);

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("VaultFactory:", address(vaultFactory));
        console2.log("RiskEngine:", address(riskEngine));
        console2.log("OracleRouter:", address(oracleRouter));
        console2.log("Vault:", address(vault));
        console2.log("Strategy:", address(strategy));
        console2.log("Final owner:", config.finalOwner);
        console2.log("Strategist:", config.strategist);
        console2.log("Guardian:", config.guardian);
        console2.log("Deposit cap:", config.depositCap);
        console2.log("Risk max allocation bps:", INITIAL_MAX_ALLOCATION_BPS);
        console2.log("Strategy global cap bps:", INITIAL_GLOBAL_ALLOCATION_CAP_BPS);
        console2.log("Strategy paused:", strategy.rebalancePaused());
        console2.log("Strategy attached:", address(vault.strategy()));
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envUint("PRIVATE_KEY");
        config.broadcaster = vm.addr(config.deployerKey);
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.oracleRouterAddress = vm.envAddress("ORACLE_ROUTER_ADDRESS");
        config.finalOwner = vm.envAddress("FINAL_OWNER");
        config.guardian = vm.envAddress("GUARDIAN");
        config.strategist = vm.envAddress("STRATEGIST");
        config.vaultName = vm.envOr("VAULT_NAME", string("Helix USDC.e Smart Vault"));
        config.vaultSymbol = vm.envOr("VAULT_SYMBOL", string("HLX-USDCe-Shell"));
        config.depositCap = vm.envOr("DEPOSIT_CAP", DEFAULT_DEPOSIT_CAP);
    }

    function _validateLaunchSurface(
        VaultFactory vaultFactory,
        RiskEngine riskEngine,
        OracleRouter oracleRouter,
        Config memory config
    ) internal view {
        if (
            config.finalOwner == address(0) || config.finalOwner == config.broadcaster
                || config.guardian == address(0) || config.strategist == address(0)
        ) {
            revert("DeployCitreaUsdcAllocatorShell requires distinct non-zero roles");
        }
        if (vaultFactory.owner() != config.broadcaster) {
            revert("Broadcaster must own VaultFactory");
        }
        if (riskEngine.owner() != config.broadcaster) {
            revert("Broadcaster must own RiskEngine");
        }
        if (oracleRouter.owner() != config.broadcaster) {
            revert("Broadcaster must own OracleRouter");
        }
        if (IERC20Metadata(CITREA_USDCE).decimals() != CITREA_USDCE_DECIMALS) {
            revert("Unexpected USDC.e decimals");
        }
        oracleRouter.getPrice(CITREA_USDCE);
    }
}
