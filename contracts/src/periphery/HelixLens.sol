// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { HelixVault } from "../HelixVault.sol";
import { IRiskEngine } from "../interfaces/IRiskEngine.sol";
import { Types } from "../libraries/Types.sol";

interface IAutoCompoundClStrategy {
    function adapter() external view returns (address);

    function compoundConfig() external view returns (Types.CompoundConfig memory);

    function totalIdle() external view returns (uint256);

    function totalDeployedAssets() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function rebalancePaused() external view returns (bool);

    function lastCompoundTimestamp() external view returns (uint256);
}

contract HelixLens {
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
