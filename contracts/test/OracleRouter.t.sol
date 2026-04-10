// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { OracleRouter } from "../src/core/OracleRouter.sol";
import {
    AggregatorV3OracleAdapter,
    IAggregatorV3Feed
} from "../src/oracles/AggregatorV3OracleAdapter.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract MockAggregatorV3Feed {
    uint8 public immutable decimals;

    int256 private _answer;
    uint256 private _updatedAt;

    constructor(
        uint8 decimals_,
        int256 answer_
    ) {
        decimals = decimals_;
        _answer = answer_;
        _updatedAt = block.timestamp;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (1, _answer, _updatedAt, _updatedAt, 1);
    }

    function setRoundData(
        int256 answer_,
        uint256 updatedAt_
    ) external {
        _answer = answer_;
        _updatedAt = updatedAt_;
    }
}

contract OracleRouterTest is Test {
    address internal constant OTHER = address(0xB0B);

    MockERC20 internal asset;
    OracleRouter internal router;
    MockOracle internal oracle;
    MockAggregatorV3Feed internal aggregatorFeed;
    AggregatorV3OracleAdapter internal aggregatorAdapter;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        router = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        aggregatorFeed = new MockAggregatorV3Feed(8, 99_980_000);
        aggregatorAdapter =
            new AggregatorV3OracleAdapter(IAggregatorV3Feed(address(aggregatorFeed)));
    }

    function testReturnsFreshPriceAndQuote() public {
        router.setOracle(address(asset), address(oracle), 1 days);

        (uint256 price, uint256 updatedAt) = router.getPrice(address(asset));
        assertEq(price, 300e18);
        assertEq(updatedAt, block.timestamp);

        uint256 quotedValue = router.quoteAsset(address(asset), 2e18);
        assertEq(quotedValue, 600e18);
    }

    function testReturnsFreshPriceFromAggregatorAdapter() public {
        router.setOracle(address(asset), address(aggregatorAdapter), 1 days);

        (uint256 price, uint256 updatedAt) = router.getPrice(address(asset));
        assertEq(price, 9998e14);
        assertEq(updatedAt, block.timestamp);

        uint256 quotedValue = router.quoteAsset(address(asset), 2e18);
        assertEq(quotedValue, 19_996e14);
    }

    function testRevertsOnStalePrice() public {
        router.setOracle(address(asset), address(oracle), 1 hours);
        vm.warp(3 hours);
        oracle.setPriceWithTimestamp(300e18, uint48(block.timestamp - 2 hours));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StalePrice.selector,
                address(asset),
                block.timestamp - 2 hours,
                block.timestamp,
                1 hours
            )
        );
        router.getPrice(address(asset));
    }

    function testRevertsOnZeroPrice() public {
        router.setOracle(address(asset), address(oracle), 1 days);
        oracle.setPrice(0);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPrice.selector, address(asset)));
        router.getPrice(address(asset));
    }

    function testOnlyOwnerCanSetOracle() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, OTHER));
        vm.prank(OTHER);
        router.setOracle(address(asset), address(oracle), 1 days);
    }
}
