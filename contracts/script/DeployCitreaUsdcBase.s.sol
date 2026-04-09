// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";

contract DeployCitreaUsdcBase is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;
    address public constant CITREA_USDCE = 0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839;
    uint8 public constant CITREA_USDCE_DECIMALS = 6;
    uint16 public constant INITIAL_MAX_ALLOCATION_BPS = 0;
    uint256 public constant DEFAULT_DEPOSIT_CAP = 25_000e6;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address vaultFactoryAddress;
        address initialOwner;
        address guardian;
        string vaultName;
        string vaultSymbol;
        uint256 depositCap;
    }

    function run() external returns (HelixVault vault, RiskEngine riskEngine) {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("DeployCitreaUsdcBase must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        riskEngine = RiskEngine(address(vaultFactory.RISK_ENGINE()));
        IERC20Metadata asset = IERC20Metadata(CITREA_USDCE);

        if (config.initialOwner == address(0) || config.guardian == address(0)) {
            revert("DeployCitreaUsdcBase requires non-zero owner and guardian");
        }
        if (vaultFactory.owner() != config.broadcaster) {
            revert("DeployCitreaUsdcBase requires broadcaster to own VaultFactory");
        }
        if (riskEngine.owner() != config.broadcaster) {
            revert("DeployCitreaUsdcBase requires broadcaster to own RiskEngine");
        }
        if (asset.decimals() != CITREA_USDCE_DECIMALS) {
            revert("Unexpected USDC.e decimals");
        }

        vm.startBroadcast(config.deployerKey);

        vault = vaultFactory.createVault(
            IERC20(address(asset)),
            config.initialOwner,
            config.guardian,
            config.vaultName,
            config.vaultSymbol
        );

        riskEngine.setConfig(
            address(vault), config.depositCap, INITIAL_MAX_ALLOCATION_BPS, false, false
        );

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("Asset (USDC.e):", address(asset));
        console2.log("Asset decimals:", asset.decimals());
        console2.log("VaultFactory:", address(vaultFactory));
        console2.log("RiskEngine:", address(riskEngine));
        console2.log("Vault:", address(vault));
        console2.log("Vault owner:", config.initialOwner);
        console2.log("Vault guardian:", config.guardian);
        console2.log("Deposit cap:", config.depositCap);
        console2.log("Max allocation bps:", INITIAL_MAX_ALLOCATION_BPS);
        console2.log("Paused:", false);
        console2.log("Withdraw only:", false);
        console2.log("Strategy attached:", address(vault.strategy()));
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envUint("PRIVATE_KEY");
        config.broadcaster = vm.addr(config.deployerKey);
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.initialOwner = vm.envAddress("INITIAL_OWNER");
        config.guardian = vm.envAddress("GUARDIAN");
        config.vaultName = vm.envOr("VAULT_NAME", string("Helix USDC.e Base"));
        config.vaultSymbol = vm.envOr("VAULT_SYMBOL", string("HLX-USDCe-Base"));
        config.depositCap = vm.envOr("DEPOSIT_CAP", DEFAULT_DEPOSIT_CAP);
    }
}
