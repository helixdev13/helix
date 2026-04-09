// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IStrategy {
    function asset() external view returns (address);

    function vault() external view returns (address);

    function deposit(
        uint256 assets
    ) external;

    function withdraw(
        uint256 assets,
        address receiver
    ) external;

    function totalAssets() external view returns (uint256);

    function harvest() external;

    function unwindAll() external;
}
