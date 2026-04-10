// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library AllocatorTypes {
    enum HealthState {
        Healthy,
        Degraded,
        Blocked
    }

    struct AdapterConfig {
        bool approved;
        bool enabled;
        uint16 maxAllocationBps;
    }

    struct AdapterValuation {
        uint256 grossAssets;
        uint256 deployedAssets;
        uint256 withdrawableAssets;
        uint256 pendingRewards;
        uint16 haircutBps;
        uint256 haircutAmount;
        uint256 netAssets;
        uint64 timestamp;
    }

    struct AdapterState {
        address adapter;
        AdapterConfig config;
        HealthState healthState;
        AdapterValuation valuation;
    }

    struct AllocatorState {
        uint256 totalIdleAssets;
        uint256 totalDeployedAssets;
        uint256 totalWithdrawableAssets;
        uint256 totalPendingRewards;
        uint256 totalLiveAssets;
        uint256 totalConservativeAssets;
        HealthState healthState;
        bool allocationPaused;
        uint16 idleFloorBps;
        uint16 globalAllocationCapBps;
        uint256 adapterCount;
        uint256 activeAdapterCount;
    }
}
