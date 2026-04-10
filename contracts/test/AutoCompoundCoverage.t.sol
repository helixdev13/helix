// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AutoCompoundClStrategy } from "../src/strategies/AutoCompoundClStrategy.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { RewardDistributor } from "../src/periphery/RewardDistributor.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { IClAdapter } from "../src/interfaces/IClAdapter.sol";
import { Errors } from "../src/libraries/Errors.sol";
import { Types } from "../src/libraries/Types.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";

contract AutoCompoundCoverageTest is Test {
    address internal constant VAULT = address(0xCAFE);
    address internal constant STRATEGIST = address(0xB0B);
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant FEE_RECIPIENT = address(0xFEE);
    address internal constant CALLER = address(0xCA11);
    uint256 internal constant INITIAL_BALANCE = 1_000e18;
    uint256 internal constant DEPLOY_AMOUNT = 60e18;

    MockERC20 internal asset;
    OracleRouter internal oracleRouter;
    MockOracle internal oracle;
    CoverageClAdapter internal adapter;
    HLXToken internal hlx;
    RewardDistributor internal rewardDistributor;
    AutoCompoundClStrategy internal strategy;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        oracleRouter = new OracleRouter(address(this));
        oracle = new MockOracle(address(this), 300e18);
        oracleRouter.setOracle(address(asset), address(oracle), 1 days);

        adapter = new CoverageClAdapter(asset);
        hlx = new HLXToken(address(this));
        rewardDistributor = new RewardDistributor(address(this), address(hlx), address(this));

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
            address(rewardDistributor)
        );

        hlx.grantRole(MINTER_ROLE, address(strategy));
        strategy.setCompoundCooldown(0);
        strategy.setHlxMintRate(1e18);

        asset.mint(VAULT, INITIAL_BALANCE);
        vm.prank(VAULT);
        asset.approve(address(strategy), type(uint256).max);

        vm.warp(1);
    }

    function testCoverageHappyPath() public {
        _seedStrategy();
        _deployToAdapter(DEPLOY_AMOUNT);
        asset.mint(address(adapter), 10e18);

        vm.prank(CALLER);
        Types.CompoundReport memory report = strategy.compound();

        assertEq(report.profit, 10e18);
        assertEq(report.performanceFee, 3e18);
        assertEq(report.treasuryFee, 9e17);
        assertEq(report.hlxUserMint, 207e16);
        assertEq(report.bountyMint, 3e16);
        assertEq(report.reinvestAmount, 7e18);
        assertTrue(report.reinvested);
    }

    function testCoverageConstructorAndViewBranches() public {
        vm.expectRevert();
        new HLXToken(address(0));

        vm.expectRevert(Errors.ZeroAddress.selector);
        new RewardDistributor(address(0), address(hlx), address(this));

        adapter.setActive(false);

        assertEq(strategy.asset(), address(asset));
        assertEq(strategy.vault(), VAULT);
        assertEq(strategy.adapter(), address(adapter));
        assertEq(strategy.oracleRouter(), address(oracleRouter));
        assertEq(strategy.totalIdle(), 0);
        assertEq(strategy.totalDeployedAssets(), 0);
        assertEq(strategy.totalConservativeAssets(), 0);
        assertEq(strategy.totalAssets(), 0);

        Types.PositionState memory position = strategy.positionState();
        assertEq(position.liquidity, 0);
        assertFalse(position.active);

        Types.Valuation memory valuation = strategy.adapterValuation();
        assertEq(valuation.grossAssets, 0);
        assertEq(valuation.netAssets, 0);

        Types.CompoundConfig memory config = strategy.compoundConfig();
        assertEq(config.performanceFeeBps, 3000);
        assertEq(config.rewardRatioBps, 7000);
        assertEq(config.bountyBps, 100);
        assertEq(config.hlxMintRate, 1e18);
        assertEq(config.minimumProfitThreshold, 1e6);
        assertEq(config.compoundCooldown, 0);
        assertEq(config.feeRecipient, FEE_RECIPIENT);
        assertEq(config.hlxToken, address(hlx));
        assertEq(config.rewardDistributor, address(rewardDistributor));

        assertEq(rewardDistributor.totalSupply(), 0);
        assertEq(rewardDistributor.balanceOf(CALLER), 0);
        assertEq(rewardDistributor.rewardPerToken(), 0);
        assertEq(rewardDistributor.lastTimeRewardApplicable(), 0);
        assertEq(rewardDistributor.getRewardForDuration(), 0);
        assertEq(rewardDistributor.earned(CALLER), 0);
    }

    function testCoverageConstructorMismatchBranches() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new AutoCompoundClStrategy(
            IERC20(address(0)),
            VAULT,
            adapter,
            oracleRouter,
            address(this),
            STRATEGIST,
            GUARDIAN,
            FEE_RECIPIENT,
            hlx,
            address(rewardDistributor)
        );

        MockERC20 otherAsset = new MockERC20("Other Asset", "OA", 18);
        CoverageClAdapter badAdapter = new CoverageClAdapter(otherAsset);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StrategyAssetMismatch.selector, address(asset), address(otherAsset)
            )
        );
        new AutoCompoundClStrategy(
            asset,
            VAULT,
            badAdapter,
            oracleRouter,
            address(this),
            STRATEGIST,
            GUARDIAN,
            FEE_RECIPIENT,
            hlx,
            address(rewardDistributor)
        );
    }

    function testCoverageReinvestCatchBranch() public {
        _seedStrategy();
        _deployToAdapter(DEPLOY_AMOUNT);
        asset.mint(address(adapter), 10e18);
        adapter.setRevertOnQuote(true);

        vm.prank(CALLER);
        Types.CompoundReport memory report = strategy.compound();

        assertFalse(report.reinvested);
        assertEq(strategy.totalIdle(), 49.1e18);
        assertEq(strategy.totalDeployedAssets(), 60e18);
        assertEq(asset.balanceOf(FEE_RECIPIENT), 9e17);
    }

    function testCoverageCooldownAndReinvestFallbackBranches() public {
        _seedStrategy();
        asset.mint(address(adapter), 10e18);

        vm.prank(CALLER);
        Types.CompoundReport memory report = strategy.compound();
        assertFalse(report.reinvested);

        strategy.setCompoundCooldown(3600);
        asset.mint(address(adapter), 10e18);

        vm.expectRevert(abi.encodeWithSelector(Errors.CompoundCooldownActive.selector, 3600));
        strategy.compound();
    }

    function testCoverageZeroProfitAndRewardAmountBranches() public {
        _seedStrategy();
        _deployToAdapter(DEPLOY_AMOUNT);
        strategy.setMinimumProfitThreshold(0);

        vm.prank(CALLER);
        Types.CompoundReport memory report = strategy.compound();
        assertFalse(report.reinvested);
        assertEq(report.profit, 0);
        assertEq(report.reinvestAmount, 0);

        vm.expectRevert(Errors.ZeroAmount.selector);
        rewardDistributor.notifyRewardAmount(0);
    }

    function testCoverageRevertsOnOracleStaleAndLowProfit() public {
        _seedStrategy();
        _deployToAdapter(DEPLOY_AMOUNT);
        asset.mint(address(adapter), 1e5);

        vm.warp(1 days + 2);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.StalePrice.selector, address(asset), 1, 1 days + 2, 1 days)
        );
        strategy.compound();

        vm.warp(1);
        oracle.setPrice(300e18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientProfit.selector, 1e5, 1e6)
        );
        strategy.compound();
    }

    function testCoverageDeadlineAndQuoteBranches() public {
        _seedStrategy();
        _deployToAdapter(DEPLOY_AMOUNT);

        Types.RebalanceIntent memory expiredIntent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: DEPLOY_AMOUNT,
            assetsToWithdraw: 0,
            deadline: 0
        });
        Types.RebalanceQuote memory expiredQuote = strategy.previewRebalance(
            Types.RebalanceIntent({
                targetLowerTick: -120,
                targetUpperTick: 120,
                targetLiquidity: 1000,
                assetsToDeploy: DEPLOY_AMOUNT,
                assetsToWithdraw: 0,
                deadline: uint64(block.timestamp + 1 days)
            })
        );
        Types.ExecutionLimits memory expiredLimits = Types.ExecutionLimits({
            minAssetsOut: 0,
            maxLoss: 0,
            deadline: 0
        });

        vm.expectRevert();
        vm.prank(STRATEGIST);
        strategy.rebalance(expiredIntent, expiredQuote, expiredLimits);

        Types.RebalanceIntent memory intent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: DEPLOY_AMOUNT,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 2 days)
        });
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = Types.ExecutionLimits({
            minAssetsOut: 0,
            maxLoss: 0,
            deadline: uint64(block.timestamp + 2 days)
        });

        vm.warp(uint256(quote.validUntil) + 1);
        oracle.setPriceWithTimestamp(300e18, uint48(block.timestamp));
        uint256 currentTimestamp = block.timestamp;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.QuoteExpired.selector, currentTimestamp, uint256(quote.validUntil)
            )
        );
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, limits);

        Types.RebalanceQuote memory mismatchQuote = strategy.previewRebalance(intent);
        mismatchQuote.expectedAdapterAssetsAfter += 1;
        vm.expectRevert(Errors.QuoteFactsMismatch.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, mismatchQuote, limits);

        Types.RebalanceQuote memory durationMismatch = strategy.previewRebalance(intent);
        durationMismatch.validUntil += 1;
        vm.expectRevert(Errors.QuoteInvalid.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, durationMismatch, limits);
    }

    function testCoverageUnauthorizedAndValidationBranches() public {
        Types.RebalanceIntent memory badIntent = Types.RebalanceIntent({
            targetLowerTick: 10,
            targetUpperTick: 10,
            targetLiquidity: 1000,
            assetsToDeploy: DEPLOY_AMOUNT,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 1 days)
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidTicks.selector, 10, 10));
        strategy.previewRebalance(badIntent);

        Types.RebalanceIntent memory intent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: DEPLOY_AMOUNT,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 1 days)
        });
        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = Types.ExecutionLimits({
            minAssetsOut: 0,
            maxLoss: 0,
            deadline: intent.deadline
        });

        vm.expectRevert(Errors.Unauthorized.selector);
        vm.prank(CALLER);
        strategy.deposit(1);

        vm.expectRevert(Errors.Unauthorized.selector);
        vm.prank(CALLER);
        strategy.withdraw(1, CALLER);

        vm.expectRevert(Errors.Unauthorized.selector);
        vm.prank(CALLER);
        strategy.harvest();

        vm.expectRevert(Errors.Unauthorized.selector);
        vm.prank(CALLER);
        strategy.unwindAll();

        vm.expectRevert(Errors.OnlyOwnerOrStrategist.selector);
        vm.prank(CALLER);
        strategy.rebalance(intent, quote, limits);

        vm.expectRevert(Errors.GuardianOnlyOrOwner.selector);
        vm.prank(CALLER);
        strategy.setRebalancePaused(true);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBps.selector, 10_001));
        strategy.setPerformanceFeeBps(10_001);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBps.selector, 10_001));
        strategy.setRewardRatioBps(10_001);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBountyBps.selector, 10_001));
        strategy.setBountyBps(10_001);

        vm.expectRevert(Errors.InvalidHlxMintRate.selector);
        strategy.setHlxMintRate(0);

        vm.expectRevert(Errors.ZeroAddress.selector);
        strategy.setFeeRecipient(address(0));

        vm.expectRevert(Errors.ZeroAddress.selector);
        strategy.setRewardDistributor(address(0));

        vm.prank(GUARDIAN);
        strategy.setRebalancePaused(true);

        vm.expectRevert(Errors.OnlyOwnerCanDisableRebalancePause.selector);
        vm.prank(GUARDIAN);
        strategy.setRebalancePaused(false);
    }

    function testCoverageQuoteMismatchAndLiquidityFailureBranches() public {
        _seedStrategy();
        _deployToAdapter(DEPLOY_AMOUNT);

        Types.RebalanceIntent memory intent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: DEPLOY_AMOUNT,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 1 days)
        });
        Types.ExecutionLimits memory limits = Types.ExecutionLimits({
            minAssetsOut: 0,
            maxLoss: 0,
            deadline: intent.deadline
        });

        Types.RebalanceQuote memory intentQuote = strategy.previewRebalance(intent);
        bytes32 expectedIntentHash = intentQuote.intentHash;
        Types.RebalanceQuote memory intentMismatch = intentQuote;
        intentMismatch.intentHash = bytes32(uint256(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.QuoteIntentMismatch.selector, expectedIntentHash, bytes32(uint256(1))
            )
        );
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, intentMismatch, limits);

        Types.RebalanceQuote memory positionQuote = strategy.previewRebalance(intent);
        uint256 expectedPositionVersion = positionQuote.positionVersion;
        Types.RebalanceQuote memory positionMismatch = positionQuote;
        positionMismatch.positionVersion = 2;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.QuotePositionMismatch.selector, expectedPositionVersion, uint256(2)
            )
        );
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, positionMismatch, limits);

        Types.RebalanceQuote memory invalidQuote = strategy.previewRebalance(intent);
        invalidQuote.validUntil = invalidQuote.quotedAt - 1;
        vm.expectRevert(Errors.QuoteInvalid.selector);
        vm.prank(STRATEGIST);
        strategy.rebalance(intent, invalidQuote, limits);

        adapter.setWithdrawCap(0);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientLiquidAssets.selector, 0, 10e18)
        );
        vm.prank(VAULT);
        strategy.withdraw(50e18, VAULT);

        adapter.setWithdrawCap(type(uint256).max);
        adapter.setForcedWithdrawShortfall(1e18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientLiquidAssets.selector, 49e18, 50e18)
        );
        vm.prank(VAULT);
        strategy.withdraw(50e18, VAULT);
    }

    function testCoverageWithdrawalAndRebalanceHappyBranches() public {
        _seedStrategy();
        _deployToAdapter(DEPLOY_AMOUNT);

        vm.prank(VAULT);
        strategy.withdraw(10e18, VAULT);

        vm.prank(VAULT);
        strategy.harvest();

        vm.prank(VAULT);
        strategy.unwindAll();
    }

    function testCoverageSetterBranches() public {
        vm.prank(GUARDIAN);
        strategy.setRebalancePaused(true);

        vm.expectRevert(Errors.OnlyOwnerCanDisableRebalancePause.selector);
        vm.prank(GUARDIAN);
        strategy.setRebalancePaused(false);

        strategy.setRebalancePaused(false);
        strategy.setStrategist(address(0x1234));
        strategy.setGuardian(address(0x5678));
        strategy.setPerformanceFeeBps(2000);
        strategy.setRewardRatioBps(6500);
        strategy.setBountyBps(250);
        strategy.setHlxMintRate(2e18);
        strategy.setMinimumProfitThreshold(5e18);
        strategy.setCompoundCooldown(7200);
        strategy.setFeeRecipient(address(0x7777));
        strategy.setRewardDistributor(address(0x8888));

        assertEq(strategy.strategist(), address(0x1234));
        assertEq(strategy.guardian(), address(0x5678));
        assertEq(strategy.performanceFeeBps(), 2000);
        assertEq(strategy.rewardRatioBps(), 6500);
        assertEq(strategy.bountyBps(), 250);
        assertEq(strategy.hlxMintRate(), 2e18);
        assertEq(strategy.minimumProfitThreshold(), 5e18);
        assertEq(strategy.compoundCooldown(), 7200);
        assertEq(strategy.feeRecipient(), address(0x7777));
        assertEq(strategy.rewardDistributor(), address(0x8888));
    }

    function testCoverageZeroAddressAndZeroAmountBranches() public {
        vm.expectRevert(Errors.ZeroAmount.selector);
        vm.prank(VAULT);
        strategy.deposit(0);

        vm.expectRevert(Errors.ZeroAmount.selector);
        vm.prank(VAULT);
        strategy.withdraw(0, VAULT);

        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(VAULT);
        strategy.withdraw(1, address(0));

        vm.expectRevert(Errors.ZeroAddress.selector);
        strategy.setFeeRecipient(address(0));

        vm.expectRevert(Errors.ZeroAddress.selector);
        strategy.setRewardDistributor(address(0));

        vm.expectRevert(Errors.InvalidHlxMintRate.selector);
        strategy.setHlxMintRate(0);
    }

    function _seedStrategy() internal {
        vm.prank(VAULT);
        strategy.deposit(100e18);
    }

    function _deployToAdapter(uint256 amount) internal {
        Types.RebalanceIntent memory intent = Types.RebalanceIntent({
            targetLowerTick: -120,
            targetUpperTick: 120,
            targetLiquidity: 1000,
            assetsToDeploy: amount,
            assetsToWithdraw: 0,
            deadline: uint64(block.timestamp + 1 days)
        });

        Types.RebalanceQuote memory quote = strategy.previewRebalance(intent);
        Types.ExecutionLimits memory limits = Types.ExecutionLimits({
            minAssetsOut: 0,
            maxLoss: 0,
            deadline: intent.deadline
        });

        vm.prank(STRATEGIST);
        strategy.rebalance(intent, quote, limits);
    }
}

