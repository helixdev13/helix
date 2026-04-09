// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Types } from "../libraries/Types.sol";

interface IClAdapter {
    function asset() external view returns (address);

    function strategy() external view returns (address);

    function bindStrategy(
        address strategy_
    ) external;

    function positionState() external view returns (Types.PositionState memory);

    function valuation() external view returns (Types.Valuation memory);

    function quoteRebalance(
        Types.RebalanceIntent calldata intent
    ) external view returns (Types.RebalanceQuote memory);

    function executeRebalance(
        Types.RebalanceIntent calldata intent,
        Types.RebalanceQuote calldata quote,
        Types.ExecutionLimits calldata limits
    ) external returns (Types.ExecutionReport memory);

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
