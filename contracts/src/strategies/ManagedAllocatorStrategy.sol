// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IAllocatorAdapter } from "../interfaces/IAllocatorAdapter.sol";
import { IOracleRouter } from "../interfaces/IOracleRouter.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { AllocatorTypes } from "../libraries/AllocatorTypes.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";

contract ManagedAllocatorStrategy is Ownable2Step, ReentrancyGuard, IStrategy {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint16 public constant BPS_DENOMINATOR = 10_000;

    IERC20 public immutable ASSET_TOKEN;
    address public immutable VAULT;
    IOracleRouter internal immutable ORACLE_ROUTER;

    address public strategist;
    address public guardian;
    bool public rebalancePaused = true;

    uint16 public idleFloorBps;
    uint16 public globalAllocationCapBps;

    address[] private _adapters;
    mapping(address adapter => AllocatorTypes.AdapterConfig config) private _adapterConfigs;

    constructor(
        IERC20 asset_,
        address vault_,
        IOracleRouter oracleRouter_,
        address initialOwner,
        address strategist_,
        address guardian_
    ) Ownable(initialOwner) {
        if (
            address(asset_) == address(0) || vault_ == address(0) || address(oracleRouter_) == address(0)
        ) {
            revert Errors.ZeroAddress();
        }

        ASSET_TOKEN = asset_;
        VAULT = vault_;
        ORACLE_ROUTER = oracleRouter_;
        strategist = strategist_;
        guardian = guardian_;
        globalAllocationCapBps = BPS_DENOMINATOR;

        emit Events.StrategyStrategistUpdated(strategist_);
        emit Events.StrategyGuardianUpdated(guardian_);
    }

    modifier onlyVault() {
        _onlyVault();
        _;
    }

    modifier onlyOwnerOrStrategist() {
        _onlyOwnerOrStrategist();
        _;
    }

    function asset() external view returns (address) {
        return address(ASSET_TOKEN);
    }

    function vault() external view returns (address) {
        return VAULT;
    }

    function oracleRouter() external view returns (address) {
        return address(ORACLE_ROUTER);
    }

    function adapterCount() external view returns (uint256) {
        return _adapters.length;
    }

    function adapterAt(
        uint256 index
    ) external view returns (address) {
        return _adapters[index];
    }

    function totalIdle() public view returns (uint256) {
        return ASSET_TOKEN.balanceOf(address(this));
    }

    function totalDeployedAssets() public view returns (uint256 total) {
        for (uint256 i = 0; i < _adapters.length; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }
            total += IAllocatorAdapter(adapter).valuation().grossAssets;
        }
    }

    function totalWithdrawableAssets() public view returns (uint256 total) {
        for (uint256 i = 0; i < _adapters.length; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }
            if (IAllocatorAdapter(adapter).healthState() == AllocatorTypes.HealthState.Blocked) {
                continue;
            }

            total += IAllocatorAdapter(adapter).withdrawableAssets();
        }
    }

    function totalPendingRewards() public view returns (uint256 total) {
        for (uint256 i = 0; i < _adapters.length; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }
            total += IAllocatorAdapter(adapter).pendingRewards();
        }
    }

    function totalConservativeAssets() public view returns (uint256) {
        uint256 total = totalIdle();
        for (uint256 i = 0; i < _adapters.length; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }
            total += IAllocatorAdapter(adapter).valuation().netAssets;
        }
        return total;
    }

    function totalAssets() public view returns (uint256) {
        return totalIdle() + totalDeployedAssets();
    }

    function healthState() public view returns (AllocatorTypes.HealthState) {
        bool hasDegraded;
        for (uint256 i = 0; i < _adapters.length; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }

            AllocatorTypes.HealthState health = IAllocatorAdapter(adapter).healthState();
            if (health == AllocatorTypes.HealthState.Blocked) {
                return AllocatorTypes.HealthState.Blocked;
            }
            if (health == AllocatorTypes.HealthState.Degraded) {
                hasDegraded = true;
            }
        }

        if (hasDegraded) {
            return AllocatorTypes.HealthState.Degraded;
        }

        return AllocatorTypes.HealthState.Healthy;
    }

    function adapterState(
        address adapter
    ) external view returns (AllocatorTypes.AdapterState memory state) {
        AllocatorTypes.AdapterConfig memory config = _adapterConfigs[adapter];
        if (!config.approved) {
            return state;
        }

        state.adapter = adapter;
        state.config = config;
        state.healthState = IAllocatorAdapter(adapter).healthState();
        state.valuation = IAllocatorAdapter(adapter).valuation();
    }

    function allocatorState() external view returns (AllocatorTypes.AllocatorState memory state) {
        state.totalIdleAssets = totalIdle();
        state.totalDeployedAssets = totalDeployedAssets();
        state.totalWithdrawableAssets = totalWithdrawableAssets();
        state.totalPendingRewards = totalPendingRewards();
        state.totalLiveAssets = state.totalIdleAssets + state.totalDeployedAssets;
        state.totalConservativeAssets = totalConservativeAssets();
        state.healthState = healthState();
        state.allocationPaused = rebalancePaused;
        state.idleFloorBps = idleFloorBps;
        state.globalAllocationCapBps = globalAllocationCapBps;
        state.adapterCount = _adapters.length;

        uint256 activeAdapters;
        for (uint256 i = 0; i < _adapters.length; ++i) {
            AllocatorTypes.AdapterConfig memory config = _adapterConfigs[_adapters[i]];
            if (config.approved && config.enabled) {
                activeAdapters += 1;
            }
        }
        state.activeAdapterCount = activeAdapters;
    }

    function deposit(
        uint256 assets
    ) external onlyVault nonReentrant {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }

        ASSET_TOKEN.safeTransferFrom(msg.sender, address(this), assets);
    }

    function withdraw(
        uint256 assets,
        address receiver
    ) external onlyVault nonReentrant {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        _ensureLiquidity(assets);
        ASSET_TOKEN.safeTransfer(receiver, assets);
    }

    function harvest() external onlyVault nonReentrant {
        _harvestAll();
    }

    function unwindAll() external onlyVault nonReentrant {
        _unwindAll();

        uint256 idleAssets = totalIdle();
        if (idleAssets != 0) {
            ASSET_TOKEN.safeTransfer(VAULT, idleAssets);
        }
    }

    function addAdapter(
        address adapter,
        uint16 maxAllocationBps
    ) external onlyOwner {
        if (adapter == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (_adapterConfigs[adapter].approved) {
            revert Errors.AdapterAlreadyAdded(adapter);
        }
        if (maxAllocationBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(maxAllocationBps);
        }

        IAllocatorAdapter allocatorAdapter = IAllocatorAdapter(adapter);
        if (allocatorAdapter.asset() != address(ASSET_TOKEN)) {
            revert Errors.StrategyAssetMismatch(address(ASSET_TOKEN), allocatorAdapter.asset());
        }
        if (allocatorAdapter.strategy() != address(0) && allocatorAdapter.strategy() != address(this)) {
            revert Errors.StrategyAlreadyBound(allocatorAdapter.strategy());
        }
        if (allocatorAdapter.strategy() == address(0)) {
            allocatorAdapter.bindStrategy(address(this));
        }

        _adapterConfigs[adapter] = AllocatorTypes.AdapterConfig({
            approved: true,
            enabled: true,
            maxAllocationBps: maxAllocationBps
        });
        _adapters.push(adapter);

        emit Events.AllocatorAdapterConfigured(adapter, true, maxAllocationBps);
    }

    function setAdapterEnabled(
        address adapter,
        bool enabled
    ) external onlyOwner {
        AllocatorTypes.AdapterConfig storage config = _adapterConfigs[adapter];
        if (!config.approved) {
            revert Errors.AdapterNotApproved(adapter);
        }

        config.enabled = enabled;
        emit Events.AllocatorAdapterConfigured(adapter, enabled, config.maxAllocationBps);
    }

    function setAdapterMaxAllocationBps(
        address adapter,
        uint16 maxAllocationBps
    ) external onlyOwner {
        AllocatorTypes.AdapterConfig storage config = _adapterConfigs[adapter];
        if (!config.approved) {
            revert Errors.AdapterNotApproved(adapter);
        }
        if (maxAllocationBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(maxAllocationBps);
        }

        config.maxAllocationBps = maxAllocationBps;
        emit Events.AllocatorAdapterConfigured(adapter, config.enabled, maxAllocationBps);
    }

    function setStrategist(
        address newStrategist
    ) external onlyOwner {
        strategist = newStrategist;
        emit Events.StrategyStrategistUpdated(newStrategist);
    }

    function setGuardian(
        address newGuardian
    ) external onlyOwner {
        guardian = newGuardian;
        emit Events.StrategyGuardianUpdated(newGuardian);
    }

    function setAllocationPaused(
        bool enabled
    ) external {
        if (!enabled && msg.sender != owner()) {
            revert Errors.OnlyOwnerCanDisableRebalancePause();
        }
        if (enabled && msg.sender != owner() && msg.sender != guardian) {
            revert Errors.GuardianOnlyOrOwner();
        }

        rebalancePaused = enabled;
        emit Events.AllocatorPauseUpdated(msg.sender, enabled);
    }

    function setIdleFloorBps(
        uint16 newBps
    ) external onlyOwner {
        if (newBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(newBps);
        }

        uint16 previous = idleFloorBps;
        idleFloorBps = newBps;
        emit Events.AllocatorIdleFloorUpdated(msg.sender, previous, newBps);
    }

    function setGlobalAllocationCapBps(
        uint16 newBps
    ) external onlyOwner {
        if (newBps > BPS_DENOMINATOR) {
            revert Errors.InvalidBps(newBps);
        }

        uint16 previous = globalAllocationCapBps;
        globalAllocationCapBps = newBps;
        emit Events.AllocatorGlobalAllocationCapUpdated(msg.sender, previous, newBps);
    }

    function allocateToAdapter(
        address adapter,
        uint256 assets
    ) external onlyOwnerOrStrategist nonReentrant {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (rebalancePaused) {
            revert Errors.RebalancePaused();
        }

        IAllocatorAdapter allocatorAdapter = _validateAllocationRequest(adapter, assets);
        _performAllocation(adapter, assets, allocatorAdapter);

        emit Events.AllocatorAllocated(address(this), adapter, assets);
    }

    function deallocateFromAdapter(
        address adapter,
        uint256 assets
    ) external onlyOwnerOrStrategist nonReentrant {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }

        AllocatorTypes.AdapterConfig memory config = _adapterConfigs[adapter];
        if (!config.approved) {
            revert Errors.AdapterNotApproved(adapter);
        }

        IAllocatorAdapter allocatorAdapter = IAllocatorAdapter(adapter);
        AllocatorTypes.HealthState health = allocatorAdapter.healthState();
        if (health == AllocatorTypes.HealthState.Blocked) {
            revert Errors.AdapterNotHealthy(adapter, uint8(health));
        }

        uint256 beforeIdle = totalIdle();
        uint256 received = allocatorAdapter.withdrawTo(address(this), assets);
        uint256 afterIdle = totalIdle();
        uint256 actualReceived = afterIdle >= beforeIdle ? afterIdle - beforeIdle : 0;

        if (received != assets || actualReceived != assets) {
            revert Errors.InsufficientLiquidAssets(actualReceived, assets);
        }

        emit Events.AllocatorDeallocated(address(this), adapter, assets);
    }

    function _ensureLiquidity(
        uint256 assets
    ) internal {
        uint256 idleAssets = totalIdle();
        if (idleAssets >= assets) {
            return;
        }

        uint256 remaining = assets - idleAssets;
        remaining = _pullLiquidityForHealth(remaining, AllocatorTypes.HealthState.Healthy);
        if (remaining != 0) {
            remaining = _pullLiquidityForHealth(remaining, AllocatorTypes.HealthState.Degraded);
        }

        uint256 updatedIdleAssets = totalIdle();
        if (updatedIdleAssets < assets || remaining != 0) {
            revert Errors.InsufficientLiquidAssets(updatedIdleAssets, assets);
        }
    }

    function _harvestAll() internal {
        _harvestByHealth(AllocatorTypes.HealthState.Healthy);
        _harvestByHealth(AllocatorTypes.HealthState.Degraded);
        _harvestByHealth(AllocatorTypes.HealthState.Blocked);
    }

    function _unwindAll() internal {
        _unwindByHealth(AllocatorTypes.HealthState.Healthy);
        _unwindByHealth(AllocatorTypes.HealthState.Degraded);
        _unwindByHealth(AllocatorTypes.HealthState.Blocked);
    }

    function _validateAllocationRequest(
        address adapter,
        uint256 assets
    ) internal view returns (IAllocatorAdapter allocatorAdapter) {
        AllocatorTypes.AdapterConfig memory config = _adapterConfigs[adapter];
        if (!config.approved) {
            revert Errors.AdapterNotApproved(adapter);
        }
        if (!config.enabled) {
            revert Errors.AdapterDisabled(adapter);
        }

        allocatorAdapter = IAllocatorAdapter(adapter);
        ORACLE_ROUTER.getPrice(address(ASSET_TOKEN));
        AllocatorTypes.HealthState health = allocatorAdapter.healthState();
        if (health != AllocatorTypes.HealthState.Healthy) {
            revert Errors.AdapterNotHealthy(adapter, uint8(health));
        }

        uint256 idleAssets = totalIdle();
        if (assets > idleAssets) {
            revert Errors.InsufficientLiquidAssets(idleAssets, assets);
        }

        uint256 totalAssetsBefore = totalAssets();
        uint256 idleAfter = idleAssets - assets;
        uint256 minimumIdleRequired = totalAssetsBefore.mulDiv(idleFloorBps, BPS_DENOMINATOR);
        if (idleAfter < minimumIdleRequired) {
            revert Errors.IdleFloorViolation(idleAfter, minimumIdleRequired);
        }

        uint256 requestedDeployed = totalDeployedAssets() + assets;
        uint256 globalMaxAllowed = totalAssetsBefore.mulDiv(globalAllocationCapBps, BPS_DENOMINATOR);
        if (requestedDeployed > globalMaxAllowed) {
            revert Errors.AllocationCapExceeded(requestedDeployed, globalMaxAllowed);
        }

        uint256 adapterCurrent = allocatorAdapter.valuation().grossAssets;
        uint256 adapterRequested = adapterCurrent + assets;
        uint256 adapterMaxAllowed = totalAssetsBefore.mulDiv(config.maxAllocationBps, BPS_DENOMINATOR);
        if (adapterRequested > adapterMaxAllowed) {
            revert Errors.AllocationCapExceeded(adapterRequested, adapterMaxAllowed);
        }

        uint256 maxDeposit = allocatorAdapter.maxDeposit();
        if (assets > maxDeposit) {
            revert Errors.AdapterCapacityExceeded(adapter, assets, maxDeposit);
        }
    }

    function _performAllocation(
        address adapter,
        uint256 assets,
        IAllocatorAdapter allocatorAdapter
    ) internal {
        uint256 beforeGross = allocatorAdapter.valuation().grossAssets;
        ASSET_TOKEN.forceApprove(adapter, 0);
        ASSET_TOKEN.forceApprove(adapter, assets);
        uint256 spent = allocatorAdapter.deposit(assets);
        ASSET_TOKEN.forceApprove(adapter, 0);

        uint256 afterGross = allocatorAdapter.valuation().grossAssets;
        uint256 reportedAssets = afterGross >= beforeGross ? afterGross - beforeGross : 0;
        if (spent != assets || reportedAssets != assets) {
            revert Errors.AdapterDepositMismatch(adapter, assets, spent, reportedAssets);
        }
    }

    function _pullLiquidityForHealth(
        uint256 remaining,
        AllocatorTypes.HealthState desiredHealth
    ) internal returns (uint256) {
        for (uint256 i = 0; i < _adapters.length && remaining != 0; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }
            if (IAllocatorAdapter(adapter).healthState() != desiredHealth) {
                continue;
            }

            uint256 withdrawable = IAllocatorAdapter(adapter).withdrawableAssets();
            if (withdrawable == 0) {
                continue;
            }

            uint256 request = remaining < withdrawable ? remaining : withdrawable;
            try IAllocatorAdapter(adapter).withdrawTo(address(this), request) returns (
                uint256 received
            ) {
                if (received != 0) {
                    emit Events.AllocatorAdapterWithdrawal(
                        address(this), adapter, request, received
                    );
                }
                if (received >= remaining) {
                    return 0;
                }
                remaining -= received;
            } catch (bytes memory reason) {
                emit Events.AllocatorAdapterOperationFailed(
                    address(this), adapter, 1, request, reason
                );
            }
        }

        return remaining;
    }

    function _harvestByHealth(
        AllocatorTypes.HealthState desiredHealth
    ) internal {
        for (uint256 i = 0; i < _adapters.length; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }
            if (IAllocatorAdapter(adapter).healthState() != desiredHealth) {
                continue;
            }

            try IAllocatorAdapter(adapter).harvestTo(address(this)) returns (
                uint256 harvested
            ) {
                if (harvested != 0) {
                    emit Events.AllocatorAdapterHarvest(
                        address(this), adapter, harvested
                    );
                }
            } catch (bytes memory reason) {
                emit Events.AllocatorAdapterOperationFailed(
                    address(this), adapter, 2, 0, reason
                );
            }
        }
    }

    function _unwindByHealth(
        AllocatorTypes.HealthState desiredHealth
    ) internal {
        for (uint256 i = 0; i < _adapters.length; ++i) {
            address adapter = _adapters[i];
            if (!_isApproved(adapter)) {
                continue;
            }
            if (IAllocatorAdapter(adapter).healthState() != desiredHealth) {
                continue;
            }

            try IAllocatorAdapter(adapter).unwindAllTo(address(this)) returns (
                uint256 returnedAssets
            ) {
                if (returnedAssets != 0) {
                    emit Events.AllocatorAdapterUnwind(
                        address(this), adapter, returnedAssets
                    );
                }
            } catch (bytes memory reason) {
                emit Events.AllocatorAdapterOperationFailed(
                    address(this), adapter, 3, 0, reason
                );
            }
        }
    }

    function _isApproved(
        address adapter
    ) internal view returns (bool) {
        return _adapterConfigs[adapter].approved;
    }

    function _onlyVault() internal view {
        if (msg.sender != VAULT) {
            revert Errors.Unauthorized();
        }
    }

    function _onlyOwnerOrStrategist() internal view {
        if (msg.sender != owner() && msg.sender != strategist) {
            revert Errors.OnlyOwnerOrStrategist();
        }
    }
}
