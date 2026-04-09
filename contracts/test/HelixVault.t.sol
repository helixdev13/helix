// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { MockClStrategy } from "../src/strategies/MockClStrategy.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract HelixVaultTest is Test {
    uint256 internal constant CAP = 1_000_000e18;

    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant ATTACKER = address(0xBAD);

    MockERC20 internal asset;
    RiskEngine internal riskEngine;
    HelixVault internal vault;
    MockClStrategy internal strategy;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        riskEngine = new RiskEngine(address(this));

        vault = new HelixVault(asset, riskEngine, address(this), GUARDIAN, "Helix Vault", "HLX");
        strategy = new MockClStrategy(asset, address(vault));

        vault.setStrategy(strategy);
        riskEngine.setConfig(address(vault), CAP, 8000, false, false);

        asset.mint(ALICE, 1000e18);
        asset.mint(BOB, 1000e18);
        asset.mint(ATTACKER, 1000e18);

        vm.prank(ALICE);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(BOB);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(ATTACKER);
        asset.approve(address(vault), type(uint256).max);
    }

    function testDepositAndWithdrawIdleAssets() public {
        uint256 previewedShares = vault.previewDeposit(100e18);

        vm.prank(ALICE);
        uint256 mintedShares = vault.deposit(100e18, ALICE);

        assertEq(mintedShares, previewedShares);
        assertEq(vault.totalAssets(), 100e18);
        assertEq(vault.balanceOf(ALICE), mintedShares);

        vm.prank(ALICE);
        uint256 burnedShares = vault.withdraw(40e18, ALICE, ALICE);

        assertEq(burnedShares, vault.previewWithdraw(40e18));
        assertEq(vault.totalAssets(), 60e18);
        assertEq(asset.balanceOf(ALICE), 940e18);
    }

    function testDepositCapIsEnforced() public {
        riskEngine.setDepositCap(address(vault), 100e18);

        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);

        vm.expectRevert(abi.encodeWithSelector(Errors.DepositCapExceeded.selector, 101e18, 100e18));
        vm.prank(BOB);
        vault.deposit(1e18, BOB);
    }

    function testDepositRevertsWhenDepositCapIsZero() public {
        riskEngine.setDepositCap(address(vault), 0);

        vm.expectRevert(Errors.DepositsDisabled.selector);
        vm.prank(ALICE);
        vault.deposit(1e18, ALICE);
    }

    function testMintRevertsWhenDepositCapIsZero() public {
        riskEngine.setDepositCap(address(vault), 0);

        vm.expectRevert(Errors.DepositsDisabled.selector);
        vm.prank(ALICE);
        vault.mint(1e18, ALICE);
    }

    function testMaxDepositAndMaxMintAreZeroWhenDepositCapIsZero() public {
        riskEngine.setDepositCap(address(vault), 0);

        assertEq(vault.maxDeposit(ALICE), 0);
        assertEq(vault.maxMint(ALICE), 0);
    }

    function testAllocateAndWithdrawPullsFromStrategy() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);

        vault.allocateToStrategy(60e18);
        assertEq(vault.totalIdle(), 40e18);
        assertEq(strategy.totalAssets(), 60e18);
        assertEq(vault.totalStrategyAssets(), 60e18);
        assertEq(vault.totalAssets(), vault.totalIdle() + vault.totalStrategyAssets());
        assertEq(asset.balanceOf(address(vault)), 40e18);

        vm.prank(ALICE);
        vault.withdraw(80e18, ALICE, ALICE);

        assertEq(strategy.totalAssets(), 20e18);
        assertEq(vault.totalAssets(), 20e18);
        assertEq(asset.balanceOf(ALICE), 980e18);
    }

    function testEmergencyPauseUnwindsStrategyAndPreservesWithdrawals() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vault.allocateToStrategy(60e18);

        vm.prank(GUARDIAN);
        vault.emergencyPause();

        assertTrue(vault.paused());
        assertTrue(vault.withdrawOnly());
        assertEq(strategy.totalAssets(), 0);
        assertEq(asset.balanceOf(address(vault)), 100e18);

        vm.expectRevert(Errors.DepositsDisabled.selector);
        vm.prank(BOB);
        vault.deposit(1e18, BOB);

        vm.prank(ALICE);
        vault.withdraw(50e18, ALICE, ALICE);

        assertEq(vault.totalAssets(), 50e18);
        assertEq(asset.balanceOf(ALICE), 950e18);
    }

    function testWithdrawOnlyBlocksDepositsAndAllocations() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);

        vm.prank(GUARDIAN);
        vault.setWithdrawOnly(true);

        assertTrue(vault.withdrawOnly());

        vm.expectRevert(Errors.DepositsDisabled.selector);
        vm.prank(BOB);
        vault.deposit(1e18, BOB);

        vm.expectRevert(Errors.AllocationDisabled.selector);
        vault.allocateToStrategy(10e18);

        vm.prank(ALICE);
        vault.withdraw(20e18, ALICE, ALICE);
        assertEq(vault.totalAssets(), 80e18);
    }

    function testGuardianCannotDisableWithdrawOnly() public {
        vm.prank(GUARDIAN);
        vault.setWithdrawOnly(true);

        vm.expectRevert(Errors.OnlyOwnerCanDisable.selector);
        vm.prank(GUARDIAN);
        vault.setWithdrawOnly(false);
    }

    function testLossScenarioReducesWithdrawCapacity() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vault.allocateToStrategy(80e18);

        deal(address(asset), address(strategy), 60e18, true);

        assertEq(strategy.totalAssets(), 60e18);
        assertEq(vault.totalAssets(), 80e18);
        assertLt(vault.maxWithdraw(ALICE), 100e18);

        vm.prank(ALICE);
        vault.withdraw(80e18, ALICE, ALICE);

        assertEq(vault.totalAssets(), 0);
        assertEq(asset.balanceOf(ALICE), 980e18);
    }

    function testPreviewWithdrawRoundsUpAfterProfit() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vault.allocateToStrategy(50e18);
        deal(address(asset), address(strategy), 57e18, true);

        uint256 floorShares = vault.convertToShares(3e18);
        uint256 ceilShares = vault.previewWithdraw(3e18);

        assertGe(ceilShares, floorShares);
        assertLe(ceilShares - floorShares, 1);
    }

    function testInflationDefenseKeepsVictimMintAboveZero() public {
        uint256 attackerStartingBalance = asset.balanceOf(ATTACKER);

        vm.prank(ATTACKER);
        vault.deposit(1e18, ATTACKER);

        vm.prank(ATTACKER);
        assertTrue(asset.transfer(address(vault), 100e18));

        assertGt(vault.previewDeposit(10e18), 0);

        vm.prank(BOB);
        vault.deposit(10e18, BOB);

        uint256 attackerShares = vault.balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        vault.redeem(attackerShares, ATTACKER, ATTACKER);

        assertLt(asset.balanceOf(ATTACKER), attackerStartingBalance);
        assertGt(vault.balanceOf(BOB), 0);
    }

    function testNonOwnerCannotAllocate() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        vault.allocateToStrategy(10e18);
    }

    function testThirdPartyRedeemConsumesShareAllowance() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);

        uint256 approvedShares = vault.balanceOf(ALICE) / 2;
        uint256 expectedAssets = vault.previewRedeem(approvedShares);

        vm.prank(ALICE);
        vault.approve(BOB, approvedShares);

        vm.prank(BOB);
        uint256 assetsReturned = vault.redeem(approvedShares, BOB, ALICE);

        assertEq(assetsReturned, expectedAssets);
        assertEq(vault.allowance(ALICE, BOB), 0);
        assertEq(asset.balanceOf(BOB), 1000e18 + expectedAssets);
    }

    function testRoundTripDepositWithdrawMonotonicity() public {
        uint256 startingBalance = asset.balanceOf(ALICE);

        vm.prank(ALICE);
        uint256 shares = vault.deposit(123e18, ALICE);

        vm.prank(ALICE);
        uint256 assetsReturned = vault.redeem(shares, ALICE, ALICE);

        assertEq(assetsReturned, 123e18);
        assertEq(asset.balanceOf(ALICE), startingBalance);
        assertEq(vault.totalAssets(), 0);
    }

    function testFuzzRoundTripRedeem(
        uint96 rawAssets
    ) public {
        uint256 assetsToDeposit = bound(uint256(rawAssets), 1e6, 500e18);
        uint256 startingBalance = asset.balanceOf(ALICE);

        vm.prank(ALICE);
        uint256 shares = vault.deposit(assetsToDeposit, ALICE);

        vm.prank(ALICE);
        uint256 assetsReturned = vault.redeem(shares, ALICE, ALICE);

        assertEq(assetsReturned, assetsToDeposit);
        assertEq(asset.balanceOf(ALICE), startingBalance);
        assertEq(vault.maxWithdraw(ALICE), 0);
        assertEq(vault.maxRedeem(ALICE), 0);
    }

    function testFuzzNoOverExtractionAcrossTwoUsers(
        uint96 rawAliceAssets,
        uint96 rawBobAssets,
        uint16 rawAllocationBps,
        bool redeemAliceFirst
    ) public {
        uint256 aliceAssets = bound(uint256(rawAliceAssets), 1e6, 400e18);
        uint256 bobAssets = bound(uint256(rawBobAssets), 1e6, 400e18);
        uint256 allocationBps = bound(uint256(rawAllocationBps), 0, 8000);

        vm.prank(ALICE);
        uint256 aliceShares = vault.deposit(aliceAssets, ALICE);
        vm.prank(BOB);
        uint256 bobShares = vault.deposit(bobAssets, BOB);

        uint256 combinedAssets = aliceAssets + bobAssets;
        uint256 allocation = combinedAssets * allocationBps / 10_000;
        if (allocation != 0) {
            vault.allocateToStrategy(allocation);
        }

        assertEq(vault.totalAssets(), vault.totalIdle() + vault.totalStrategyAssets());

        uint256 aliceBalanceBefore = asset.balanceOf(ALICE);
        uint256 bobBalanceBefore = asset.balanceOf(BOB);

        if (redeemAliceFirst) {
            vm.prank(ALICE);
            vault.redeem(aliceShares, ALICE, ALICE);
            vm.prank(BOB);
            vault.redeem(bobShares, BOB, BOB);
        } else {
            vm.prank(BOB);
            vault.redeem(bobShares, BOB, BOB);
            vm.prank(ALICE);
            vault.redeem(aliceShares, ALICE, ALICE);
        }

        assertEq(asset.balanceOf(ALICE), aliceBalanceBefore + aliceAssets);
        assertEq(asset.balanceOf(BOB), bobBalanceBefore + bobAssets);
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalIdle(), 0);
        assertEq(vault.totalStrategyAssets(), 0);
        assertEq(vault.totalAssets(), vault.totalIdle() + vault.totalStrategyAssets());
    }

    function testStrategyLossSocializationAcrossUsers() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vm.prank(BOB);
        vault.deposit(100e18, BOB);

        vault.allocateToStrategy(160e18);
        deal(address(asset), address(strategy), 120e18, true);

        assertEq(vault.totalAssets(), 160e18);
        assertEq(vault.maxWithdraw(ALICE), 80e18);
        assertEq(vault.maxWithdraw(BOB), 80e18);

        vm.prank(ALICE);
        vault.withdraw(80e18, ALICE, ALICE);
        vm.prank(BOB);
        vault.withdraw(80e18, BOB, BOB);

        assertEq(asset.balanceOf(ALICE), 980e18);
        assertEq(asset.balanceOf(BOB), 980e18);
        assertEq(vault.totalAssets(), 0);
    }

    function testPausedAndWithdrawOnlySemantics() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);

        riskEngine.setPause(address(vault), true);
        assertTrue(vault.paused());
        assertTrue(vault.withdrawOnly());
        assertEq(vault.maxDeposit(BOB), 0);
        assertEq(vault.maxMint(BOB), 0);

        vm.expectRevert(Errors.DepositsDisabled.selector);
        vm.prank(BOB);
        vault.deposit(1e18, BOB);

        vm.prank(ALICE);
        vault.withdraw(10e18, ALICE, ALICE);

        riskEngine.setPause(address(vault), false);
        riskEngine.setWithdrawOnly(address(vault), true);

        assertFalse(vault.paused());
        assertTrue(vault.withdrawOnly());
        assertEq(vault.maxDeposit(BOB), 0);

        vm.expectRevert(Errors.DepositsDisabled.selector);
        vm.prank(BOB);
        vault.mint(1e18, BOB);

        uint256 remainingShares = vault.balanceOf(ALICE);
        vm.prank(ALICE);
        vault.redeem(remainingShares, ALICE, ALICE);
    }

    function testStrategyReplacementBlockedWhileAssetsRemain() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vault.allocateToStrategy(50e18);

        MockClStrategy replacement = new MockClStrategy(asset, address(vault));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StrategyNotEmpty.selector, address(strategy), strategy.totalAssets()
            )
        );
        vault.setStrategy(replacement);
    }

    function testStrategyReplacementAllowedAfterUnwind() public {
        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vault.allocateToStrategy(50e18);
        vault.emergencyPause();

        MockClStrategy replacement = new MockClStrategy(asset, address(vault));
        vault.setStrategy(replacement);

        assertEq(address(vault.strategy()), address(replacement));
    }

    function testDepositCapEnforcementAfterGainAndLoss() public {
        riskEngine.setDepositCap(address(vault), 150e18);

        vm.prank(ALICE);
        vault.deposit(100e18, ALICE);
        vault.allocateToStrategy(80e18);

        deal(address(asset), address(strategy), 120e18, true);
        assertEq(vault.totalAssets(), 140e18);
        assertEq(vault.maxDeposit(BOB), 10e18);

        vm.expectRevert(abi.encodeWithSelector(Errors.DepositCapExceeded.selector, 151e18, 150e18));
        vm.prank(BOB);
        vault.deposit(11e18, BOB);

        deal(address(asset), address(strategy), 70e18, true);
        assertEq(vault.totalAssets(), 90e18);
        assertEq(vault.maxDeposit(BOB), 60e18);

        vm.prank(BOB);
        vault.deposit(60e18, BOB);
        assertEq(vault.totalAssets(), 150e18);
    }

    function testSixDecimalAssetOffsetBehavior() public {
        MockERC20 sixDecimalAsset = new MockERC20("USDC Mock", "mUSDC", 6);
        HelixVault sixDecimalVault = new HelixVault(
            sixDecimalAsset, riskEngine, address(this), GUARDIAN, "Helix USDC", "hUSDC"
        );
        MockClStrategy sixDecimalStrategy =
            new MockClStrategy(sixDecimalAsset, address(sixDecimalVault));

        sixDecimalVault.setStrategy(sixDecimalStrategy);
        riskEngine.setConfig(address(sixDecimalVault), 1_000_000e6, 8000, false, false);

        sixDecimalAsset.mint(ALICE, 1_000_000_000);
        vm.prank(ALICE);
        sixDecimalAsset.approve(address(sixDecimalVault), type(uint256).max);

        assertEq(sixDecimalVault.decimals(), 12);
        vm.prank(ALICE);
        uint256 shares = sixDecimalVault.deposit(100_000_000, ALICE);
        assertGt(shares, 0);

        vm.prank(ALICE);
        assertTrue(sixDecimalAsset.transfer(address(sixDecimalVault), 50_000_000));
        assertGt(sixDecimalVault.previewDeposit(1_000_000), 0);
    }

    function testStrategyAssetAndVaultMustMatch() public {
        MockERC20 otherAsset = new MockERC20("Other", "OTH", 18);
        MockClStrategy wrongAssetStrategy = new MockClStrategy(otherAsset, address(vault));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StrategyAssetMismatch.selector, address(asset), address(otherAsset)
            )
        );
        vault.setStrategy(wrongAssetStrategy);

        HelixVault otherVault =
            new HelixVault(asset, riskEngine, address(this), GUARDIAN, "Other Vault", "OHVX");
        MockClStrategy wrongVaultStrategy = new MockClStrategy(asset, address(otherVault));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StrategyVaultMismatch.selector, address(vault), address(otherVault)
            )
        );
        vault.setStrategy(wrongVaultStrategy);
    }
}
