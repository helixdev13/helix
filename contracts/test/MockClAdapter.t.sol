// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { MockClAdapter } from "../src/adapters/MockClAdapter.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { Errors } from "../src/libraries/Errors.sol";
import { Types } from "../src/libraries/Types.sol";

contract MockClAdapterTest is Test {
    MockERC20 internal asset;
    MockClAdapter internal adapter;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        adapter = new MockClAdapter(asset, 1 hours);
        adapter.bindStrategy(address(this));

        asset.mint(address(this), 1000e18);
        asset.approve(address(adapter), type(uint256).max);
    }

    function testBindStrategyOnlyOnce() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyAlreadyBound.selector, address(this)));
        adapter.bindStrategy(address(this));
    }

    function testQuoteAndExecuteHappyPath() public {
        Types.RebalanceIntent memory intent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: 80e18,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 1 hours)
        });

        Types.RebalanceQuote memory quote = adapter.quoteRebalance(intent);
        Types.ExecutionLimits memory limits =
            Types.ExecutionLimits({ minAssetsOut: 0, maxLoss: 0, deadline: intent.deadline });

        Types.ExecutionReport memory report = adapter.executeRebalance(intent, quote, limits);

        assertEq(report.assetsIn, 80e18);
        assertEq(report.assetsOut, 0);
        assertEq(report.lossInAssets, 0);
        assertEq(asset.balanceOf(address(adapter)), 80e18);
        assertEq(adapter.valuation().grossAssets, 80e18);
    }

    function testForceInvalidQuoteBlocksExecution() public {
        Types.RebalanceIntent memory intent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: 40e18,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 1 hours)
        });

        Types.RebalanceQuote memory quote = adapter.quoteRebalance(intent);
        adapter.setForceQuoteInvalid(true);

        vm.expectRevert(Errors.QuoteInvalid.selector);
        adapter.executeRebalance(
            intent,
            quote,
            Types.ExecutionLimits({ minAssetsOut: 0, maxLoss: 0, deadline: intent.deadline })
        );
    }
}
