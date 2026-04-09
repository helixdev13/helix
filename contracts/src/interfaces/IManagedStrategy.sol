// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IStrategy } from "./IStrategy.sol";
import { Types } from "../libraries/Types.sol";

interface IManagedStrategy is IStrategy {
    function adapter() external view returns (address);

    function oracleRouter() external view returns (address);

    function strategist() external view returns (address);

    function guardian() external view returns (address);

    function rebalancePaused() external view returns (bool);

    function totalIdle() external view returns (uint256);

    function totalDeployedAssets() external view returns (uint256);

    function totalConservativeAssets() external view returns (uint256);

    function positionState() external view returns (Types.PositionState memory);

    function adapterValuation() external view returns (Types.Valuation memory);

    function previewRebalance(
        Types.RebalanceIntent calldata intent
    ) external view returns (Types.RebalanceQuote memory);

    function rebalance(
        Types.RebalanceIntent calldata intent,
        Types.RebalanceQuote calldata quote,
        Types.ExecutionLimits calldata limits
    ) external;
}
