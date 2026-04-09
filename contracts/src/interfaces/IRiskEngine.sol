// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Types } from "../libraries/Types.sol";

interface IRiskEngine {
    function getConfig(
        address vault
    ) external view returns (Types.RiskConfig memory);

    function getDepositCap(
        address vault
    ) external view returns (uint256);

    function getMaxAllocationBps(
        address vault
    ) external view returns (uint16);

    function isPaused(
        address vault
    ) external view returns (bool);

    function isWithdrawOnly(
        address vault
    ) external view returns (bool);
}
