// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library Events {
    event DepositCapUpdated(address indexed vault, uint256 previousCap, uint256 newCap);
    event MaxAllocationUpdated(address indexed vault, uint16 previousBps, uint16 newBps);
    event RiskPauseUpdated(address indexed vault, bool paused);
    event RiskWithdrawOnlyUpdated(address indexed vault, bool withdrawOnly);
    event RiskConfigSet(
        address indexed vault,
        uint256 depositCap,
        uint16 maxAllocationBps,
        bool paused,
        bool withdrawOnly
    );
    event OracleConfigured(address indexed asset, address indexed oracle, uint48 heartbeat);
    event StrategyUpdated(address indexed previousStrategy, address indexed newStrategy);
    event StrategyAllocated(address indexed strategy, uint256 assets);
    event StrategyHarvested(address indexed strategy, uint256 totalAssets);
    event StrategyUnwound(address indexed strategy, uint256 assetsReturned);
    event GuardianUpdated(address indexed guardian);
    event PauseUpdated(address indexed caller, bool enabled);
    event LocalWithdrawOnlySet(address indexed caller, bool enabled);
    event StrategyStrategistUpdated(address indexed strategist);
    event StrategyGuardianUpdated(address indexed guardian);
    event RebalancePauseUpdated(address indexed caller, bool enabled);
    event AdapterStrategyBound(address indexed adapter, address indexed strategy);
    event StrategyRebalanced(
        address indexed strategy,
        address indexed adapter,
        uint256 assetsIn,
        uint256 assetsOut,
        uint256 lossInAssets,
        uint256 adapterAssetsAfter,
        uint64 positionVersion
    );
    event AdapterHarvested(address indexed adapter, uint256 assetsHarvested);
    event AdapterWithdrawal(
        address indexed adapter, address indexed receiver, uint256 assetsWithdrawn
    );
    event AdapterUnwound(address indexed adapter, uint256 assetsReturned);
    event AdapterSimulationUpdated(
        address indexed adapter,
        uint16 executionLossBps,
        uint16 valuationHaircutBps,
        uint64 quoteValidity,
        bool forceQuoteInvalid
    );
}
