// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library Errors {
    error ZeroAddress();
    error ZeroAmount();
    error Unauthorized();
    error DepositsDisabled();
    error AllocationDisabled();
    error DepositCapExceeded(uint256 totalAssetsAfter, uint256 cap);
    error AllocationCapExceeded(uint256 requestedAllocation, uint256 maxAllowed);
    error StrategyNotSet();
    error StrategyNotEmpty(address strategy, uint256 assets);
    error StrategyAssetMismatch(address expected, address actual);
    error StrategyVaultMismatch(address expected, address actual);
    error InvalidBps(uint256 bps);
    error InvalidHeartbeat();
    error InvalidOracle(address asset);
    error InvalidPrice(address asset);
    error StalePrice(address asset, uint256 updatedAt, uint256 currentTimestamp, uint256 heartbeat);
    error GuardianOnlyOrOwner();
    error OnlyOwnerCanDisable();
    error OnlyOwnerOrStrategist();
    error OnlyOwnerCanDisableRebalancePause();
    error NoSharesMinted();
    error InsufficientLiquidAssets(uint256 available, uint256 required);
    error RebalancePaused();
    error DeadlineExpired(uint256 currentTimestamp, uint256 deadline);
    error QuoteExpired(uint256 currentTimestamp, uint256 validUntil);
    error QuoteIntentMismatch(bytes32 expected, bytes32 actual);
    error QuotePositionMismatch(uint256 expected, uint256 actual);
    error QuoteFactsMismatch();
    error QuoteInvalid();
    error LossExceeded(uint256 actualLoss, uint256 maxLoss);
    error MinAssetsOutNotMet(uint256 actualAssetsOut, uint256 minAssetsOut);
    error InvalidTicks(int24 lowerTick, int24 upperTick);
    error InvalidTickSpacing(int24 lowerTick, int24 upperTick, int24 spacing);
    error InvalidQuoteWindow();
    error StrategyAlreadyBound(address strategy);
    error AdapterAlreadyAdded(address adapter);
    error AdapterNotApproved(address adapter);
    error AdapterDisabled(address adapter);
    error AdapterNotHealthy(address adapter, uint8 health);
    error AdapterCapacityExceeded(address adapter, uint256 requestedAssets, uint256 maxDeposit);
    error AdapterDepositMismatch(
        address adapter,
        uint256 requestedAssets,
        uint256 actualAssetsSpent,
        uint256 reportedAssetsDeployed
    );
    error IdleFloorViolation(uint256 idleAssetsAfter, uint256 minimumIdleRequired);
    error InvalidRewardAmounts(uint256 conservativeRewards, uint256 liveRewards);
    error PoolNotFound(address tokenA, address tokenB, uint24 fee);
    error InvalidPoolTokens(
        address expectedAsset, address expectedPair, address token0, address token1
    );
    error PoolPriceDeviation(
        uint256 poolQuoteAmount,
        uint256 referenceQuoteAmount,
        uint256 deviationBps,
        uint256 maxDeviationBps
    );
    error UnexpectedLiquidity(uint128 actualLiquidity, uint128 targetLiquidity);
    error CompoundCooldownActive(uint256 remaining);
    error InsufficientProfit(uint256 profit, uint256 threshold);
    error InvalidHlxMintRate();
    error InvalidRewardRatio();
    error InvalidBountyBps(uint256 bps);
    error RewardMintFailed();
    error FeeTransferFailed();
    error NoPositionToReinvest();
}
