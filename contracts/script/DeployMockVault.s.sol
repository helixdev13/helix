// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockClStrategy } from "../src/strategies/MockClStrategy.sol";

contract DeployMockVault is Script {
    uint256 internal constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address initialOwner;
        address guardian;
        address mockAssetAddress;
        address vaultFactoryAddress;
        string vaultName;
        string vaultSymbol;
        string assetName;
        string assetSymbol;
        uint8 assetDecimals;
        uint256 depositCap;
        uint16 maxAllocationBps;
        bool paused;
        bool withdrawOnly;
        bool seedDemo;
        uint256 seedAmount;
        uint256 allocateAmount;
        uint256 demoProfit;
    }

    function run()
        external
        returns (
            IERC20Metadata asset,
            HelixVault vault,
            MockClStrategy strategy,
            RiskEngine riskEngine
        )
    {
        Config memory config = _loadConfig();
        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        riskEngine = RiskEngine(address(vaultFactory.RISK_ENGINE()));
        MockERC20 deployedMockAsset;

        if (config.initialOwner != config.broadcaster) {
            revert("DeployMockVault requires broadcaster to be the initial owner");
        }
        if (config.seedDemo && config.mockAssetAddress != address(0)) {
            revert("Seeded demo only supported when DeployMockVault deploys the mock asset");
        }

        vm.startBroadcast(config.deployerKey);

        if (config.mockAssetAddress == address(0)) {
            deployedMockAsset =
                new MockERC20(config.assetName, config.assetSymbol, config.assetDecimals);
            asset = IERC20Metadata(address(deployedMockAsset));
        } else {
            asset = IERC20Metadata(config.mockAssetAddress);
        }

        vault = vaultFactory.createVault(
            asset, config.initialOwner, config.guardian, config.vaultName, config.vaultSymbol
        );
        strategy = new MockClStrategy(asset, address(vault));

        vault.setStrategy(strategy);
        riskEngine.setConfig(
            address(vault),
            config.depositCap,
            config.maxAllocationBps,
            config.paused,
            config.withdrawOnly
        );

        if (config.seedDemo) {
            deployedMockAsset.mint(config.broadcaster, config.seedAmount);
            IERC20(address(asset)).approve(address(vault), type(uint256).max);
            vault.deposit(config.seedAmount, config.broadcaster);

            if (config.allocateAmount != 0) {
                vault.allocateToStrategy(config.allocateAmount);
            }
            if (config.demoProfit != 0) {
                deployedMockAsset.mint(address(strategy), config.demoProfit);
            }
        }

        vm.stopBroadcast();

        console2.log("MockAsset:", address(asset));
        console2.log("Vault:", address(vault));
        console2.log("Strategy:", address(strategy));
        console2.log("RiskEngine:", address(riskEngine));
        console2.log("Seeded demo state:", config.seedDemo);
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envOr("PRIVATE_KEY", DEFAULT_ANVIL_PRIVATE_KEY);
        config.broadcaster = vm.addr(config.deployerKey);
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.initialOwner = vm.envOr("INITIAL_OWNER", config.broadcaster);
        config.guardian = vm.envOr("GUARDIAN", config.broadcaster);
        config.mockAssetAddress = vm.envOr("MOCK_ASSET_ADDRESS", address(0));
        config.vaultName = vm.envOr("VAULT_NAME", string("Helix Mock Vault"));
        config.vaultSymbol = vm.envOr("VAULT_SYMBOL", string("HLX-MOCK"));
        config.assetName = vm.envOr("MOCK_ASSET_NAME", string("Mock BNB Asset"));
        config.assetSymbol = vm.envOr("MOCK_ASSET_SYMBOL", string("mBNB"));
        config.assetDecimals = _resolveAssetDecimals(config.mockAssetAddress);
        config.depositCap = vm.envExists("DEPOSIT_CAP")
            ? vm.envUint("DEPOSIT_CAP")
            : _scaleWholeTokens(1_000_000, config.assetDecimals);
        config.maxAllocationBps = uint16(vm.envOr("MAX_ALLOCATION_BPS", uint256(8000)));
        config.paused = vm.envOr("PAUSED", false);
        config.withdrawOnly = vm.envOr("WITHDRAW_ONLY", false);
        config.seedDemo = vm.envOr("SEED_DEMO", false);
        config.seedAmount = vm.envExists("SEED_AMOUNT")
            ? vm.envUint("SEED_AMOUNT")
            : _scaleWholeTokens(100, config.assetDecimals);
        config.allocateAmount = vm.envExists("ALLOCATE_AMOUNT")
            ? vm.envUint("ALLOCATE_AMOUNT")
            : _scaleWholeTokens(60, config.assetDecimals);
        config.demoProfit = vm.envExists("DEMO_PROFIT")
            ? vm.envUint("DEMO_PROFIT")
            : _scaleWholeTokens(5, config.assetDecimals);
    }

    function _resolveAssetDecimals(
        address mockAssetAddress
    ) internal view returns (uint8 assetDecimals) {
        if (mockAssetAddress == address(0)) {
            return uint8(vm.envOr("MOCK_ASSET_DECIMALS", uint256(18)));
        }

        try IERC20Metadata(mockAssetAddress).decimals() returns (uint8 resolvedDecimals) {
            return resolvedDecimals;
        } catch {
            revert("DeployMockVault could not resolve decimals for MOCK_ASSET_ADDRESS");
        }
    }

    function _scaleWholeTokens(
        uint256 wholeTokens,
        uint8 assetDecimals
    ) internal pure returns (uint256) {
        return wholeTokens * (10 ** uint256(assetDecimals));
    }
}