contract CoverageClAdapter is IClAdapter {
    MockERC20 internal immutable ASSET_TOKEN;
    address internal _strategy;
    bool public revertOnExecute;
    bool public revertOnQuote;
    bool public active = true;
    uint256 public withdrawCap = type(uint256).max;
    uint256 public forcedWithdrawShortfall;
    uint256 public principalAssets;

    constructor(
        MockERC20 asset_
    ) {
        ASSET_TOKEN = asset_;
    }

    function asset() external view returns (address) {
        return address(ASSET_TOKEN);
    }

    function strategy() external view returns (address) {
        return _strategy;
    }

    function bindStrategy(
        address strategy_
    ) external {
        require(_strategy == address(0), "bound");
        require(msg.sender == strategy_, "auth");
        _strategy = strategy_;
    }

    function positionState() external view returns (Types.PositionState memory) {
        return Types.PositionState({
            lowerTick: -120,
            upperTick: 120,
            liquidity: active ? 1000 : 0,
            principalAssets: principalAssets,
            version: 1,
            lastRebalance: uint64(block.timestamp),
            active: active
        });
    }

    function valuation() external view returns (Types.Valuation memory value) {
        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));

        value = Types.Valuation({
            grossAssets: grossAssets,
            deployedAssets: principalAssets,
            pendingFees: grossAssets > principalAssets ? grossAssets - principalAssets : 0,
            haircutBps: 0,
            haircutAmount: 0,
            netAssets: grossAssets,
            positionVersion: 1,
            timestamp: uint64(block.timestamp)
        });
    }

    function quoteRebalance(
        Types.RebalanceIntent calldata intent
    ) external view returns (Types.RebalanceQuote memory quote) {
        if (revertOnQuote) {
            revert("REINVEST_QUOTE_FAIL");
        }

        uint256 assetsBefore = ASSET_TOKEN.balanceOf(address(this));
        uint256 assetsAfter = assetsBefore + intent.assetsToDeploy - intent.assetsToWithdraw;

        quote = Types.RebalanceQuote({
            intentHash: keccak256("COVERAGE_INTENT"),
            positionVersion: 1,
            quotedAt: uint64(block.timestamp),
            validUntil: uint64(block.timestamp + 1 days),
            adapterAssetsBefore: assetsBefore,
            assetsToDeploy: intent.assetsToDeploy,
            assetsToWithdraw: intent.assetsToWithdraw,
            estimatedLoss: 0,
            expectedAssetsOut: intent.assetsToWithdraw,
            expectedAdapterAssetsAfter: assetsAfter
        });
    }

    function executeRebalance(
        Types.RebalanceIntent calldata intent,
        Types.RebalanceQuote calldata,
        Types.ExecutionLimits calldata
    ) external returns (Types.ExecutionReport memory report) {
        if (revertOnExecute) {
            revert("REINVEST_FAIL");
        }

        if (intent.assetsToDeploy != 0) {
            ASSET_TOKEN.transferFrom(msg.sender, address(this), intent.assetsToDeploy);
            principalAssets += intent.assetsToDeploy;
        }

        if (intent.assetsToWithdraw != 0) {
            ASSET_TOKEN.transfer(msg.sender, intent.assetsToWithdraw);
            principalAssets -= intent.assetsToWithdraw;
        }

        active = principalAssets != 0;

        report = Types.ExecutionReport({
            assetsIn: intent.assetsToDeploy,
            assetsOut: intent.assetsToWithdraw,
            lossInAssets: 0,
            harvestedFees: 0,
            adapterAssetsAfter: ASSET_TOKEN.balanceOf(address(this)),
            positionVersion: 1
        });
    }

    function withdrawTo(
        address receiver,
        uint256 assets
    ) external returns (uint256 assetsWithdrawn) {
        uint256 balance = ASSET_TOKEN.balanceOf(address(this));
        uint256 available = balance < withdrawCap ? balance : withdrawCap;
        uint256 actualAssets = assets;
        if (forcedWithdrawShortfall != 0) {
            if (forcedWithdrawShortfall >= actualAssets) {
                actualAssets = 1;
            } else {
                actualAssets -= forcedWithdrawShortfall;
            }
        }
        if (available < actualAssets) {
            revert Errors.InsufficientLiquidAssets(available, actualAssets);
        }

        ASSET_TOKEN.transfer(receiver, actualAssets);
        principalAssets = balance - actualAssets;
        active = principalAssets != 0;
        return actualAssets;
    }

    function harvestTo(
        address receiver
    ) external returns (uint256 assetsHarvested) {
        uint256 balance = ASSET_TOKEN.balanceOf(address(this));
        uint256 pendingFees = balance > principalAssets ? balance - principalAssets : 0;
        if (pendingFees != 0) {
            ASSET_TOKEN.transfer(receiver, pendingFees);
        }

        principalAssets = ASSET_TOKEN.balanceOf(address(this));
        active = principalAssets != 0;
        return pendingFees;
    }

    function unwindAllTo(
        address receiver
    ) external returns (uint256 assetsReturned) {
        uint256 balance = ASSET_TOKEN.balanceOf(address(this));
        if (balance != 0) {
            ASSET_TOKEN.transfer(receiver, balance);
        }

        principalAssets = 0;
        active = false;
        return balance;
    }

    function setRevertOnExecute(
        bool enabled
    ) external {
        revertOnExecute = enabled;
    }

    function setRevertOnQuote(
        bool enabled
    ) external {
        revertOnQuote = enabled;
    }

    function setActive(
        bool enabled
    ) external {
        active = enabled;
    }

    function setWithdrawCap(
        uint256 cap
    ) external {
        withdrawCap = cap;
    }

    function setForcedWithdrawShortfall(
        uint256 shortfall
    ) external {
        forcedWithdrawShortfall = shortfall;
    }
}
