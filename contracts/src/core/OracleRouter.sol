// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IOracleRouter } from "../interfaces/IOracleRouter.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { Types } from "../libraries/Types.sol";

interface IPriceSource {
    function latestPrice() external view returns (uint256 price, uint256 updatedAt);
}

contract OracleRouter is Ownable2Step, IOracleRouter {
    mapping(address asset => Types.OracleConfig config) private _configs;

    constructor(
        address initialOwner
    ) Ownable(initialOwner) { }

    function setOracle(
        address asset,
        address oracle,
        uint48 heartbeat
    ) external onlyOwner {
        if (asset == address(0) || oracle == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (heartbeat == 0) {
            revert Errors.InvalidHeartbeat();
        }

        _configs[asset] = Types.OracleConfig({ oracle: oracle, heartbeat: heartbeat });

        emit Events.OracleConfigured(asset, oracle, heartbeat);
    }

    function getConfig(
        address asset
    ) external view returns (Types.OracleConfig memory) {
        return _configs[asset];
    }

    function getPrice(
        address asset
    ) public view returns (uint256 price, uint256 updatedAt) {
        Types.OracleConfig memory config = _configs[asset];
        if (config.oracle == address(0)) {
            revert Errors.InvalidOracle(asset);
        }

        (price, updatedAt) = IPriceSource(config.oracle).latestPrice();
        if (price == 0) {
            revert Errors.InvalidPrice(asset);
        }
        if (_isStale(updatedAt, config.heartbeat)) {
            revert Errors.StalePrice(asset, updatedAt, block.timestamp, config.heartbeat);
        }
    }

    function isStale(
        address asset
    ) public view returns (bool) {
        Types.OracleConfig memory config = _configs[asset];
        if (config.oracle == address(0)) {
            return true;
        }

        (, uint256 updatedAt) = IPriceSource(config.oracle).latestPrice();
        return _isStale(updatedAt, config.heartbeat);
    }

    function quoteAsset(
        address asset,
        uint256 amount
    ) external view returns (uint256 value) {
        (uint256 price,) = getPrice(asset);
        uint8 decimals_ = IERC20Metadata(asset).decimals();
        return Math.mulDiv(amount, price, 10 ** uint256(decimals_));
    }

    function _isStale(
        uint256 updatedAt,
        uint256 heartbeat
    ) internal view returns (bool) {
        return updatedAt == 0 || updatedAt + heartbeat < block.timestamp;
    }
}
