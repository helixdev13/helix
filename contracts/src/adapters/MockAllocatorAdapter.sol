// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IAllocatorAdapter } from "../interfaces/IAllocatorAdapter.sol";
import { AllocatorTypes } from "../libraries/AllocatorTypes.sol";
import { Errors } from "../libraries/Errors.sol";

contract MockAllocatorAdapter is IAllocatorAdapter, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint16 public constant BPS_DENOMINATOR = 10_000;

    IERC20 public immutable ASSET_TOKEN;

    address public _strategy;

    uint256 private _deployedPrincipal;
    uint256 private _withdrawableLiquidity;
    uint256 private _maxDepositCap = type(uint256).max;
    uint16 public valuationHaircutBps;
    AllocatorTypes.HealthState public override healthState = AllocatorTypes.HealthState.Healthy;

    constructor(
        IERC20 asset_
    ) {
        if (address(asset_) == address(0)) {
            revert Errors.ZeroAddress();
        }

        ASSET_TOKEN = asset_;
    }

    modifier onlyStrategy() {
        _onlyStrategy();
        _;
    }

    function asset() external view returns (address) {
        return address(ASSET_TOKEN);
    }

    function strategy() external view returns (address) {
        return _strategy;
    }

    function bindStrategy(
        address strategy_
    ) external {
        if (_strategy != address(0)) {
            revert Errors.StrategyAlreadyBound(_strategy);
        }
        if (strategy_ == address(0) || msg.sender != strategy_) {
            revert Errors.Unauthorized();
        }

        _strategy = strategy_;
    }

    function valuation() public view returns (AllocatorTypes.AdapterValuation memory value) {
        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));
        uint256 pendingRewards_ =
            grossAssets > _deployedPrincipal ? grossAssets - _deployedPrincipal : 0;
        uint256 haircutAmount = grossAssets * valuationHaircutBps / BPS_DENOMINATOR;

        value = AllocatorTypes.AdapterValuation({
            grossAssets: grossAssets,
            deployedAssets: _deployedPrincipal,
            withdrawableAssets: withdrawableAssets(),
            pendingRewards: pendingRewards_,
            haircutBps: valuationHaircutBps,
            haircutAmount: haircutAmount,
            netAssets: grossAssets - haircutAmount,
            timestamp: uint64(block.timestamp)
        });
    }

    function withdrawableAssets() public view returns (uint256) {
        if (healthState == AllocatorTypes.HealthState.Blocked) {
            return 0;
        }

        uint256 balance = ASSET_TOKEN.balanceOf(address(this));
        return balance < _withdrawableLiquidity ? balance : _withdrawableLiquidity;
    }

    function pendingRewards() public view returns (uint256) {
        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));
        return grossAssets > _deployedPrincipal ? grossAssets - _deployedPrincipal : 0;
    }

    function maxDeposit() public view returns (uint256) {
        if (healthState == AllocatorTypes.HealthState.Blocked) {
            return 0;
        }
        if (_maxDepositCap == type(uint256).max) {
            return type(uint256).max;
        }

        uint256 balance = ASSET_TOKEN.balanceOf(address(this));
        return balance >= _maxDepositCap ? 0 : _maxDepositCap - balance;
    }

    function deposit(
        uint256 assets
    ) external onlyStrategy nonReentrant returns (uint256 assetsDeposited) {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (healthState == AllocatorTypes.HealthState.Blocked) {
            revert Errors.AdapterNotHealthy(address(this), uint8(healthState));
        }
        if (assets > maxDeposit()) {
            revert Errors.AdapterCapacityExceeded(address(this), assets, maxDeposit());
        }

        ASSET_TOKEN.safeTransferFrom(msg.sender, address(this), assets);
        _deployedPrincipal += assets;
        _withdrawableLiquidity += assets;

        return assets;
    }

    function withdrawTo(
        address receiver,
        uint256 assets
    ) external onlyStrategy nonReentrant returns (uint256 assetsWithdrawn) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (healthState == AllocatorTypes.HealthState.Blocked) {
            revert Errors.AdapterNotHealthy(address(this), uint8(healthState));
        }

        uint256 available = withdrawableAssets();
        if (available < assets) {
            revert Errors.InsufficientLiquidAssets(available, assets);
        }

        ASSET_TOKEN.safeTransfer(receiver, assets);
        _deployedPrincipal = assets >= _deployedPrincipal ? 0 : _deployedPrincipal - assets;
        _withdrawableLiquidity = assets >= _withdrawableLiquidity ? 0 : _withdrawableLiquidity - assets;

        return assets;
    }

    function harvestTo(
        address receiver
    ) external onlyStrategy nonReentrant returns (uint256 assetsHarvested) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (healthState == AllocatorTypes.HealthState.Blocked) {
            revert Errors.AdapterNotHealthy(address(this), uint8(healthState));
        }

        uint256 grossAssets = ASSET_TOKEN.balanceOf(address(this));
        if (grossAssets <= _deployedPrincipal) {
            return 0;
        }

        assetsHarvested = grossAssets - _deployedPrincipal;
        ASSET_TOKEN.safeTransfer(receiver, assetsHarvested);
        _withdrawableLiquidity = ASSET_TOKEN.balanceOf(address(this)) < _withdrawableLiquidity
            ? ASSET_TOKEN.balanceOf(address(this))
            : _withdrawableLiquidity;
    }

    function unwindAllTo(
        address receiver
    ) external onlyStrategy nonReentrant returns (uint256 assetsReturned) {
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        assetsReturned = ASSET_TOKEN.balanceOf(address(this));
        if (assetsReturned == 0) {
            return 0;
        }

        ASSET_TOKEN.safeTransfer(receiver, assetsReturned);
        _deployedPrincipal = 0;
        _withdrawableLiquidity = 0;
    }

    function setHealthState(
        AllocatorTypes.HealthState newHealthState
    ) external onlyStrategy {
        healthState = newHealthState;
    }

    function setWithdrawableLiquidity(
        uint256 newWithdrawableLiquidity
    ) external onlyStrategy {
        _withdrawableLiquidity = newWithdrawableLiquidity;
    }

    function setMaxDepositCap(
        uint256 newMaxDepositCap
    ) external onlyStrategy {
        _maxDepositCap = newMaxDepositCap;
    }

    function setValuationHaircutBps(
        uint16 newValuationHaircutBps
    ) external onlyStrategy {
        if (newValuationHaircutBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(newValuationHaircutBps);
        }

        valuationHaircutBps = newValuationHaircutBps;
    }

    function _onlyStrategy() internal view {
        if (msg.sender != _strategy) {
            revert Errors.Unauthorized();
        }
    }
}
