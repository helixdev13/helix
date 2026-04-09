// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IJuiceSwapFactory {
    function feeAmountTickSpacing(
        uint24 fee
    ) external view returns (int24);

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}
