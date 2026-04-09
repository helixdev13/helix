// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { JuiceSwapClAdapter } from "../src/adapters/JuiceSwapClAdapter.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { ManagedClStrategy } from "../src/strategies/ManagedClStrategy.sol";
import { IJuiceSwapFactory } from "../src/interfaces/venues/juiceswap/IJuiceSwapFactory.sol";
import { IJuiceSwapPool } from "../src/interfaces/venues/juiceswap/IJuiceSwapPool.sol";
import {
    IJuiceSwapPositionManager
} from "../src/interfaces/venues/juiceswap/IJuiceSwapPositionManager.sol";
import { IJuiceSwapSwapRouter } from "../src/interfaces/venues/juiceswap/IJuiceSwapSwapRouter.sol";

contract DeployCitreaJuiceSwapUsdcWcBtcCandidate is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;
    address public constant CITREA_USDCE = 0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839;
    address public constant CITREA_WCBTC = 0x3100000000000000000000000000000000000006;
    uint8 public constant CITREA_USDCE_DECIMALS = 6;
    uint8 public constant CITREA_WCBTC_DECIMALS = 18;
    address public constant JUICESWAP_FACTORY = 0xd809b1285aDd8eeaF1B1566Bf31B2B4C4Bba8e82;
    address public constant JUICESWAP_SWAP_ROUTER = 0x565eD3D57fe40f78A46f348C220121AE093c3cF8;
    address public constant JUICESWAP_POSITION_MANAGER = 0x3D3821D358f56395d4053954f98aec0E1F0fa568;
    address public constant JUICESWAP_USDCE_WCBTC_3000_POOL =
        0xD77f369715E227B93D48b09066640F46F0B01b29;
    uint24 public constant APPROVED_POOL_FEE = 3000;
    int24 public constant APPROVED_TICK_SPACING = 60;
    uint16 public constant INITIAL_MAX_ALLOCATION_BPS = 0;
    uint16 public constant DEFAULT_VALUATION_HAIRCUT_BPS = 500;
    uint16 public constant DEFAULT_MAX_PRICE_DEVIATION_BPS = 500;
    uint64 public constant DEFAULT_QUOTE_VALIDITY = 1 days;
    uint256 public constant DEFAULT_DEPOSIT_CAP = 25_000e6;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address vaultAddress;
        address oracleRouterAddress;
        address strategist;
        uint64 quoteValidity;
        uint16 valuationHaircutBps;
        uint16 maxPriceDeviationBps;
        uint256 depositCap;
    }

    function run()
        external
        returns (JuiceSwapClAdapter adapter, ManagedClStrategy strategy, RiskEngine riskEngine)
    {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("DeployCitreaJuiceSwapUsdcWcBtcCandidate must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        HelixVault vault = HelixVault(payable(config.vaultAddress));
        OracleRouter oracleRouter = OracleRouter(config.oracleRouterAddress);
        IJuiceSwapFactory factory = IJuiceSwapFactory(JUICESWAP_FACTORY);
        IJuiceSwapPool pool = IJuiceSwapPool(JUICESWAP_USDCE_WCBTC_3000_POOL);
        riskEngine = RiskEngine(address(vault.RISK_ENGINE()));

        _validateCandidateConfig(vault, riskEngine, oracleRouter, factory, pool, config);

        vm.startBroadcast(config.deployerKey);

        adapter = new JuiceSwapClAdapter(
            IERC20(CITREA_USDCE),
            IERC20(CITREA_WCBTC),
            factory,
            IJuiceSwapPositionManager(JUICESWAP_POSITION_MANAGER),
            IJuiceSwapSwapRouter(JUICESWAP_SWAP_ROUTER),
            oracleRouter,
            APPROVED_POOL_FEE,
            config.quoteValidity,
            config.valuationHaircutBps,
            config.maxPriceDeviationBps
        );

        strategy = new ManagedClStrategy(
            IERC20(CITREA_USDCE),
            address(vault),
            adapter,
            oracleRouter,
            vault.owner(),
            config.strategist,
            vault.guardian()
        );

        vault.setStrategy(strategy);
        riskEngine.setConfig(
            address(vault), config.depositCap, INITIAL_MAX_ALLOCATION_BPS, false, false
        );

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("Vault:", address(vault));
        console2.log("Vault asset:", vault.asset());
        console2.log("Vault owner:", vault.owner());
        console2.log("Vault guardian:", vault.guardian());
        console2.log("OracleRouter:", address(oracleRouter));
        console2.log("Factory:", JUICESWAP_FACTORY);
        console2.log("SwapRouter:", JUICESWAP_SWAP_ROUTER);
        console2.log("PositionManager:", JUICESWAP_POSITION_MANAGER);
        console2.log("Approved pool:", address(pool));
        console2.log("Approved pool fee:", APPROVED_POOL_FEE);
        console2.log("Approved tick spacing:", APPROVED_TICK_SPACING);
        console2.log("Adapter:", address(adapter));
        console2.log("Strategy:", address(strategy));
        console2.log("Strategist:", config.strategist);
        console2.log("Deposit cap:", config.depositCap);
        console2.log("Max allocation bps:", INITIAL_MAX_ALLOCATION_BPS);
        console2.log("Paused:", false);
        console2.log("Withdraw only:", false);
        console2.log("Strategy attached:", address(vault.strategy()));
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envUint("PRIVATE_KEY");
        config.broadcaster = vm.addr(config.deployerKey);
        config.vaultAddress = vm.envAddress("VAULT_ADDRESS");
        config.oracleRouterAddress = vm.envAddress("ORACLE_ROUTER_ADDRESS");
        config.strategist = vm.envAddress("STRATEGIST");
        config.quoteValidity = uint64(vm.envOr("QUOTE_VALIDITY", uint256(DEFAULT_QUOTE_VALIDITY)));
        config.valuationHaircutBps =
            uint16(vm.envOr("VALUATION_HAIRCUT_BPS", uint256(DEFAULT_VALUATION_HAIRCUT_BPS)));
        config.maxPriceDeviationBps =
            uint16(vm.envOr("MAX_PRICE_DEVIATION_BPS", uint256(DEFAULT_MAX_PRICE_DEVIATION_BPS)));
        config.depositCap = vm.envOr("DEPOSIT_CAP", DEFAULT_DEPOSIT_CAP);
    }

    function _validateCandidateConfig(
        HelixVault vault,
        RiskEngine riskEngine,
        OracleRouter oracleRouter,
        IJuiceSwapFactory factory,
        IJuiceSwapPool pool,
        Config memory config
    ) internal view {
        if (config.strategist == address(0)) {
            revert("DeployCitreaJuiceSwapUsdcWcBtcCandidate requires a strategist");
        }
        if (config.quoteValidity == 0) {
            revert("DeployCitreaJuiceSwapUsdcWcBtcCandidate requires non-zero quote validity");
        }
        if (vault.asset() != CITREA_USDCE) {
            revert("Vault asset must be USDC.e");
        }
        if (address(vault.strategy()) != address(0)) {
            revert("Vault already has a strategy");
        }
        if (vault.owner() != config.broadcaster) {
            revert("Broadcaster must own the vault to attach strategy");
        }
        if (riskEngine.owner() != config.broadcaster) {
            revert("Broadcaster must own RiskEngine to set launch config");
        }
        if (IERC20Metadata(CITREA_USDCE).decimals() != CITREA_USDCE_DECIMALS) {
            revert("Unexpected USDC.e decimals");
        }
        if (IERC20Metadata(CITREA_WCBTC).decimals() != CITREA_WCBTC_DECIMALS) {
            revert("Unexpected wcBTC decimals");
        }
        if (
            factory.getPool(CITREA_USDCE, CITREA_WCBTC, APPROVED_POOL_FEE)
                != JUICESWAP_USDCE_WCBTC_3000_POOL
        ) {
            revert("Approved JuiceSwap pool mismatch");
        }
        if (pool.token0() != CITREA_WCBTC || pool.token1() != CITREA_USDCE) {
            revert("Unexpected approved pool orientation");
        }
        if (pool.fee() != APPROVED_POOL_FEE || pool.tickSpacing() != APPROVED_TICK_SPACING) {
            revert("Unexpected approved pool metadata");
        }

        oracleRouter.getPrice(CITREA_USDCE);
        oracleRouter.getPrice(CITREA_WCBTC);
    }
}
