// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { MockClStrategy } from "../src/strategies/MockClStrategy.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract MockClStrategyTest is Test {
    address internal constant VAULT = address(0xCAFE);
    address internal constant USER = address(0xB0B);

    MockERC20 internal asset;
    MockClStrategy internal strategy;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        strategy = new MockClStrategy(asset, VAULT);

        asset.mint(VAULT, 1000e18);
        vm.prank(VAULT);
        asset.approve(address(strategy), type(uint256).max);
    }

    function testOnlyVaultCanDepositAndWithdraw() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.deposit(1e18);

        vm.prank(VAULT);
        strategy.deposit(100e18);
        assertEq(strategy.totalAssets(), 100e18);

        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.withdraw(1e18, USER);
    }

    function testProfitLossAndUnwindFlow() public {
        vm.prank(VAULT);
        strategy.deposit(100e18);

        deal(address(asset), address(strategy), 120e18, true);
        assertEq(strategy.totalAssets(), 120e18);

        deal(address(asset), address(strategy), 90e18, true);
        assertEq(strategy.totalAssets(), 90e18);

        vm.prank(VAULT);
        strategy.unwindAll();

        assertEq(strategy.totalAssets(), 0);
        assertEq(asset.balanceOf(VAULT), 990e18);
    }

    function testHarvestCallableOnlyByVault() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.harvest();

        vm.prank(VAULT);
        strategy.harvest();
    }

    function testStrategyIsBoundToExactVaultAndAsset() public view {
        assertEq(strategy.vault(), VAULT);
        assertEq(strategy.asset(), address(asset));
    }
}
