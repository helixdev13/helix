// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import {
    AggregatorV3OracleAdapter,
    IAggregatorV3Feed
} from "../src/oracles/AggregatorV3OracleAdapter.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";

contract ConfigureCitreaUsdcWcBtcOracles is Script {
    uint256 public constant CITREA_MAINNET_CHAIN_ID = 4114;
    address public constant CITREA_USDCE = 0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839;
    address public constant CITREA_WCBTC = 0x3100000000000000000000000000000000000006;
    address public constant REDSTONE_USDC_USD_FEED = 0xf0DEbDAE819b354D076b0D162e399BE013A856d3;
    address public constant REDSTONE_BTC_USD_FEED = 0xc555c100DB24dF36D406243642C169CC5A937f09;
    uint48 public constant PRODUCTION_HEARTBEAT = 6 hours;

    struct Config {
        uint256 deployerKey;
        address broadcaster;
        address oracleRouterAddress;
    }

    function run()
        external
        returns (
            AggregatorV3OracleAdapter usdcOracleAdapter,
            AggregatorV3OracleAdapter btcOracleAdapter
        )
    {
        if (block.chainid != CITREA_MAINNET_CHAIN_ID) {
            revert("ConfigureCitreaUsdcWcBtcOracles must run on Citrea Mainnet");
        }

        Config memory config = _loadConfig();
        OracleRouter oracleRouter = OracleRouter(config.oracleRouterAddress);
        if (oracleRouter.owner() != config.broadcaster) {
            revert("Broadcaster must own OracleRouter to configure candidate feeds");
        }

        vm.startBroadcast(config.deployerKey);

        usdcOracleAdapter = new AggregatorV3OracleAdapter(IAggregatorV3Feed(REDSTONE_USDC_USD_FEED));
        btcOracleAdapter = new AggregatorV3OracleAdapter(IAggregatorV3Feed(REDSTONE_BTC_USD_FEED));

        oracleRouter.setOracle(CITREA_USDCE, address(usdcOracleAdapter), PRODUCTION_HEARTBEAT);
        oracleRouter.setOracle(CITREA_WCBTC, address(btcOracleAdapter), PRODUCTION_HEARTBEAT);

        vm.stopBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("OracleRouter:", address(oracleRouter));
        console2.log("USDC.e asset:", CITREA_USDCE);
        console2.log("USDC/USD source feed:", REDSTONE_USDC_USD_FEED);
        console2.log("USDC.e oracle adapter:", address(usdcOracleAdapter));
        console2.log("wcBTC asset:", CITREA_WCBTC);
        console2.log("BTC/USD source feed:", REDSTONE_BTC_USD_FEED);
        console2.log("wcBTC oracle adapter:", address(btcOracleAdapter));
        console2.log("Heartbeat:", PRODUCTION_HEARTBEAT);
    }

    function _loadConfig() internal view returns (Config memory config) {
        config.deployerKey = vm.envUint("PRIVATE_KEY");
        config.broadcaster = vm.addr(config.deployerKey);
        config.oracleRouterAddress = vm.envAddress("ORACLE_ROUTER_ADDRESS");
    }
}
