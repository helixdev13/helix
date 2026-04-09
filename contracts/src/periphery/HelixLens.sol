// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { HelixVault } from "../HelixVault.sol";
import { IRiskEngine } from "../interfaces/IRiskEngine.sol";

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
}
