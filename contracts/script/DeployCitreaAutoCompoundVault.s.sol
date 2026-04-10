// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { JuiceSwapClAdapter } from "../src/adapters/JuiceSwapClAdapter.sol";
import { HelixVault } from "../src/HelixVault.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { RewardDistributor } from "../src/periphery/RewardDistributor.sol";
import { AutoCompoundClStrategy } from "../src/strategies/AutoCompoundClStrategy.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { IJuiceSwapFactory } from "../src/interfaces/venues/juiceswap/IJuiceSwapFactory.sol";
import { IJuiceSwapPool } from "../src/interfaces/venues/juiceswap/IJuiceSwapPool.sol";
import {
    IJuiceSwapPositionManager
} from "../src/interfaces/venues/juiceswap/IJuiceSwapPositionManager.sol";
import { IJuiceSwapSwapRouter } from "../src/interfaces/venues/juiceswap/IJuiceSwapSwapRouter.sol";

contract DeployCitreaAutoCompoundVault is Script {
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
    uint48 public constant PRODUCTION_HEARTBEAT = 6 hours;
    uint16 public constant INITIAL_MAX_ALLOCATION_BPS = 0;
    uint16 public constant DEFAULT_VALUATION_HAIRCUT_BPS = 500;
    uint16 public constant DEFAULT_MAX_PRICE_DEVIATION_BPS = 500;
    uint64 public constant DEFAULT_QUOTE_VALIDITY = 1 days;
    uint256 public constant DEFAULT_DEPOSIT_CAP = 25_000e6;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address vaultFactoryAddress;
        address oracleRouterAddress;
        address finalOwner;
        address guardian;
        address strategist;
        address feeRecipient;
        uint64 quoteValidity;
        uint16 valuationHaircutBps;
        uint16 maxPriceDeviationBps;
        uint256 depositCap;
        string vaultName;
        string vaultSymbol;
    }

    function run()
        external
        returns (
            HLXToken hlxToken,
            HelixVault vault,
            JuiceSwapClAdapter adapter,
            AutoCompoundClStrategy strategy,
            RewardDistributor rewardDistributor,
            RiskEngine riskEngine
        )
    {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("DeployCitreaAutoCompoundVault must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        VaultFactory vaultFactory = VaultFactory(config.vaultFactoryAddress);
        OracleRouter oracleRouter = OracleRouter(config.oracleRouterAddress);
        riskEngine = RiskEngine(address(vaultFactory.RISK_ENGINE()));
        IJuiceSwapFactory factory = IJuiceSwapFactory(JUICESWAP_FACTORY);
        IJuiceSwapPool pool = IJuiceSwapPool(JUICESWAP_USDCE_WCBTC_3000_POOL);

        _validateLaunchSurface(vaultFactory, riskEngine, oracleRouter, factory, pool, config);

        vm.startBroadcast(config.deployerKey);

        hlxToken = new HLXToken(config.broadcaster);

        vault = vaultFactory.createVault(
            IERC20(CITREA_USDCE),
            config.broadcaster,
            config.guardian,
            config.vaultName,
            config.vaultSymbol
        );
        if (
            vault.owner() != config.broadcaster || vault.guardian() != config.guardian
                || address(vault.strategy()) != address(0)
        ) {
            revert("Vault deployment state mismatch");
        }

        riskEngine.setConfig(
            address(vault), config.depositCap, INITIAL_MAX_ALLOCATION_BPS, false, false
        );
        if (
            riskEngine.getDepositCap(address(vault)) != config.depositCap
                || riskEngine.getMaxAllocationBps(address(vault)) != INITIAL_MAX_ALLOCATION_BPS
                || riskEngine.isPaused(address(vault))
                || riskEngine.isWithdrawOnly(address(vault))
        ) {
            revert("RiskEngine launch config mismatch");
        }

        adapter = _deployAdapter(config, oracleRouter);

        rewardDistributor = _deployRewardDistributor(config, hlxToken, vault);

        strategy = _deployStrategy(config, hlxToken, vault, adapter, oracleRouter, rewardDistributor);

        vault.setStrategy(strategy);
        if (address(vault.strategy()) != address(strategy)) {
            revert("Vault strategy attachment failed");
        }

        hlxToken.grantRole(MINTER_ROLE, address(strategy));
        hlxToken.grantRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.finalOwner);
        hlxToken.revokeRole(MINTER_ROLE, config.broadcaster);
        hlxToken.revokeRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.broadcaster);
        if (
            !hlxToken.hasRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.finalOwner)
                || hlxToken.hasRole(hlxToken.DEFAULT_ADMIN_ROLE(), config.broadcaster)
                || hlxToken.hasRole(MINTER_ROLE, config.broadcaster)
                || !hlxToken.hasRole(MINTER_ROLE, address(strategy))
        ) {
            revert("HLX token role handoff mismatch");
        }

        vaultFactory.transferOwnership(config.finalOwner);
        riskEngine.transferOwnership(config.finalOwner);
        oracleRouter.transferOwnership(config.finalOwner);
        vault.transferOwnership(config.finalOwner);
        strategy.transferOwnership(config.finalOwner);
        rewardDistributor.transferOwnership(config.finalOwner);

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("VaultFactory:", address(vaultFactory));
        console2.log("RiskEngine:", address(riskEngine));
        console2.log("OracleRouter:", address(oracleRouter));
        console2.log("Vault:", address(vault));
        console2.log("HLXToken:", address(hlxToken));
        console2.log("Adapter:", address(adapter));
        console2.log("Strategy:", address(strategy));
        console2.log("RewardDistributor:", address(rewardDistributor));
        console2.log("Final owner:", config.finalOwner);
        console2.log("Strategist:", config.strategist);
        console2.log("Guardian:", config.guardian);
        console2.log("Fee recipient:", config.feeRecipient);
        console2.log("Deposit cap:", config.depositCap);
        console2.log("Max allocation bps:", INITIAL_MAX_ALLOCATION_BPS);
        console2.log("Paused:", false);
        console2.log("Withdraw only:", false);
        console2.log("Strategy attached:", address(vault.strategy()));
        console2.log("VaultFactory pending owner:", vaultFactory.pendingOwner());
        console2.log("RiskEngine pending owner:", riskEngine.pendingOwner());
        console2.log("OracleRouter pending owner:", oracleRouter.pendingOwner());
        console2.log("Vault pending owner:", vault.pendingOwner());
        console2.log("Strategy pending owner:", strategy.pendingOwner());
        console2.log("RewardDistributor pending owner:", rewardDistributor.pendingOwner());
        console2.log("HLX admin:", config.finalOwner);
        console2.log("HLX minter:", address(strategy));
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envUint("PRIVATE_KEY");
        config.broadcaster = vm.addr(config.deployerKey);
        config.vaultFactoryAddress = vm.envAddress("VAULT_FACTORY_ADDRESS");
        config.oracleRouterAddress = vm.envAddress("ORACLE_ROUTER_ADDRESS");
        config.finalOwner = vm.envAddress("FINAL_OWNER");
        config.guardian = vm.envAddress("GUARDIAN");
        config.strategist = vm.envAddress("STRATEGIST");
        config.feeRecipient = vm.envOr("FEE_RECIPIENT", config.finalOwner);
        config.quoteValidity = uint64(vm.envOr("QUOTE_VALIDITY", uint256(DEFAULT_QUOTE_VALIDITY)));
        config.valuationHaircutBps =
            uint16(vm.envOr("VALUATION_HAIRCUT_BPS", uint256(DEFAULT_VALUATION_HAIRCUT_BPS)));
        config.maxPriceDeviationBps =
            uint16(vm.envOr("MAX_PRICE_DEVIATION_BPS", uint256(DEFAULT_MAX_PRICE_DEVIATION_BPS)));
        config.depositCap = vm.envOr("DEPOSIT_CAP", DEFAULT_DEPOSIT_CAP);
        config.vaultName = vm.envOr("VAULT_NAME", string("Helix USDC.e Smart Vault"));
        config.vaultSymbol = vm.envOr("VAULT_SYMBOL", string("HLX-USDCe-SV"));
    }

    function _validateLaunchSurface(
        VaultFactory vaultFactory,
        RiskEngine riskEngine,
        OracleRouter oracleRouter,
        IJuiceSwapFactory factory,
        IJuiceSwapPool pool,
        Config memory config
    ) internal view {
        if (
            config.finalOwner == address(0) || config.finalOwner == config.broadcaster
                || config.guardian == address(0) || config.strategist == address(0)
                || config.feeRecipient == address(0)
        ) {
            revert("DeployCitreaAutoCompoundVault requires distinct non-zero roles");
        }
        if (config.quoteValidity == 0) {
            revert("DeployCitreaAutoCompoundVault requires non-zero quote validity");
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
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = 1800;
        secondsAgos[1] = 0;
        pool.observe(secondsAgos);

        oracleRouter.getPrice(CITREA_USDCE);
        oracleRouter.getPrice(CITREA_WCBTC);

        if (
            oracleRouter.getConfig(CITREA_USDCE).heartbeat != PRODUCTION_HEARTBEAT
                || oracleRouter.getConfig(CITREA_WCBTC).heartbeat != PRODUCTION_HEARTBEAT
        ) {
            revert("Unexpected oracle heartbeat");
        }
    }

    function _deployAdapter(
        Config memory config,
        OracleRouter oracleRouter
    ) internal returns (JuiceSwapClAdapter adapter) {
        IJuiceSwapFactory factory = IJuiceSwapFactory(JUICESWAP_FACTORY);
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
    }

    function _deployRewardDistributor(
        Config memory config,
        HLXToken hlxToken,
        HelixVault vault
    ) internal returns (RewardDistributor rewardDistributor) {
        rewardDistributor =
            new RewardDistributor(address(vault), address(hlxToken), config.broadcaster);
        if (
            rewardDistributor.owner() != config.broadcaster
                || address(rewardDistributor.STAKING_TOKEN()) != address(vault)
                || address(rewardDistributor.REWARD_TOKEN()) != address(hlxToken)
        ) {
            revert("RewardDistributor deployment state mismatch");
        }
    }

    function _deployStrategy(
        Config memory config,
        HLXToken hlxToken,
        HelixVault vault,
        JuiceSwapClAdapter adapter,
        OracleRouter oracleRouter,
        RewardDistributor rewardDistributor
    ) internal returns (AutoCompoundClStrategy strategy) {
        strategy = new AutoCompoundClStrategy(
            IERC20(CITREA_USDCE),
            address(vault),
            adapter,
            oracleRouter,
            config.broadcaster,
            config.strategist,
            config.guardian,
            config.feeRecipient,
            hlxToken,
            address(rewardDistributor)
        );
        if (
            strategy.owner() != config.broadcaster || strategy.vault() != address(vault)
                || strategy.asset() != CITREA_USDCE || strategy.adapter() != address(adapter)
                || address(adapter.strategy()) != address(strategy)
        ) {
            revert("Strategy deployment state mismatch");
        }
    }
}
