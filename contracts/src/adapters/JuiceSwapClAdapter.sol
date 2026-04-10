// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IClAdapter } from "../interfaces/IClAdapter.sol";
import { IOracleRouter } from "../interfaces/IOracleRouter.sol";
import { IJuiceSwapFactory } from "../interfaces/venues/juiceswap/IJuiceSwapFactory.sol";
import { IJuiceSwapPool } from "../interfaces/venues/juiceswap/IJuiceSwapPool.sol";
import {
    IJuiceSwapPositionManager
} from "../interfaces/venues/juiceswap/IJuiceSwapPositionManager.sol";
import { IJuiceSwapSwapRouter } from "../interfaces/venues/juiceswap/IJuiceSwapSwapRouter.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { Types } from "../libraries/Types.sol";
import { JuiceSwapFeeMath } from "../libraries/venues/juiceswap/JuiceSwapFeeMath.sol";
import { JuiceSwapLiquidityMath } from "../libraries/venues/juiceswap/JuiceSwapLiquidityMath.sol";
import { JuiceSwapTickMath } from "../libraries/venues/juiceswap/JuiceSwapTickMath.sol";

contract JuiceSwapClAdapter is IClAdapter, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint16 public constant BPS_DENOMINATOR = 10_000;
    uint24 public constant FEE_DENOMINATOR = 1_000_000;
    uint128 internal constant MAX_COLLECT_AMOUNT = type(uint128).max;
    uint32 internal constant EXIT_TWAP_WINDOW = 30 minutes;

    IERC20 public immutable ASSET_TOKEN;
    IERC20 public immutable PAIR_TOKEN;
    IJuiceSwapFactory public immutable FACTORY;
    IJuiceSwapPool public immutable POOL;
    IJuiceSwapPositionManager public immutable POSITION_MANAGER;
    IJuiceSwapSwapRouter public immutable SWAP_ROUTER;
    IOracleRouter public immutable ORACLE_ROUTER;
    uint24 public immutable POOL_FEE;
    uint16 public immutable VALUATION_HAIRCUT_BPS;
    uint16 public immutable MAX_PRICE_DEVIATION_BPS;
    uint64 public immutable QUOTE_VALIDITY;
    bool public immutable ASSET_IS_TOKEN0;
    uint256 public immutable ASSET_UNIT;
    uint256 public immutable PAIR_UNIT;

    address public strategy;
    uint256 public positionTokenId;

    Types.PositionState private _position;

    struct PositionSnapshot {
        bool exists;
        address token0;
        address token1;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    constructor(
        IERC20 asset_,
        IERC20 pairToken_,
        IJuiceSwapFactory factory_,
        IJuiceSwapPositionManager positionManager_,
        IJuiceSwapSwapRouter swapRouter_,
        IOracleRouter oracleRouter_,
        uint24 poolFee_,
        uint64 quoteValidity_,
        uint16 valuationHaircutBps_,
        uint16 maxPriceDeviationBps_
    ) {
        if (
            address(asset_) == address(0) || address(pairToken_) == address(0)
                || address(factory_) == address(0) || address(positionManager_) == address(0)
                || address(swapRouter_) == address(0) || address(oracleRouter_) == address(0)
        ) {
            revert Errors.ZeroAddress();
        }
        if (address(asset_) == address(pairToken_)) {
            revert Errors.StrategyAssetMismatch(address(asset_), address(pairToken_));
        }
        if (quoteValidity_ == 0) {
            revert Errors.InvalidQuoteWindow();
        }
        if (valuationHaircutBps_ > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(valuationHaircutBps_);
        }
        if (maxPriceDeviationBps_ > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(maxPriceDeviationBps_);
        }

        address poolAddress = factory_.getPool(address(asset_), address(pairToken_), poolFee_);
        if (poolAddress == address(0)) {
            revert Errors.PoolNotFound(address(asset_), address(pairToken_), poolFee_);
        }

        IJuiceSwapPool pool = IJuiceSwapPool(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        bool assetIsToken0 = token0 == address(asset_) && token1 == address(pairToken_);
        bool assetIsToken1 = token1 == address(asset_) && token0 == address(pairToken_);
        if (!assetIsToken0 && !assetIsToken1) {
            revert Errors.InvalidPoolTokens(address(asset_), address(pairToken_), token0, token1);
        }

        ASSET_TOKEN = asset_;
        PAIR_TOKEN = pairToken_;
        FACTORY = factory_;
        POOL = pool;
        POSITION_MANAGER = positionManager_;
        SWAP_ROUTER = swapRouter_;
        ORACLE_ROUTER = oracleRouter_;
        POOL_FEE = poolFee_;
        QUOTE_VALIDITY = quoteValidity_;
        VALUATION_HAIRCUT_BPS = valuationHaircutBps_;
        MAX_PRICE_DEVIATION_BPS = maxPriceDeviationBps_;
        ASSET_IS_TOKEN0 = assetIsToken0;
        ASSET_UNIT = 10 ** uint256(IERC20Metadata(address(asset_)).decimals());
        PAIR_UNIT = 10 ** uint256(IERC20Metadata(address(pairToken_)).decimals());
    }

    modifier onlyStrategy() {
        _onlyStrategy();
        _;
    }

    function asset() external view returns (address) {
        return address(ASSET_TOKEN);
    }

    function bindStrategy(
        address strategy_
    ) external {
        if (strategy != address(0)) {
            revert Errors.StrategyAlreadyBound(strategy);
        }
        if (strategy_ == address(0) || msg.sender != strategy_) {
            revert Errors.Unauthorized();
        }

        strategy = strategy_;
        emit Events.AdapterStrategyBound(address(this), strategy_);
    }

    function positionState() external view returns (Types.PositionState memory) {
        return _position;
    }

    function valuation() public view returns (Types.Valuation memory value) {
        PositionSnapshot memory snapshot = _readPositionSnapshot();
        (uint256 baseIdle, uint256 quoteIdle) = _idleBalances();
        uint256 grossAssets = baseIdle;
        uint256 pendingFees;

        if (snapshot.exists || quoteIdle != 0) {
            (uint160 sqrtPriceX96, int24 currentTick) = _validatedPoolState();
            (uint256 positionBase, uint256 positionQuote) =
                _liquidityAmounts(snapshot, sqrtPriceX96);
            (uint256 feeBase, uint256 feeQuote) = _pendingFeeBalances(snapshot, currentTick);

            grossAssets += positionBase + feeBase;
            grossAssets += _quoteToBaseAfterFee(quoteIdle + positionQuote + feeQuote, sqrtPriceX96);
            pendingFees = feeBase + _quoteToBaseAfterFee(feeQuote, sqrtPriceX96);
        }

        uint256 deployedAssets = grossAssets - pendingFees;
        uint256 haircutAmount = grossAssets * VALUATION_HAIRCUT_BPS / BPS_DENOMINATOR;

        value = Types.Valuation({
            grossAssets: grossAssets,
            deployedAssets: deployedAssets,
            pendingFees: pendingFees,
            haircutBps: VALUATION_HAIRCUT_BPS,
            haircutAmount: haircutAmount,
            netAssets: grossAssets - haircutAmount,
            positionVersion: _position.version,
            timestamp: uint64(block.timestamp)
        });
    }

    function quoteRebalance(
        Types.RebalanceIntent calldata intent
    ) public view returns (Types.RebalanceQuote memory quote) {
        _validateIntent(intent);

        Types.Valuation memory valueBefore = valuation();
        uint256 expectedAdapterAssetsAfter =
            _quotePostRebalanceAssets(intent, valueBefore.grossAssets + intent.assetsToDeploy);
        uint256 estimatedLoss = valueBefore.grossAssets + intent.assetsToDeploy
            - intent.assetsToWithdraw - expectedAdapterAssetsAfter;

        quote = Types.RebalanceQuote({
            intentHash: _hashIntent(intent),
            positionVersion: _position.version,
            quotedAt: uint64(block.timestamp),
            validUntil: uint64(block.timestamp) + QUOTE_VALIDITY,
            adapterAssetsBefore: valueBefore.grossAssets,
            assetsToDeploy: intent.assetsToDeploy,
            assetsToWithdraw: intent.assetsToWithdraw,
            estimatedLoss: estimatedLoss,
            expectedAssetsOut: intent.assetsToWithdraw,
            expectedAdapterAssetsAfter: expectedAdapterAssetsAfter
        });
    }

    function executeRebalance(
        Types.RebalanceIntent calldata intent,
        Types.RebalanceQuote calldata quote,
        Types.ExecutionLimits calldata limits
    ) external onlyStrategy nonReentrant returns (Types.ExecutionReport memory report) {
        _validateIntent(intent);
        _validateQuote(intent, quote, limits);

        if (intent.assetsToDeploy != 0) {
            ASSET_TOKEN.safeTransferFrom(msg.sender, address(this), intent.assetsToDeploy);
        }

        _collapsePositionToBase(true);

        uint256 assetsOut = intent.assetsToWithdraw;
        uint256 baseAvailable = ASSET_TOKEN.balanceOf(address(this));
        if (baseAvailable < assetsOut) {
            revert Errors.InsufficientLiquidAssets(baseAvailable, assetsOut);
        }
        if (assetsOut < limits.minAssetsOut) {
            revert Errors.MinAssetsOutNotMet(assetsOut, limits.minAssetsOut);
        }
        if (assetsOut != 0) {
            ASSET_TOKEN.safeTransfer(msg.sender, assetsOut);
        }

        if (intent.targetLiquidity != 0) {
            _mintExactLiquidity(
                intent.targetLowerTick, intent.targetUpperTick, intent.targetLiquidity, true
            );
        }

        Types.Valuation memory valueAfter = valuation();
        uint256 lossInAssets =
            quote.adapterAssetsBefore + intent.assetsToDeploy - assetsOut - valueAfter.grossAssets;
        if (lossInAssets > limits.maxLoss) {
            revert Errors.LossExceeded(lossInAssets, limits.maxLoss);
        }

        _refreshPosition(true);
        uint64 positionVersion = _position.version;

        report = Types.ExecutionReport({
            assetsIn: intent.assetsToDeploy,
            assetsOut: assetsOut,
            lossInAssets: lossInAssets,
            harvestedFees: 0,
            adapterAssetsAfter: valueAfter.grossAssets,
            positionVersion: positionVersion
        });
    }

    function withdrawTo(
        address receiver,
        uint256 assets
    ) external onlyStrategy nonReentrant returns (uint256 assetsWithdrawn) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }

        PositionSnapshot memory previous = _readPositionSnapshot();
        bool useOracleExitChecks = _oracleExitChecksAvailable();
        _collapsePositionToBase(useOracleExitChecks);

        uint256 baseAvailable = ASSET_TOKEN.balanceOf(address(this));
        if (baseAvailable < assets) {
            revert Errors.InsufficientLiquidAssets(baseAvailable, assets);
        }

        ASSET_TOKEN.safeTransfer(receiver, assets);
        assetsWithdrawn = assets;

        uint256 remainingBase = ASSET_TOKEN.balanceOf(address(this));
        if (useOracleExitChecks && previous.exists && previous.liquidity != 0 && remainingBase != 0)
        {
            uint256 previousCost =
                _baseCostForLiquidity(previous.lowerTick, previous.upperTick, previous.liquidity);
            if (previousCost != 0) {
                uint128 targetLiquidity =
                    uint128(Math.mulDiv(previous.liquidity, remainingBase, previousCost));
                uint128 affordableLiquidity = _maxAffordableLiquidity(
                    previous.lowerTick, previous.upperTick, targetLiquidity, remainingBase
                );
                if (affordableLiquidity != 0) {
                    (uint256 remintBaseAmount, uint256 remintQuoteAmount) = _requiredBaseAndQuote(
                        previous.lowerTick, previous.upperTick, affordableLiquidity
                    );
                    if (
                        _previewLiquidityForDesiredAmounts(
                                previous.lowerTick,
                                previous.upperTick,
                                remintBaseAmount,
                                remintQuoteAmount
                            ) != 0
                    ) {
                        _mintExactLiquidity(
                            previous.lowerTick, previous.upperTick, affordableLiquidity, false
                        );
                    }
                }
            }
        }

        _refreshPosition(false);
        emit Events.AdapterWithdrawal(address(this), receiver, assetsWithdrawn);
    }

    function harvestTo(
        address receiver
    ) external onlyStrategy nonReentrant returns (uint256 assetsHarvested) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        uint256 baseBefore = ASSET_TOKEN.balanceOf(address(this));
        _collectPositionFees();
        _swapAllQuoteToBase(true);

        assetsHarvested = ASSET_TOKEN.balanceOf(address(this)) - baseBefore;
        if (assetsHarvested != 0) {
            ASSET_TOKEN.safeTransfer(receiver, assetsHarvested);
        }

        _refreshPosition(false);
        emit Events.AdapterHarvested(address(this), assetsHarvested);
    }

    function unwindAllTo(
        address receiver
    ) external onlyStrategy nonReentrant returns (uint256 assetsReturned) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        _collapsePositionToBase(_oracleExitChecksAvailable());
        assetsReturned = ASSET_TOKEN.balanceOf(address(this));
        if (assetsReturned != 0) {
            ASSET_TOKEN.safeTransfer(receiver, assetsReturned);
        }

        _refreshPosition(true);
        emit Events.AdapterUnwound(address(this), assetsReturned);
    }

    function _onlyStrategy() internal view {
        if (msg.sender != strategy) {
            revert Errors.Unauthorized();
        }
    }

    function _validateIntent(
        Types.RebalanceIntent calldata intent
    ) internal view {
        if (intent.targetLowerTick >= intent.targetUpperTick) {
            revert Errors.InvalidTicks(intent.targetLowerTick, intent.targetUpperTick);
        }

        int24 spacing = POOL.tickSpacing();
        if (intent.targetLowerTick % spacing != 0 || intent.targetUpperTick % spacing != 0) {
            revert Errors.InvalidTickSpacing(
                intent.targetLowerTick, intent.targetUpperTick, spacing
            );
        }
    }

    function _validateQuote(
        Types.RebalanceIntent calldata intent,
        Types.RebalanceQuote calldata quote,
        Types.ExecutionLimits calldata limits
    ) internal view {
        if (block.timestamp > intent.deadline) {
            revert Errors.DeadlineExpired(block.timestamp, intent.deadline);
        }
        if (block.timestamp > limits.deadline) {
            revert Errors.DeadlineExpired(block.timestamp, limits.deadline);
        }
        if (block.timestamp > quote.validUntil) {
            revert Errors.QuoteExpired(block.timestamp, quote.validUntil);
        }

        bytes32 expectedIntentHash = _hashIntent(intent);
        if (quote.intentHash != expectedIntentHash) {
            revert Errors.QuoteIntentMismatch(expectedIntentHash, quote.intentHash);
        }
        if (quote.positionVersion != _position.version) {
            revert Errors.QuotePositionMismatch(_position.version, quote.positionVersion);
        }
    }

    function _quotePostRebalanceAssets(
        Types.RebalanceIntent calldata intent,
        uint256 totalBaseAssets
    ) internal view returns (uint256 expectedAdapterAssetsAfter) {
        if (totalBaseAssets < intent.assetsToWithdraw) {
            revert Errors.InsufficientLiquidAssets(totalBaseAssets, intent.assetsToWithdraw);
        }

        uint256 remainingBase = totalBaseAssets - intent.assetsToWithdraw;
        if (intent.targetLiquidity == 0) {
            return remainingBase;
        }

        (uint256 directBaseAmount, uint256 quoteAmount) = _requiredBaseAndQuote(
            intent.targetLowerTick, intent.targetUpperTick, intent.targetLiquidity
        );
        (uint160 sqrtPriceX96,) = _validatedPoolState();
        uint256 quoteAcquisitionCost = _quoteAmountToBaseInForExactOut(quoteAmount, sqrtPriceX96);
        uint256 requiredBaseBudget = directBaseAmount + quoteAcquisitionCost;
        if (remainingBase < requiredBaseBudget) {
            revert Errors.InsufficientLiquidAssets(remainingBase, requiredBaseBudget);
        }

        uint256 idleBaseAfterMint = remainingBase - requiredBaseBudget;
        expectedAdapterAssetsAfter =
            idleBaseAfterMint + directBaseAmount + _quoteToBaseAfterFee(quoteAmount, sqrtPriceX96);
    }

    function _mintExactLiquidity(
        int24 lowerTick,
        int24 upperTick,
        uint128 targetLiquidity,
        bool strict
    ) internal {
        if (targetLiquidity == 0) {
            return;
        }

        (uint256 directBaseAmount, uint256 quoteAmount) =
            _requiredBaseAndQuote(lowerTick, upperTick, targetLiquidity);

        if (quoteAmount != 0) {
            uint256 maxBaseSpend = ASSET_TOKEN.balanceOf(address(this)) - directBaseAmount;
            _swapBaseForExactQuote(quoteAmount, maxBaseSpend);
        }

        (uint256 amount0Desired, uint256 amount1Desired) =
            ASSET_IS_TOKEN0 ? (directBaseAmount, quoteAmount) : (quoteAmount, directBaseAmount);

        ASSET_TOKEN.forceApprove(address(POSITION_MANAGER), 0);
        PAIR_TOKEN.forceApprove(address(POSITION_MANAGER), 0);
        if (directBaseAmount != 0) {
            ASSET_TOKEN.forceApprove(address(POSITION_MANAGER), directBaseAmount);
        }
        if (quoteAmount != 0) {
            PAIR_TOKEN.forceApprove(address(POSITION_MANAGER), quoteAmount);
        }

        (uint256 tokenId, uint128 mintedLiquidity,,) = POSITION_MANAGER.mint(
            IJuiceSwapPositionManager.MintParams({
                token0: ASSET_IS_TOKEN0 ? address(ASSET_TOKEN) : address(PAIR_TOKEN),
                token1: ASSET_IS_TOKEN0 ? address(PAIR_TOKEN) : address(ASSET_TOKEN),
                fee: POOL_FEE,
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        ASSET_TOKEN.forceApprove(address(POSITION_MANAGER), 0);
        PAIR_TOKEN.forceApprove(address(POSITION_MANAGER), 0);

        if (
            strict
                && mintedLiquidity + _allowedLiquidityShortfall(targetLiquidity) < targetLiquidity
        ) {
            revert Errors.UnexpectedLiquidity(mintedLiquidity, targetLiquidity);
        }

        positionTokenId = tokenId;
    }

    function _collapsePositionToBase(
        bool useOracleExitChecks
    ) internal {
        PositionSnapshot memory snapshot = _readPositionSnapshot();
        if (snapshot.exists) {
            if (snapshot.liquidity != 0) {
                POSITION_MANAGER.decreaseLiquidity(
                    IJuiceSwapPositionManager.DecreaseLiquidityParams({
                        tokenId: positionTokenId,
                        liquidity: snapshot.liquidity,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp
                    })
                );
            }

            POSITION_MANAGER.collect(
                IJuiceSwapPositionManager.CollectParams({
                    tokenId: positionTokenId,
                    recipient: address(this),
                    amount0Max: MAX_COLLECT_AMOUNT,
                    amount1Max: MAX_COLLECT_AMOUNT
                })
            );

            POSITION_MANAGER.burn(positionTokenId);
            positionTokenId = 0;
        }

        _swapAllQuoteToBase(useOracleExitChecks);
    }

    function _collectPositionFees() internal {
        if (positionTokenId == 0) {
            return;
        }

        POSITION_MANAGER.collect(
            IJuiceSwapPositionManager.CollectParams({
                tokenId: positionTokenId,
                recipient: address(this),
                amount0Max: MAX_COLLECT_AMOUNT,
                amount1Max: MAX_COLLECT_AMOUNT
            })
        );
    }

    function _swapAllQuoteToBase(
        bool useOracleExitChecks
    ) internal {
        uint256 quoteBalance = PAIR_TOKEN.balanceOf(address(this));
        if (quoteBalance == 0) {
            return;
        }

        uint256 minBaseOut = useOracleExitChecks
            ? _minimumBaseOutForQuoteAmount(quoteBalance)
            : _minimumForcedExitBaseOutForQuoteAmount(quoteBalance);

        PAIR_TOKEN.forceApprove(address(SWAP_ROUTER), 0);
        PAIR_TOKEN.forceApprove(address(SWAP_ROUTER), quoteBalance);
        SWAP_ROUTER.exactInputSingle(
            IJuiceSwapSwapRouter.ExactInputSingleParams({
                tokenIn: address(PAIR_TOKEN),
                tokenOut: address(ASSET_TOKEN),
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: quoteBalance,
                amountOutMinimum: minBaseOut,
                sqrtPriceLimitX96: 0
            })
        );
        PAIR_TOKEN.forceApprove(address(SWAP_ROUTER), 0);
    }

    function _swapBaseForExactQuote(
        uint256 quoteAmount,
        uint256 maxBaseSpend
    ) internal {
        if (quoteAmount == 0) {
            return;
        }

        _validatedPoolState();

        ASSET_TOKEN.forceApprove(address(SWAP_ROUTER), 0);
        ASSET_TOKEN.forceApprove(address(SWAP_ROUTER), maxBaseSpend);
        SWAP_ROUTER.exactOutputSingle(
            IJuiceSwapSwapRouter.ExactOutputSingleParams({
                tokenIn: address(ASSET_TOKEN),
                tokenOut: address(PAIR_TOKEN),
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: quoteAmount,
                amountInMaximum: maxBaseSpend,
                sqrtPriceLimitX96: 0
            })
        );
        ASSET_TOKEN.forceApprove(address(SWAP_ROUTER), 0);
    }

    function _refreshPosition(
        bool updateLastRebalance
    ) internal {
        PositionSnapshot memory snapshot = _readPositionSnapshot();

        _position.version += 1;
        _position.lowerTick = snapshot.exists ? snapshot.lowerTick : int24(0);
        _position.upperTick = snapshot.exists ? snapshot.upperTick : int24(0);
        _position.liquidity = snapshot.exists ? snapshot.liquidity : 0;
        _position.active = snapshot.exists
            && (snapshot.liquidity != 0 || snapshot.tokensOwed0 != 0 || snapshot.tokensOwed1 != 0);
        _position.principalAssets = valuation().deployedAssets;
        if (updateLastRebalance) {
            _position.lastRebalance = uint64(block.timestamp);
        }
    }

    function _readPositionSnapshot() internal view returns (PositionSnapshot memory snapshot) {
        if (positionTokenId == 0) {
            return snapshot;
        }

        (
            ,,
            address token0,
            address token1,,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = POSITION_MANAGER.positions(positionTokenId);

        snapshot = PositionSnapshot({
            exists: true,
            token0: token0,
            token1: token1,
            lowerTick: tickLower,
            upperTick: tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: feeGrowthInside1LastX128,
            tokensOwed0: tokensOwed0,
            tokensOwed1: tokensOwed1
        });
    }

    function _liquidityAmounts(
        PositionSnapshot memory snapshot,
        uint160 sqrtPriceX96
    ) internal view returns (uint256 baseAmount, uint256 quoteAmount) {
        if (!snapshot.exists || snapshot.liquidity == 0) {
            return (0, 0);
        }

        uint160 sqrtLower = JuiceSwapTickMath.getSqrtRatioAtTick(snapshot.lowerTick);
        uint160 sqrtUpper = JuiceSwapTickMath.getSqrtRatioAtTick(snapshot.upperTick);
        (uint256 amount0, uint256 amount1) = JuiceSwapLiquidityMath.getAmountsForLiquidity(
            sqrtPriceX96, sqrtLower, sqrtUpper, snapshot.liquidity
        );

        return ASSET_IS_TOKEN0 ? (amount0, amount1) : (amount1, amount0);
    }

    function _pendingFeeBalances(
        PositionSnapshot memory snapshot,
        int24 currentTick
    ) internal view returns (uint256 baseFees, uint256 quoteFees) {
        if (!snapshot.exists) {
            return (0, 0);
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            _currentFeeGrowthInsideX128(snapshot.lowerTick, snapshot.upperTick, currentTick);
        (uint256 pending0, uint256 pending1) = JuiceSwapFeeMath.getPendingFees(
            snapshot.liquidity,
            feeGrowthInside0X128,
            feeGrowthInside1X128,
            snapshot.feeGrowthInside0LastX128,
            snapshot.feeGrowthInside1LastX128,
            snapshot.tokensOwed0,
            snapshot.tokensOwed1
        );

        return ASSET_IS_TOKEN0 ? (pending0, pending1) : (pending1, pending0);
    }

    function _idleBalances() internal view returns (uint256 baseIdle, uint256 quoteIdle) {
        return (ASSET_TOKEN.balanceOf(address(this)), PAIR_TOKEN.balanceOf(address(this)));
    }

    function _requiredBaseAndQuote(
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity
    ) internal view returns (uint256 directBaseAmount, uint256 quoteAmount) {
        (uint160 sqrtPriceX96,) = _validatedPoolState();
        uint160 sqrtLower = JuiceSwapTickMath.getSqrtRatioAtTick(lowerTick);
        uint160 sqrtUpper = JuiceSwapTickMath.getSqrtRatioAtTick(upperTick);
        (uint256 amount0, uint256 amount1) = JuiceSwapLiquidityMath.getAmountsForLiquidity(
            sqrtPriceX96, sqrtLower, sqrtUpper, liquidity
        );

        (directBaseAmount, quoteAmount) = ASSET_IS_TOKEN0 ? (amount0, amount1) : (amount1, amount0);
    }

    function _previewLiquidityForDesiredAmounts(
        int24 lowerTick,
        int24 upperTick,
        uint256 baseAmount,
        uint256 quoteAmount
    ) internal view returns (uint128 liquidity) {
        if (baseAmount == 0 && quoteAmount == 0) {
            return 0;
        }

        (uint160 sqrtPriceX96,) = _validatedPoolState();
        uint160 sqrtLower = JuiceSwapTickMath.getSqrtRatioAtTick(lowerTick);
        uint160 sqrtUpper = JuiceSwapTickMath.getSqrtRatioAtTick(upperTick);
        (uint256 amount0Desired, uint256 amount1Desired) =
            ASSET_IS_TOKEN0 ? (baseAmount, quoteAmount) : (quoteAmount, baseAmount);

        return JuiceSwapLiquidityMath.getLiquidityForAmounts(
            sqrtPriceX96, sqrtLower, sqrtUpper, amount0Desired, amount1Desired
        );
    }

    function _baseCostForLiquidity(
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity
    ) internal view returns (uint256) {
        (uint256 directBaseAmount, uint256 quoteAmount) =
            _requiredBaseAndQuote(lowerTick, upperTick, liquidity);
        (uint160 sqrtPriceX96,) = _validatedPoolState();
        return directBaseAmount + _quoteAmountToBaseInForExactOut(quoteAmount, sqrtPriceX96);
    }

    function _maxAffordableLiquidity(
        int24 lowerTick,
        int24 upperTick,
        uint128 targetLiquidity,
        uint256 baseBudget
    ) internal view returns (uint128 affordableLiquidity) {
        uint128 low = 0;
        uint128 high = targetLiquidity;

        while (low < high) {
            uint128 mid = low + (high - low + 1) / 2;
            if (_baseCostForLiquidity(lowerTick, upperTick, mid) <= baseBudget) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }

        return low;
    }

    function _validatedPoolState() internal view returns (uint160 sqrtPriceX96, int24 currentTick) {
        (sqrtPriceX96, currentTick,,,,,) = POOL.slot0();
        _assertPoolPriceWithinReference(sqrtPriceX96);
    }

    function _oracleExitChecksAvailable() internal view returns (bool) {
        try ORACLE_ROUTER.getPrice(address(ASSET_TOKEN)) returns (uint256 assetPrice, uint256) {
            if (assetPrice == 0) {
                return false;
            }
        } catch {
            return false;
        }

        try ORACLE_ROUTER.getPrice(address(PAIR_TOKEN)) returns (uint256 pairPrice, uint256) {
            return pairPrice != 0;
        } catch {
            return false;
        }
    }

    function _currentFeeGrowthInsideX128(
        int24 lowerTick,
        int24 upperTick,
        int24 currentTick
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        (JuiceSwapFeeMath.TickFeeData memory lower, bool lowerInitialized) = _tickFeeData(lowerTick);
        (JuiceSwapFeeMath.TickFeeData memory upper, bool upperInitialized) = _tickFeeData(upperTick);

        if (!lowerInitialized || !upperInitialized) {
            revert Errors.QuoteInvalid();
        }

        return JuiceSwapFeeMath.getFeeGrowthInside(
            currentTick,
            lowerTick,
            upperTick,
            POOL.feeGrowthGlobal0X128(),
            POOL.feeGrowthGlobal1X128(),
            lower,
            upper
        );
    }

    function _tickFeeData(
        int24 tick_
    ) internal view returns (JuiceSwapFeeMath.TickFeeData memory data, bool initialized) {
        (,, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128,,,, bool tickInitialized) =
            POOL.ticks(tick_);
        data = JuiceSwapFeeMath.TickFeeData({
            feeGrowthOutside0X128: feeGrowthOutside0X128,
            feeGrowthOutside1X128: feeGrowthOutside1X128
        });
        initialized = tickInitialized;
    }

    function _assertPoolPriceWithinReference(
        uint160 sqrtPriceX96
    ) internal view {
        uint256 poolQuoteAmount = _poolQuoteForBaseAmount(ASSET_UNIT, sqrtPriceX96);
        uint256 referenceQuoteAmount = _referenceQuoteForBaseAmount(ASSET_UNIT);
        uint256 absoluteDifference = poolQuoteAmount > referenceQuoteAmount
            ? poolQuoteAmount - referenceQuoteAmount
            : referenceQuoteAmount - poolQuoteAmount;
        uint256 deviationBps = Math.mulDiv(
            absoluteDifference, BPS_DENOMINATOR, referenceQuoteAmount, Math.Rounding.Ceil
        );

        if (deviationBps > MAX_PRICE_DEVIATION_BPS) {
            revert Errors.PoolPriceDeviation(
                poolQuoteAmount, referenceQuoteAmount, deviationBps, MAX_PRICE_DEVIATION_BPS
            );
        }
    }

    function _referenceQuoteForBaseAmount(
        uint256 baseAmount
    ) internal view returns (uint256) {
        (uint256 assetPrice,) = ORACLE_ROUTER.getPrice(address(ASSET_TOKEN));
        (uint256 pairPrice,) = ORACLE_ROUTER.getPrice(address(PAIR_TOKEN));
        uint256 baseValue = Math.mulDiv(baseAmount, assetPrice, ASSET_UNIT);
        return Math.mulDiv(baseValue, PAIR_UNIT, pairPrice);
    }

    function _referenceBaseForQuoteAmount(
        uint256 quoteAmount
    ) internal view returns (uint256) {
        (uint256 assetPrice,) = ORACLE_ROUTER.getPrice(address(ASSET_TOKEN));
        (uint256 pairPrice,) = ORACLE_ROUTER.getPrice(address(PAIR_TOKEN));
        uint256 quoteValue = Math.mulDiv(quoteAmount, pairPrice, PAIR_UNIT);
        return Math.mulDiv(quoteValue, ASSET_UNIT, assetPrice);
    }

    function _minimumBaseOutForQuoteAmount(
        uint256 quoteAmount
    ) internal view returns (uint256 minBaseOut) {
        uint256 referenceBaseOut = _referenceBaseForQuoteAmount(quoteAmount);
        uint256 referenceBaseAfterFee =
            Math.mulDiv(referenceBaseOut, FEE_DENOMINATOR - POOL_FEE, FEE_DENOMINATOR);
        minBaseOut = Math.mulDiv(
            referenceBaseAfterFee, BPS_DENOMINATOR - MAX_PRICE_DEVIATION_BPS, BPS_DENOMINATOR
        );
    }

    function _minimumForcedExitBaseOutForQuoteAmount(
        uint256 quoteAmount
    ) internal view returns (uint256 minBaseOut) {
        uint160 exitSqrtPriceX96 = _forcedExitSqrtPriceX96();
        uint256 baseAfterFee = _quoteToBaseAfterFee(quoteAmount, exitSqrtPriceX96);
        minBaseOut =
            Math.mulDiv(baseAfterFee, BPS_DENOMINATOR - MAX_PRICE_DEVIATION_BPS, BPS_DENOMINATOR);
    }

    function _forcedExitSqrtPriceX96() internal view returns (uint160 sqrtPriceX96) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = EXIT_TWAP_WINDOW;
        secondsAgos[1] = 0;

        try POOL.observe(secondsAgos) returns (int56[] memory tickCumulatives, uint160[] memory) {
            int56 tickDelta = tickCumulatives[1] - tickCumulatives[0];
            int56 window = int56(uint56(EXIT_TWAP_WINDOW));
            int24 meanTick = int24(tickDelta / window);
            if (tickDelta < 0 && tickDelta % window != 0) {
                meanTick -= 1;
            }
            return JuiceSwapTickMath.getSqrtRatioAtTick(meanTick);
        } catch {
            (sqrtPriceX96,,,,,,) = POOL.slot0();
        }
    }

    function _poolQuoteForBaseAmount(
        uint256 baseAmount,
        uint160 sqrtPriceX96
    ) internal view returns (uint256) {
        return ASSET_IS_TOKEN0
            ? _token0ToToken1AtSpot(baseAmount, sqrtPriceX96)
            : _token1ToToken0AtSpot(baseAmount, sqrtPriceX96);
    }

    function _quoteAmountToBaseInForExactOut(
        uint256 quoteAmount,
        uint160 sqrtPriceX96
    ) internal view returns (uint256) {
        if (quoteAmount == 0) {
            return 0;
        }

        uint256 baseWithoutFee = _quoteToBaseAtSpot(quoteAmount, sqrtPriceX96);
        return Math.mulDiv(
            baseWithoutFee, FEE_DENOMINATOR, FEE_DENOMINATOR - POOL_FEE, Math.Rounding.Ceil
        );
    }

    function _quoteToBaseAfterFee(
        uint256 quoteAmount,
        uint160 sqrtPriceX96
    ) internal view returns (uint256) {
        if (quoteAmount == 0) {
            return 0;
        }

        uint256 baseWithoutFee = _quoteToBaseAtSpot(quoteAmount, sqrtPriceX96);
        return Math.mulDiv(baseWithoutFee, FEE_DENOMINATOR - POOL_FEE, FEE_DENOMINATOR);
    }

    function _quoteToBaseAtSpot(
        uint256 quoteAmount,
        uint160 sqrtPriceX96
    ) internal view returns (uint256) {
        return ASSET_IS_TOKEN0
            ? _token1ToToken0AtSpot(quoteAmount, sqrtPriceX96)
            : _token0ToToken1AtSpot(quoteAmount, sqrtPriceX96);
    }

    function _token0ToToken1AtSpot(
        uint256 amount0,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256) {
        uint256 priceX96 = Math.mulDiv(sqrtPriceX96, sqrtPriceX96, JuiceSwapLiquidityMath.Q96);
        return Math.mulDiv(amount0, priceX96, JuiceSwapLiquidityMath.Q96);
    }

    function _token1ToToken0AtSpot(
        uint256 amount1,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256) {
        uint256 priceX96 = Math.mulDiv(sqrtPriceX96, sqrtPriceX96, JuiceSwapLiquidityMath.Q96);
        return Math.mulDiv(amount1, JuiceSwapLiquidityMath.Q96, priceX96);
    }

    function _hashIntent(
        Types.RebalanceIntent calldata intent
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                intent.targetLowerTick,
                intent.targetUpperTick,
                intent.targetLiquidity,
                intent.assetsToDeploy,
                intent.assetsToWithdraw,
                intent.deadline
            )
        );
    }

    function _allowedLiquidityShortfall(
        uint128 targetLiquidity
    ) internal pure returns (uint128) {
        uint128 tolerance = uint128(uint256(targetLiquidity) / FEE_DENOMINATOR);
        return tolerance == 0 ? 1 : tolerance;
    }
}
