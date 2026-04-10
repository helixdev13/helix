// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { AllocatorTypes } from "../libraries/AllocatorTypes.sol";

interface IAllocatorAdapter {
    function asset() external view returns (address);

    function strategy() external view returns (address);

    function bindStrategy(
        address strategy_
    ) external;

    function healthState() external view returns (AllocatorTypes.HealthState);

    function valuation() external view returns (AllocatorTypes.AdapterValuation memory);

    function withdrawableAssets() external view returns (uint256);

    function pendingRewards() external view returns (uint256);

    function maxDeposit() external view returns (uint256);

    function deposit(
        uint256 assets
    ) external returns (uint256 assetsDeposited);

    function withdrawTo(
        address receiver,
        uint256 assets
    ) external returns (uint256 assetsWithdrawn);

    function harvestTo(
        address receiver
    ) external returns (uint256 assetsHarvested);

    function unwindAllTo(
        address receiver
    ) external returns (uint256 assetsReturned);
}
