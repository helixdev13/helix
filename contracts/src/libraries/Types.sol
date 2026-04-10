// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library Types {
    struct RiskConfig {
        uint256 depositCap;
        uint16 maxAllocationBps;
        bool paused;
        bool withdrawOnly;
    }

    struct OracleConfig {
        address oracle;
        uint48 heartbeat;
    }

    struct PositionState {
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        uint256 principalAssets;
        uint64 version;
        uint64 lastRebalance;
        bool active;
    }

    struct Valuation {
        uint256 grossAssets;
        uint256 deployedAssets;
        uint256 pendingFees;
        uint16 haircutBps;
        uint256 haircutAmount;
        uint256 netAssets;
        uint64 positionVersion;
        uint64 timestamp;
    }

    struct RebalanceIntent {
        int24 targetLowerTick;
        int24 targetUpperTick;
        uint128 targetLiquidity;
        uint256 assetsToDeploy;
        uint256 assetsToWithdraw;
        uint64 deadline;
    }

    struct RebalanceQuote {
        bytes32 intentHash;
        uint64 positionVersion;
        uint64 quotedAt;
        uint64 validUntil;
        uint256 adapterAssetsBefore;
        uint256 assetsToDeploy;
        uint256 assetsToWithdraw;
        uint256 estimatedLoss;
        uint256 expectedAssetsOut;
        uint256 expectedAdapterAssetsAfter;
    }

    struct ExecutionLimits {
        uint256 minAssetsOut;
        uint256 maxLoss;
        uint64 deadline;
    }

    struct ExecutionReport {
        uint256 assetsIn;
        uint256 assetsOut;
        uint256 lossInAssets;
        uint256 harvestedFees;
        uint256 adapterAssetsAfter;
        uint64 positionVersion;
    }

    struct CompoundReport {
        uint256 profit;
        uint256 performanceFee;
        uint256 treasuryFee;
        uint256 hlxUserMint;
        uint256 bountyMint;
        uint256 reinvestAmount;
        bool reinvested;
    }

    struct CompoundConfig {
        uint16 performanceFeeBps;
        uint16 rewardRatioBps;
        uint16 bountyBps;
        uint256 hlxMintRate;
        uint256 minimumProfitThreshold;
        uint256 compoundCooldown;
        address feeRecipient;
        address hlxToken;
        address rewardDistributor;
    }
}
