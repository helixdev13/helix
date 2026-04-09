// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IClAdapter } from "../interfaces/IClAdapter.sol";
import { IManagedStrategy } from "../interfaces/IManagedStrategy.sol";
import { IOracleRouter } from "../interfaces/IOracleRouter.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { Types } from "../libraries/Types.sol";

contract ManagedClStrategy is Ownable2Step, ReentrancyGuard, IManagedStrategy {
    using SafeERC20 for IERC20;

    IERC20 public immutable ASSET_TOKEN;
    address public immutable VAULT;
    IClAdapter internal immutable ADAPTER;
    IOracleRouter internal immutable ORACLE_ROUTER;

    address public strategist;
    address public guardian;
    bool public rebalancePaused;

    constructor(
        IERC20 asset_,
        address vault_,
        IClAdapter adapter_,
        IOracleRouter oracleRouter_,
        address initialOwner,
        address strategist_,
        address guardian_
    ) Ownable(initialOwner) {
        if (
            address(asset_) == address(0) || vault_ == address(0) || address(adapter_) == address(0)
                || address(oracleRouter_) == address(0)
        ) {
            revert Errors.ZeroAddress();
        }
        if (adapter_.asset() != address(asset_)) {
            revert Errors.StrategyAssetMismatch(address(asset_), adapter_.asset());
        }

        ASSET_TOKEN = asset_;
        VAULT = vault_;
        ADAPTER = adapter_;
        ORACLE_ROUTER = oracleRouter_;
        strategist = strategist_;
        guardian = guardian_;

        adapter_.bindStrategy(address(this));

        emit Events.StrategyStrategistUpdated(strategist_);
        emit Events.StrategyGuardianUpdated(guardian_);
    }

    modifier onlyVault() {
        _onlyVault();
        _;
    }

    modifier onlyOwnerOrStrategist() {
        _onlyOwnerOrStrategist();
        _;
    }

    function asset() external view returns (address) {
        return address(ASSET_TOKEN);
    }

    function _onlyVault() internal view {
        if (msg.sender != VAULT) {
            revert Errors.Unauthorized();
        }
    }

    function _onlyOwnerOrStrategist() internal view {
        if (msg.sender != owner() && msg.sender != strategist) {
            revert Errors.OnlyOwnerOrStrategist();
        }
    }

    function vault() external view returns (address) {
        return VAULT;
    }

    function adapter() external view returns (address) {
        return address(ADAPTER);
    }

    function oracleRouter() external view returns (address) {
        return address(ORACLE_ROUTER);
    }

    function totalIdle() public view returns (uint256) {
        return ASSET_TOKEN.balanceOf(address(this));
    }

    function totalDeployedAssets() public view returns (uint256) {
        return ADAPTER.valuation().grossAssets;
    }

    function totalConservativeAssets() public view returns (uint256) {
        return totalIdle() + ADAPTER.valuation().netAssets;
    }

    function totalAssets() public view returns (uint256) {
        return totalIdle() + totalDeployedAssets();
    }

    function positionState() external view returns (Types.PositionState memory) {
        return ADAPTER.positionState();
    }

    function adapterValuation() public view returns (Types.Valuation memory) {
        return ADAPTER.valuation();
    }

    function deposit(
        uint256 assets
    ) external onlyVault nonReentrant {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }

        ASSET_TOKEN.safeTransferFrom(msg.sender, address(this), assets);
    }

    function withdraw(
        uint256 assets,
        address receiver
    ) external onlyVault nonReentrant {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        _ensureLiquidity(assets);
        ASSET_TOKEN.safeTransfer(receiver, assets);
    }

    function harvest() external onlyVault nonReentrant {
        ADAPTER.harvestTo(address(this));
    }

    function unwindAll() external onlyVault nonReentrant {
        ADAPTER.unwindAllTo(address(this));

        uint256 idleAssets = totalIdle();
        if (idleAssets != 0) {
            ASSET_TOKEN.safeTransfer(VAULT, idleAssets);
        }
    }

    function previewRebalance(
        Types.RebalanceIntent calldata intent
    ) external view returns (Types.RebalanceQuote memory quote) {
        _validateIntent(intent);
        quote = ADAPTER.quoteRebalance(intent);
    }

    function rebalance(
        Types.RebalanceIntent calldata intent,
        Types.RebalanceQuote calldata quote,
        Types.ExecutionLimits calldata limits
    ) external onlyOwnerOrStrategist nonReentrant {
        if (rebalancePaused) {
            revert Errors.RebalancePaused();
        }

        _validateIntent(intent);
        _enforceDeadline(intent.deadline);
        _enforceDeadline(limits.deadline);
        ORACLE_ROUTER.getPrice(address(ASSET_TOKEN));

        Types.RebalanceQuote memory freshQuote = ADAPTER.quoteRebalance(intent);
        _validateQuoteFacts(quote, freshQuote);

        if (intent.assetsToDeploy != 0) {
            ASSET_TOKEN.forceApprove(address(ADAPTER), 0);
            ASSET_TOKEN.forceApprove(address(ADAPTER), intent.assetsToDeploy);
        }

        Types.ExecutionReport memory report = ADAPTER.executeRebalance(intent, quote, limits);

        if (intent.assetsToDeploy != 0) {
            ASSET_TOKEN.forceApprove(address(ADAPTER), 0);
        }

        emit Events.StrategyRebalanced(
            address(this),
            address(ADAPTER),
            report.assetsIn,
            report.assetsOut,
            report.lossInAssets,
            report.adapterAssetsAfter,
            report.positionVersion
        );
    }

    function setStrategist(
        address newStrategist
    ) external onlyOwner {
        strategist = newStrategist;
        emit Events.StrategyStrategistUpdated(newStrategist);
    }

    function setGuardian(
        address newGuardian
    ) external onlyOwner {
        guardian = newGuardian;
        emit Events.StrategyGuardianUpdated(newGuardian);
    }

    function setRebalancePaused(
        bool enabled
    ) external {
        if (msg.sender != owner() && msg.sender != guardian) {
            revert Errors.GuardianOnlyOrOwner();
        }
        if (!enabled && msg.sender != owner()) {
            revert Errors.OnlyOwnerCanDisableRebalancePause();
        }

        rebalancePaused = enabled;
        emit Events.RebalancePauseUpdated(msg.sender, enabled);
    }

    function _ensureLiquidity(
        uint256 assets
    ) internal {
        uint256 idleAssets = totalIdle();
        if (idleAssets >= assets) {
            return;
        }

        ADAPTER.withdrawTo(address(this), assets - idleAssets);

        uint256 updatedIdleAssets = totalIdle();
        if (updatedIdleAssets < assets) {
            revert Errors.InsufficientLiquidAssets(updatedIdleAssets, assets);
        }
    }

    function _validateIntent(
        Types.RebalanceIntent calldata intent
    ) internal pure {
        if (intent.targetLowerTick >= intent.targetUpperTick) {
            revert Errors.InvalidTicks(intent.targetLowerTick, intent.targetUpperTick);
        }
    }

    function _enforceDeadline(
        uint64 deadline
    ) internal view {
        if (block.timestamp > deadline) {
            revert Errors.DeadlineExpired(block.timestamp, deadline);
        }
    }

    function _validateQuoteFacts(
        Types.RebalanceQuote calldata providedQuote,
        Types.RebalanceQuote memory freshQuote
    ) internal view {
        if (
            providedQuote.quotedAt > block.timestamp
                || providedQuote.validUntil < providedQuote.quotedAt
        ) {
            revert Errors.QuoteInvalid();
        }
        if (block.timestamp > providedQuote.validUntil) {
            revert Errors.QuoteExpired(block.timestamp, providedQuote.validUntil);
        }
        if (
            providedQuote.validUntil - providedQuote.quotedAt
                != freshQuote.validUntil - freshQuote.quotedAt
        ) {
            revert Errors.QuoteInvalid();
        }
        if (providedQuote.intentHash != freshQuote.intentHash) {
            revert Errors.QuoteIntentMismatch(freshQuote.intentHash, providedQuote.intentHash);
        }
        if (providedQuote.positionVersion != freshQuote.positionVersion) {
            revert Errors.QuotePositionMismatch(
                freshQuote.positionVersion, providedQuote.positionVersion
            );
        }
        if (
            providedQuote.adapterAssetsBefore != freshQuote.adapterAssetsBefore
                || providedQuote.assetsToDeploy != freshQuote.assetsToDeploy
                || providedQuote.assetsToWithdraw != freshQuote.assetsToWithdraw
                || providedQuote.estimatedLoss != freshQuote.estimatedLoss
                || providedQuote.expectedAssetsOut != freshQuote.expectedAssetsOut
                || providedQuote.expectedAdapterAssetsAfter != freshQuote.expectedAdapterAssetsAfter
        ) {
            revert Errors.QuoteFactsMismatch();
        }
    }
}
