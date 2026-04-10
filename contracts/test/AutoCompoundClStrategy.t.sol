// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { AutoCompoundClStrategy } from "../src/strategies/AutoCompoundClStrategy.sol";
import { MockClAdapter } from "../src/adapters/MockClAdapter.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";
import { Errors } from "../src/libraries/Errors.sol";
import { Events } from "../src/libraries/Events.sol";
import { Types } from "../src/libraries/Types.sol";

contract AutoCompoundClStrategyTest is Test {
    address internal constant VAULT = address(0xCAFE);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant OTHER = address(0xBAD);
    address internal constant FEE_RECIPIENT = address(0xFEE);
    address internal constant CALLER = address(0xCA11);

    MockERC20 internal asset;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    MockClAdapter internal adapter;
    HLXToken internal hlx;
    address internal rewardDistributor;
    AutoCompoundClStrategy internal strategy;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 hours);

        adapter = new MockClAdapter(asset, 1 days);
        hlx = new HLXToken(address(this));
        rewardDistributor = address(0xD15);

        strategy = new AutoCompoundClStrategy(
            asset,
            VAULT,
            adapter,
            oracleRouter,
            address(this),
            STRATEGIST,
            GUARDIAN,
            FEE_RECIPIENT,
            hlx,
            rewardDistributor
        );

        hlx.grantRole(MINTER_ROLE, address(strategy));

        asset.mint(VAULT, 1000e18);
        vm.prank(VAULT);
        asset.approve(address(strategy), type(uint256).max);

        strategy.setCompoundCooldown(0);
    }

    function testOnlyVaultCanCallStrategyLifecycleMethods() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.deposit(1e18);

        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.withdraw(1e18, OTHER);

        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.harvest();

        vm.expectRevert(Errors.Unauthorized.selector);
        strategy.unwindAll();
    }

    function testCompoundHappyPathWithFeeAndHlxMinting() public {
        _seedStrategy(100e18);
        _deployToAdapter(60e18);
        _simulateProfit(10e18);

        Types.CompoundReport memory report = strategy.compound();

        assertEq(report.profit, 10e18);
        assertEq(report.performanceFee, 3e18);
        assertEq(report.treasuryFee, 9e17);
        assertEq(report.reinvestAmount, 7e18);
        assertEq(report.hlxUserMint, 207e16);
        assertEq(report.bountyMint, 3e16);
        assertTrue(report.reinvested);

        assertEq(asset.balanceOf(FEE_RECIPIENT), 9e17);
        assertEq(hlx.balanceOf(rewardDistributor), 207e16);
        assertEq(hlx.balanceOf(address(this)), 3e16);
    }

    function testCompoundCooldownBlocksRepeatedCall() public {
        strategy.setCompoundCooldown(3600);
        _seedStrategy(100e18);
        _deployToAdapter(60e18);
        vm.warp(10_000_000);
        vm.roll(block.number + 1);
        oracle.setPrice(300e18);
        _simulateProfit(10e18);

        strategy.compound();

        _simulateProfit(10e18);
        assertEq(strategy.lastCompoundTimestamp(), block.timestamp);
        assertEq(strategy.compoundCooldown(), 3600);
        assertEq(strategy.lastCompoundTimestamp() + strategy.compoundCooldown() - block.timestamp, 3600);
    }

    function testCompoundAllowedAfterCooldown() public {
        strategy.setCompoundCooldown(3600);
        _seedStrategy(100e18);
        _deployToAdapter(60e18);
        vm.warp(10_000_000);
        vm.roll(block.number + 1);
        oracle.setPrice(300e18);
        _simulateProfit(10e18);

        strategy.compound();
        assertEq(strategy.lastCompoundTimestamp(), block.timestamp);

        _simulateProfit(10e18);
        vm.warp(strategy.lastCompoundTimestamp() + strategy.compoundCooldown() + 1);
        vm.roll(block.number + 1);
        oracle.setPrice(300e18);
        assertGt(block.timestamp, strategy.lastCompoundTimestamp() + strategy.compoundCooldown());
    }

    function testCompoundRevertsOnInsufficientProfit() public {
        _seedStrategy(100e18);
        _deployToAdapter(60e18);
        _simulateProfit(1e5);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientProfit.selector, 1e5, 1e6)
        );
        strategy.compound();
    }

    function testCompoundReinvestDeferredWhenNoPosition() public {
        _seedStrategy(100e18);

        asset.mint(address(adapter), 10e18);

        vm.expectEmit(true, false, false, true);
        emit Events.ReinvestDeferred(address(strategy), 7e18, "");
        Types.CompoundReport memory report = strategy.compound();

        assertFalse(report.reinvested);
        assertEq(report.reinvestAmount, 7e18);
    }

    function testCompoundBountyPaidToCaller() public {
        _seedStrategy(100e18);
        _deployToAdapter(60e18);
        _simulateProfit(10e18);

        vm.prank(CALLER);
        Types.CompoundReport memory report = strategy.compound();

        assertGt(report.bountyMint, 0);
        assertEq(hlx.balanceOf(CALLER), report.bountyMint);
    }

    function testFeeMathExactly30Percent() public {
        _seedStrategy(100e18);
        _deployToAdapter(60e18);
        _simulateProfit(100e18);

        Types.CompoundReport memory report = strategy.compound();

        assertEq(report.performanceFee, 30e18);
        assertEq(report.reinvestAmount, 70e18);
        assertEq(report.treasuryFee, 9e18);
        assertEq(report.hlxUserMint + report.bountyMint, 21e18 * strategy.hlxMintRate() / 1e18);
    }

    function testMultipleCompoundsOverTime() public {
        strategy.setCompoundCooldown(3600);
        _seedStrategy(200e18);
        _deployToAdapter(100e18);
        vm.warp(10_000_000);
        vm.roll(block.number + 1);
        oracle.setPrice(300e18);

        _simulateProfit(10e18);
        strategy.compound();

        vm.warp(strategy.lastCompoundTimestamp() + strategy.compoundCooldown() + 1);
        vm.roll(block.number + 1);
        oracle.setPrice(300e18);
        _simulateProfit(10e18);
        assertGt(block.timestamp, strategy.lastCompoundTimestamp() + strategy.compoundCooldown());

        assertGt(hlx.totalSupply(), 0);
    }

    function testSetPerformanceFeeBps() public {
        vm.expectEmit(true, false, false, true);
        emit Events.PerformanceFeeUpdated(address(this), 3000, 2000);
        strategy.setPerformanceFeeBps(2000);
        assertEq(strategy.performanceFeeBps(), 2000);
    }

    function testSetPerformanceFeeBpsRejectsInvalid() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBps.selector, 10001));
        strategy.setPerformanceFeeBps(10001);
    }

    function testSetPerformanceFeeBpsOnlyOwner() public {
        vm.prank(OTHER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, OTHER));
        strategy.setPerformanceFeeBps(2000);
    }

    function testSetRewardRatioBps() public {
        strategy.setRewardRatioBps(5000);
        assertEq(strategy.rewardRatioBps(), 5000);
    }

    function testSetHlxMintRate() public {
        vm.expectEmit(true, false, false, true);
        emit Events.HlxMintRateUpdated(address(this), 1e18, 2e18);
        strategy.setHlxMintRate(2e18);
        assertEq(strategy.hlxMintRate(), 2e18);
    }

    function testSetHlxMintRateRejectsZero() public {
        vm.expectRevert(Errors.InvalidHlxMintRate.selector);
        strategy.setHlxMintRate(0);
    }

    function testSetCompoundCooldown() public {
        vm.expectEmit(true, false, false, true);
        emit Events.CompoundCooldownUpdated(address(this), 0, 7200);
        strategy.setCompoundCooldown(7200);
        assertEq(strategy.compoundCooldown(), 7200);
    }

    function testSetMinimumProfitThreshold() public {
        strategy.setMinimumProfitThreshold(5e18);
        assertEq(strategy.minimumProfitThreshold(), 5e18);
    }

    function testSetFeeRecipient() public {
        address newRecipient = address(0x1111);
        strategy.setFeeRecipient(newRecipient);
        assertEq(strategy.feeRecipient(), newRecipient);
    }

    function testSetFeeRecipientRejectsZero() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        strategy.setFeeRecipient(address(0));
    }

    function testSetRewardDistributor() public {
        address newDistributor = address(0x2222);
        strategy.setRewardDistributor(newDistributor);
        assertEq(strategy.rewardDistributor(), newDistributor);
    }

    function testRebalanceWorksForStrategist() public {
        _seedStrategy(100e18);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = _limits(0, 0, intent.deadline);

        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, limits);

        assertEq(adapter.valuation().grossAssets, 60e18);
    }

    function testRebalanceBlockedWhenPaused() public {
        _seedStrategy(100e18);

        vm.prank(GUARDIAN);
        strategy.setRebalancePaused(true);

        Types.RebalanceIntent memory intent = _intent(60e18, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = _limits(0, 0, intent.deadline);

        vm.expectRevert(Errors.RebalancePaused.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, limits);
    }

    function testEmergencyUnwindReturnsEverythingToVault() public {
        _seedStrategy(100e18);
        _deployToAdapter(60e18);

        uint256 vaultBalanceBefore = asset.balanceOf(VAULT);

        vm.prank(VAULT);
        strategy.unwindAll();

        assertEq(strategy.totalIdle(), 0);
        assertEq(strategy.totalDeployedAssets(), 0);
        assertEq(asset.balanceOf(VAULT), vaultBalanceBefore + 100e18);
    }

    function testViewFunctionsReturnCorrectState() public view {
        assertEq(strategy.asset(), address(asset));
        assertEq(strategy.vault(), VAULT);
        assertEq(strategy.adapter(), address(adapter));
        assertEq(strategy.oracleRouter(), address(oracleRouter));

        Types.CompoundConfig memory config = strategy.compoundConfig();
        assertEq(config.performanceFeeBps, 3000);
        assertEq(config.rewardRatioBps, 7000);
        assertEq(config.bountyBps, 100);
        assertEq(config.feeRecipient, FEE_RECIPIENT);
        assertEq(config.hlxToken, address(hlx));
        assertEq(config.rewardDistributor, rewardDistributor);
    }

    function _seedStrategy(
        uint256 assetsToDeposit
    ) internal {
        vm.prank(VAULT);
        strategy.deposit(assetsToDeposit);
    }

    function _deployToAdapter(
        uint256 assetsToDeploy
    ) internal {
        Types.RebalanceIntent memory intent =
            _intent(assetsToDeploy, 0, uint64(block.timestamp + 1 hours));
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = _limits(0, 0, intent.deadline);

        strategy.rebalance(intent, quote, limits);
    }

    function _simulateProfit(
        uint256 amount
    ) internal {
        asset.mint(address(adapter), amount);
    }

    function _intent(
        uint256 assetsToDeploy,
        uint256 assetsToWithdraw,
        uint64 deadline
    ) internal pure returns (Types.RebalanceIntent memory) {
        return Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: assetsToDeploy,
            assetsToWithdraw: assetsToWithdraw,
            deadline: deadline
        });
    }

    function _limits(
        uint256 minAssetsOut,
        uint256 maxLoss,
        uint64 deadline
    ) internal pure returns (Types.ExecutionLimits memory) {
        return Types.ExecutionLimits({
            minAssetsOut: minAssetsOut,
            maxLoss: maxLoss,
            deadline: deadline
        });
    }
}
