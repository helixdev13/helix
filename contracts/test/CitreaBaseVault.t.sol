// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockClStrategy } from "../src/strategies/MockClStrategy.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract CitreaBaseVaultTest is Test {
    uint256 internal constant DEPOSIT_CAP = 50_000e6;

    address internal owner;
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);

    MockERC20 internal ctusd;
    RiskEngine internal riskEngine;
    HelixVault internal vault;

    function setUp() public {
        owner = address(this);
        ctusd = new MockERC20("Citrea USD", "ctUSD", 6);
        riskEngine = new RiskEngine(owner);
        vault = new HelixVault(
            ctusd, riskEngine, owner, GUARDIAN, "Helix ctUSD Base", "HLX-ctUSD-Base"
        );

        riskEngine.setConfig(address(vault), DEPOSIT_CAP, 0, false, false);

        ctusd.mint(ALICE, 1_000_000_000);
        ctusd.mint(BOB, 1_000_000_000);

        vm.prank(ALICE);
        ctusd.approve(address(vault), type(uint256).max);
        vm.prank(BOB);
        ctusd.approve(address(vault), type(uint256).max);
    }

    function testSixDecimalDepositsAndWithdrawalsWorkWithoutStrategy() public {
        vm.prank(ALICE);
        uint256 shares = vault.deposit(100_000_000, ALICE);

        assertEq(vault.decimals(), 12);
        assertGt(shares, 0);
        assertEq(vault.totalIdle(), 100_000_000);
        assertEq(vault.totalStrategyAssets(), 0);
        assertEq(vault.totalAssets(), vault.totalIdle() + vault.totalStrategyAssets());
        assertEq(address(vault.strategy()), address(0));

        vm.prank(ALICE);
        uint256 assetsOut = vault.redeem(shares, ALICE, ALICE);

        assertEq(assetsOut, 100_000_000);
        assertEq(vault.totalAssets(), 0);
        assertEq(ctusd.balanceOf(ALICE), 1_000_000_000);
    }

    function testAllocationIsImpossibleWhenStrategyIsUnsetAndMaxAllocationIsZero() public {
        vm.prank(ALICE);
        vault.deposit(100_000_000, ALICE);

        assertEq(riskEngine.getMaxAllocationBps(address(vault)), 0);

        vm.expectRevert(Errors.StrategyNotSet.selector);
        vault.allocateToStrategy(1_000_000);
    }

    function testZeroMaxAllocationBlocksFutureAllocationEvenIfStrategyIsAttached() public {
        MockClStrategy strategy = new MockClStrategy(ctusd, address(vault));
        vault.setStrategy(strategy);

        vm.prank(ALICE);
        vault.deposit(100_000_000, ALICE);

        vm.expectRevert(abi.encodeWithSelector(Errors.AllocationCapExceeded.selector, 1_000_000, 0));
        vault.allocateToStrategy(1_000_000);
    }

    function testEmergencyPauseWithoutStrategyPreservesWithdrawals() public {
        vm.prank(ALICE);
        vault.deposit(100_000_000, ALICE);

        vm.prank(GUARDIAN);
        vault.emergencyPause();

        assertTrue(vault.paused());
        assertTrue(vault.withdrawOnly());
        assertEq(address(vault.strategy()), address(0));

        vm.expectRevert(Errors.DepositsDisabled.selector);
        vm.prank(BOB);
        vault.deposit(1_000_000, BOB);

        vm.prank(ALICE);
        vault.withdraw(40_000_000, ALICE, ALICE);

        assertEq(vault.totalIdle(), 60_000_000);
        assertEq(vault.totalStrategyAssets(), 0);
        assertEq(vault.totalAssets(), 60_000_000);
    }

    function testBaseVaultStateIsAuditableWithNoStrategy() public {
        vm.prank(ALICE);
        vault.deposit(125_000_000, ALICE);

        assertEq(vault.totalIdle(), 125_000_000);
        assertEq(vault.totalStrategyAssets(), 0);
        assertEq(vault.totalAssets(), 125_000_000);
        assertEq(vault.maxDeposit(BOB), DEPOSIT_CAP - 125_000_000);
        assertEq(vault.maxMint(BOB), vault.previewDeposit(vault.maxDeposit(BOB)));
        assertEq(vault.totalAssets(), vault.totalIdle() + vault.totalStrategyAssets());
    }
}
