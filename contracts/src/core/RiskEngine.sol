// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { IRiskEngine } from "../interfaces/IRiskEngine.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { Types } from "../libraries/Types.sol";

contract RiskEngine is Ownable2Step, IRiskEngine {
    uint16 public constant BPS_DENOMINATOR = 10_000;

    mapping(address vault => Types.RiskConfig config) private _configs;

    constructor(
        address initialOwner
    ) Ownable(initialOwner) { }

    function setConfig(
        address vault,
        uint256 depositCap,
        uint16 maxAllocationBps,
        bool paused,
        bool withdrawOnly
    ) external onlyOwner {
        _setConfig(
            vault,
            Types.RiskConfig({
                depositCap: depositCap,
                maxAllocationBps: maxAllocationBps,
                paused: paused,
                withdrawOnly: withdrawOnly
            })
        );
    }

    function setDepositCap(
        address vault,
        uint256 depositCap
    ) external onlyOwner {
        Types.RiskConfig memory config = _configs[vault];
        config.depositCap = depositCap;
        _setConfig(vault, config);
    }

    function setPause(
        address vault,
        bool paused
    ) external onlyOwner {
        Types.RiskConfig memory config = _configs[vault];
        config.paused = paused;
        _setConfig(vault, config);
    }

    function setWithdrawOnly(
        address vault,
        bool withdrawOnly
    ) external onlyOwner {
        Types.RiskConfig memory config = _configs[vault];
        config.withdrawOnly = withdrawOnly;
        _setConfig(vault, config);
    }

    function setMaxAllocationBps(
        address vault,
        uint16 maxAllocationBps
    ) external onlyOwner {
        Types.RiskConfig memory config = _configs[vault];
        config.maxAllocationBps = maxAllocationBps;
        _setConfig(vault, config);
    }

    function getConfig(
        address vault
    ) external view returns (Types.RiskConfig memory) {
        return _configs[vault];
    }

    function getDepositCap(
        address vault
    ) external view returns (uint256) {
        return _configs[vault].depositCap;
    }

    function getMaxAllocationBps(
        address vault
    ) external view returns (uint16) {
        return _configs[vault].maxAllocationBps;
    }

    function isPaused(
        address vault
    ) external view returns (bool) {
        return _configs[vault].paused;
    }

    function isWithdrawOnly(
        address vault
    ) external view returns (bool) {
        return _configs[vault].withdrawOnly;
    }

    function _setConfig(
        address vault,
        Types.RiskConfig memory config
    ) internal {
        Types.RiskConfig memory previous = _configs[vault];

        if (vault == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (config.maxAllocationBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(config.maxAllocationBps);
        }

        _configs[vault] = config;

        if (previous.depositCap != config.depositCap) {
            emit Events.DepositCapUpdated(vault, previous.depositCap, config.depositCap);
        }
        if (previous.maxAllocationBps != config.maxAllocationBps) {
            emit Events.MaxAllocationUpdated(
                vault, previous.maxAllocationBps, config.maxAllocationBps
            );
        }
        if (previous.paused != config.paused) {
            emit Events.RiskPauseUpdated(vault, config.paused);
        }
        if (previous.withdrawOnly != config.withdrawOnly) {
            emit Events.RiskWithdrawOnlyUpdated(vault, config.withdrawOnly);
        }

        emit Events.RiskConfigSet(
            vault, config.depositCap, config.maxAllocationBps, config.paused, config.withdrawOnly
        );
    }
}
