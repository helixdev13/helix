// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { HelixVault } from "../HelixVault.sol";
import { IRiskEngine } from "../interfaces/IRiskEngine.sol";
import { Types } from "../libraries/Types.sol";

/// @notice Minimal view surface for an auto-compound strategy.
interface IAutoCompoundClStrategy {
    /// @notice Return the adapter address.
    /// @return Address of the CL adapter.
    function adapter() external view returns (address);

    /// @notice Return the compounder configuration.
    /// @return Configured compound parameters.
    function compoundConfig() external view returns (Types.CompoundConfig memory);

    /// @notice Return idle assets held directly by the strategy.
    /// @return Idle asset balance.
    function totalIdle() external view returns (uint256);

    /// @notice Return gross deployed assets reported by the adapter.
    /// @return Deployed asset balance.
    function totalDeployedAssets() external view returns (uint256);

    /// @notice Return total assets tracked by the strategy.
    /// @return Total strategy assets.
    function totalAssets() external view returns (uint256);

    /// @notice Return the current rebalance pause flag.
    /// @return `true` when rebalances are paused.
    function rebalancePaused() external view returns (bool);

    /// @notice Return the timestamp of the last compound.
    /// @return Timestamp of the last successful compound.
    function lastCompoundTimestamp() external view returns (uint256);
}

/// @notice Read-only lens for Helix vault and auto-compound strategy state.
/// @dev Intended for operator dashboards and off-chain verification.
contract HelixLens {
    /// @notice Vault state snapshot used by operators and dashboards.
    /// @dev Values are read directly from the vault and risk engine.
    struct VaultView {
        address vault;
        address asset;
        address guardian;
        address strategy;
        address riskEngine;
        uint256 totalAssets;
        uint256 totalIdle;
        uint256 totalStrategyAssets;
        uint256 depositCap;
        uint16 maxAllocationBps;
        bool paused;
        bool withdrawOnly;
    }

    /// @notice Auto-compound strategy state snapshot.
    /// @dev Combines compound configuration, adapter state, and accounting totals.
    struct CompoundStrategyView {
        address vault;
        address strategy;
        address adapter;
        uint16 performanceFeeBps;
        uint16 rewardRatioBps;
        uint16 bountyBps;
        uint256 hlxMintRate;
        uint256 minimumProfitThreshold;
        uint256 compoundCooldown;
        uint256 lastCompoundTimestamp;
        address feeRecipient;
        address hlxToken;
        address rewardDistributor;
        uint256 totalIdle;
        uint256 totalDeployedAssets;
        uint256 totalAssets;
        bool rebalancePaused;
    }

    /// @notice Return the current vault and risk-engine view for a Helix vault.
    /// @param vault Helix vault to inspect.
    /// @return view_ Read-only vault snapshot.
    function getVaultView(
        HelixVault vault
    ) external view returns (VaultView memory view_) {
        IRiskEngine riskEngine = vault.RISK_ENGINE();

        view_ = VaultView({
            vault: address(vault),
            asset: vault.asset(),
            guardian: vault.guardian(),
            strategy: address(vault.strategy()),
            riskEngine: address(riskEngine),
            totalAssets: vault.totalAssets(),
            totalIdle: vault.totalIdle(),
            totalStrategyAssets: vault.totalStrategyAssets(),
            depositCap: riskEngine.getDepositCap(address(vault)),
            maxAllocationBps: riskEngine.getMaxAllocationBps(address(vault)),
            paused: vault.paused(),
            withdrawOnly: vault.withdrawOnly()
        });
    }

    /// @notice Return the auto-compound strategy view for a Helix vault.
    /// @param vault Helix vault to inspect.
    /// @return view_ Read-only compound strategy snapshot.
    function getCompoundStrategyView(
        HelixVault vault
    ) external view returns (CompoundStrategyView memory view_) {
        address strategy = address(vault.strategy());
        if (strategy == address(0)) {
            return view_;
        }

        IAutoCompoundClStrategy compoundStrategy = IAutoCompoundClStrategy(strategy);
        Types.CompoundConfig memory config = compoundStrategy.compoundConfig();

        view_ = CompoundStrategyView({
            vault: address(vault),
            strategy: strategy,
            adapter: compoundStrategy.adapter(),
            performanceFeeBps: config.performanceFeeBps,
            rewardRatioBps: config.rewardRatioBps,
            bountyBps: config.bountyBps,
            hlxMintRate: config.hlxMintRate,
            minimumProfitThreshold: config.minimumProfitThreshold,
            compoundCooldown: config.compoundCooldown,
            lastCompoundTimestamp: compoundStrategy.lastCompoundTimestamp(),
            feeRecipient: config.feeRecipient,
            hlxToken: config.hlxToken,
            rewardDistributor: config.rewardDistributor,
            totalIdle: compoundStrategy.totalIdle(),
            totalDeployedAssets: compoundStrategy.totalDeployedAssets(),
            totalAssets: compoundStrategy.totalAssets(),
            rebalancePaused: compoundStrategy.rebalancePaused()
        });
    }

}
