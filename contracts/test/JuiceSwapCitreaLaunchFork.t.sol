// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IJuiceSwapFactory } from "../src/interfaces/venues/juiceswap/IJuiceSwapFactory.sol";
import { IJuiceSwapPool } from "../src/interfaces/venues/juiceswap/IJuiceSwapPool.sol";

contract JuiceSwapCitreaLaunchForkTest is Test {
    uint256 internal constant CITREA_MAINNET_CHAIN_ID = 4114;
    address internal constant CITREA_USDCE = 0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839;
    address internal constant CITREA_WCBTC = 0x3100000000000000000000000000000000000006;
    address internal constant JUICESWAP_FACTORY = 0xd809b1285aDd8eeaF1B1566Bf31B2B4C4Bba8e82;
    address internal constant APPROVED_POOL = 0xD77f369715E227B93D48b09066640F46F0B01b29;
    address internal constant ALTERNATE_POOL = 0x43AAec0c03d56f3839b0467240ea01a86774c0a7;
    uint24 internal constant APPROVED_POOL_FEE = 3000;

    function testCitreaLiveCandidatePoolMetadata() public {
        string memory rpcUrl = vm.envOr("CITREA_RPC_URL", string(""));
        if (bytes(rpcUrl).length == 0) {
            return;
        }

        vm.createSelectFork(rpcUrl);

        IJuiceSwapFactory factory = IJuiceSwapFactory(JUICESWAP_FACTORY);
        IJuiceSwapPool pool = IJuiceSwapPool(APPROVED_POOL);

        assertEq(block.chainid, CITREA_MAINNET_CHAIN_ID);
        assertEq(IERC20Metadata(CITREA_USDCE).decimals(), 6);
        assertEq(IERC20Metadata(CITREA_WCBTC).decimals(), 18);
        assertEq(factory.feeAmountTickSpacing(APPROVED_POOL_FEE), 60);
        assertEq(factory.getPool(CITREA_USDCE, CITREA_WCBTC, 500), address(0));
        assertEq(factory.getPool(CITREA_USDCE, CITREA_WCBTC, APPROVED_POOL_FEE), APPROVED_POOL);
        assertEq(factory.getPool(CITREA_USDCE, CITREA_WCBTC, 10_000), ALTERNATE_POOL);
        assertTrue(ALTERNATE_POOL != APPROVED_POOL);

        assertEq(pool.token0(), CITREA_WCBTC);
        assertEq(pool.token1(), CITREA_USDCE);
        assertEq(pool.fee(), APPROVED_POOL_FEE);
        assertEq(pool.tickSpacing(), 60);
    }
}
