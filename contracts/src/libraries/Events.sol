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
    event AllocatorPauseUpdated(address indexed caller, bool enabled);
    event AllocatorIdleFloorUpdated(address indexed caller, uint16 previousBps, uint16 newBps);
    event AllocatorGlobalAllocationCapUpdated(
        address indexed caller, uint16 previousBps, uint16 newBps
    );
    event AdapterStrategyBound(address indexed adapter, address indexed strategy);
    event AllocatorAdapterConfigured(
        address indexed adapter, bool enabled, uint16 maxAllocationBps
    );
    event AllocatorAllocated(address indexed strategy, address indexed adapter, uint256 assets);
    event AllocatorDeallocated(address indexed strategy, address indexed adapter, uint256 assets);
    event AllocatorAdapterWithdrawal(
        address indexed strategy,
        address indexed adapter,
        uint256 requestedAssets,
        uint256 assetsReceived
    );
    event AllocatorAdapterHarvest(
        address indexed strategy, address indexed adapter, uint256 assetsHarvested
    );
    event AllocatorAdapterUnwind(
        address indexed strategy, address indexed adapter, uint256 assetsReturned
    );
    event AllocatorAdapterOperationFailed(
        address indexed strategy,
        address indexed adapter,
        uint8 indexed operation,
        uint256 requestedAssets,
        bytes reason
    );
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
    event CompoundExecuted(
        address indexed strategy,
        uint256 profit,
        uint256 performanceFee,
        uint256 treasuryFee,
        uint256 hlxMinted,
        uint256 bounty,
        uint256 reinvestAmount,
        bool reinvested
    );
    event ReinvestDeferred(address indexed strategy, uint256 amount, bytes reason);
    event RewardDistributed(address indexed distributor, uint256 amount);
    event HlxMintRateUpdated(address indexed caller, uint256 previousRate, uint256 newRate);
    event CompoundConfigUpdated(address indexed caller, string parameter, uint256 value);
    event PerformanceFeeUpdated(address indexed caller, uint16 previousBps, uint16 newBps);
    event RewardRatioUpdated(address indexed caller, uint16 previousBps, uint16 newBps);
    event CompoundCooldownUpdated(address indexed caller, uint256 previous, uint256 newCooldown);
}
