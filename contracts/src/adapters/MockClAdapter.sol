// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IClAdapter } from "../interfaces/IClAdapter.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { Types } from "../libraries/Types.sol";

contract MockClAdapter is IClAdapter, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint16 public constant BPS_DENOMINATOR = 10_000;
    address internal constant LOSS_SINK = address(0x000000000000000000000000000000000000dEaD);

    IERC20 public immutable ASSET_TOKEN;

    address public strategy;

    Types.PositionState private _position;

    uint16 public executionLossBps;
    uint16 public valuationHaircutBps;
    uint64 public quoteValidity;
    bool public forceQuoteInvalid;

    constructor(
        IERC20 asset_,
        uint64 quoteValidity_
    ) {
        if (address(asset_) == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (quoteValidity_ == 0) {
            revert Errors.InvalidQuoteWindow();
        }

        ASSET_TOKEN = asset_;
        quoteValidity = quoteValidity_;
    }

    modifier onlyStrategy() {
        _onlyStrategy();
        _;
    }

    function asset() external view returns (address) {
        return address(ASSET_TOKEN);
    }

    function _onlyStrategy() internal view {
        if (msg.sender != strategy) {
            revert Errors.Unauthorized();
        }
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
        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));
        uint256 deployedAssets =
            grossAssets > _position.principalAssets ? _position.principalAssets : grossAssets;
        uint256 pendingFees =
            grossAssets > _position.principalAssets ? grossAssets - _position.principalAssets : 0;
        uint256 haircutAmount = grossAssets * valuationHaircutBps / BPS_DENOMINATOR;

        value = Types.Valuation({
            grossAssets: grossAssets,
            deployedAssets: deployedAssets,
            pendingFees: pendingFees,
            haircutBps: valuationHaircutBps,
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

        Types.Valuation memory value = valuation();
        uint256 estimatedLoss =
            (intent.assetsToDeploy + intent.assetsToWithdraw) * executionLossBps / BPS_DENOMINATOR;
        uint256 assetsAvailableAfterLoss = value.grossAssets + intent.assetsToDeploy;
        if (estimatedLoss > assetsAvailableAfterLoss) {
            estimatedLoss = assetsAvailableAfterLoss;
        }

        uint256 expectedAssetsOut = intent.assetsToWithdraw;
        if (expectedAssetsOut + estimatedLoss > assetsAvailableAfterLoss) {
            expectedAssetsOut = assetsAvailableAfterLoss > estimatedLoss
                ? assetsAvailableAfterLoss - estimatedLoss
                : 0;
        }

        quote = Types.RebalanceQuote({
            intentHash: _hashIntent(intent),
            positionVersion: _position.version,
            quotedAt: uint64(block.timestamp),
            validUntil: uint64(block.timestamp) + quoteValidity,
            adapterAssetsBefore: value.grossAssets,
            assetsToDeploy: intent.assetsToDeploy,
            assetsToWithdraw: intent.assetsToWithdraw,
            estimatedLoss: estimatedLoss,
            expectedAssetsOut: expectedAssetsOut,
            expectedAdapterAssetsAfter: assetsAvailableAfterLoss - estimatedLoss - expectedAssetsOut
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

        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));
        uint256 lossInAssets =
            (intent.assetsToDeploy + intent.assetsToWithdraw) * executionLossBps / BPS_DENOMINATOR;
        if (lossInAssets > limits.maxLoss) {
            revert Errors.LossExceeded(lossInAssets, limits.maxLoss);
        }
        if (lossInAssets > grossAssets) {
            lossInAssets = grossAssets;
        }

        if (lossInAssets != 0) {
            ASSET_TOKEN.safeTransfer(LOSS_SINK, lossInAssets);
            grossAssets -= lossInAssets;
        }

        uint256 assetsOut = intent.assetsToWithdraw;
        if (assetsOut > grossAssets) {
            assetsOut = grossAssets;
        }
        if (assetsOut < limits.minAssetsOut) {
            revert Errors.MinAssetsOutNotMet(assetsOut, limits.minAssetsOut);
        }

        if (assetsOut != 0) {
            ASSET_TOKEN.safeTransfer(msg.sender, assetsOut);
            grossAssets -= assetsOut;
        }

        _position.lowerTick = intent.targetLowerTick;
        _position.upperTick = intent.targetUpperTick;
        _position.liquidity = intent.targetLiquidity;
        _position.principalAssets = grossAssets;
        _position.version += 1;
        _position.lastRebalance = uint64(block.timestamp);
        _position.active = grossAssets != 0;

        report = Types.ExecutionReport({
            assetsIn: intent.assetsToDeploy,
            assetsOut: assetsOut,
            lossInAssets: lossInAssets,
            harvestedFees: 0,
            adapterAssetsAfter: grossAssets,
            positionVersion: _position.version
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

        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));
        if (grossAssets < assets) {
            revert Errors.InsufficientLiquidAssets(grossAssets, assets);
        }

        ASSET_TOKEN.safeTransfer(receiver, assets);
        grossAssets -= assets;

        _position.principalAssets = grossAssets;
        _position.active = grossAssets != 0;
        _position.version += 1;

        emit Events.AdapterWithdrawal(address(this), receiver, assets);
        return assets;
    }

    function harvestTo(
        address receiver
    ) external onlyStrategy nonReentrant returns (uint256 assetsHarvested) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        Types.Valuation memory value = valuation();
        assetsHarvested = value.pendingFees;

        if (assetsHarvested != 0) {
            ASSET_TOKEN.safeTransfer(receiver, assetsHarvested);
        }

        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));
        _position.principalAssets = grossAssets;
        _position.active = grossAssets != 0;
        _position.version += 1;

        emit Events.AdapterHarvested(address(this), assetsHarvested);
    }

    function unwindAllTo(
        address receiver
    ) external onlyStrategy nonReentrant returns (uint256 assetsReturned) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        assetsReturned = ASSET_TOKEN.balanceOf(address(this));
        if (assetsReturned != 0) {
            ASSET_TOKEN.safeTransfer(receiver, assetsReturned);
        }

        _position.principalAssets = 0;
        _position.liquidity = 0;
        _position.version += 1;
        _position.lastRebalance = uint64(block.timestamp);
        _position.active = false;

        emit Events.AdapterUnwound(address(this), assetsReturned);
    }

    function setExecutionLossBps(
        uint16 newExecutionLossBps
    ) external onlyStrategy {
        if (newExecutionLossBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(newExecutionLossBps);
        }

        executionLossBps = newExecutionLossBps;
        _position.version += 1;
        _emitSimulationUpdate();
    }

    function setValuationHaircutBps(
        uint16 newValuationHaircutBps
    ) external onlyStrategy {
        if (newValuationHaircutBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(newValuationHaircutBps);
        }

        valuationHaircutBps = newValuationHaircutBps;
        _position.version += 1;
        _emitSimulationUpdate();
    }

    function setQuoteValidity(
        uint64 newQuoteValidity
    ) external onlyStrategy {
        if (newQuoteValidity == 0) {
            revert Errors.InvalidQuoteWindow();
        }

        quoteValidity = newQuoteValidity;
        _position.version += 1;
        _emitSimulationUpdate();
    }

    function setForceQuoteInvalid(
        bool invalidQuote
    ) external onlyStrategy {
        forceQuoteInvalid = invalidQuote;
        _position.version += 1;
        _emitSimulationUpdate();
    }

    function _validateIntent(
        Types.RebalanceIntent calldata intent
    ) internal pure {
        if (intent.targetLowerTick >= intent.targetUpperTick) {
            revert Errors.InvalidTicks(intent.targetLowerTick, intent.targetUpperTick);
        }
    }

    function _validateQuote(
        Types.RebalanceIntent calldata intent,
        Types.RebalanceQuote calldata quote,
        Types.ExecutionLimits calldata limits
    ) internal view {
        if (forceQuoteInvalid) {
            revert Errors.QuoteInvalid();
        }
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

    function _emitSimulationUpdate() internal {
        emit Events.AdapterSimulationUpdated(
            address(this), executionLossBps, valuationHaircutBps, quoteValidity, forceQuoteInvalid
        );
    }
}
