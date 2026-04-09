// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IOracleRouter {
    function getPrice(
        address asset
    ) external view returns (uint256 price, uint256 updatedAt);

    function isStale(
        address asset
    ) external view returns (bool);

    function quoteAsset(
        address asset,
        uint256 amount
    ) external view returns (uint256 value);
}
