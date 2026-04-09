// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IRiskEngine } from "./interfaces/IRiskEngine.sol";
import { IStrategy } from "./interfaces/IStrategy.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";

contract HelixVault is ERC4626, Ownable2Step, ReentrancyGuard {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint16 public constant BPS_DENOMINATOR = 10_000;
    uint8 internal constant DECIMALS_OFFSET = 6;

    IRiskEngine public immutable RISK_ENGINE;

    IStrategy public strategy;
    address public guardian;

    bool public localEmergencyPaused;
    bool public localWithdrawOnly;

    constructor(
        IERC20 asset_,
        IRiskEngine riskEngine_,
        address initialOwner,
        address guardian_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC4626(asset_) Ownable(initialOwner) {
        if (address(asset_) == address(0) || address(riskEngine_) == address(0)) {
            revert Errors.ZeroAddress();
        }

        RISK_ENGINE = riskEngine_;
        guardian = guardian_;

        emit Events.GuardianUpdated(guardian_);
    }

    function paused() public view returns (bool) {
        return localEmergencyPaused || RISK_ENGINE.isPaused(address(this));
    }

    function withdrawOnly() public view returns (bool) {
        return paused() || localWithdrawOnly || RISK_ENGINE.isWithdrawOnly(address(this));
    }

    function totalAssets() public view override returns (uint256) {
        return totalIdle() + totalStrategyAssets();
    }

    function totalIdle() public view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function totalStrategyAssets() public view returns (uint256) {
        if (address(strategy) == address(0)) {
            return 0;
        }
        return strategy.totalAssets();
    }

    function maxDeposit(
        address
    ) public view override returns (uint256) {
        if (withdrawOnly()) {
            return 0;
        }

        uint256 depositCap = RISK_ENGINE.getDepositCap(address(this));
        if (depositCap == 0) {
            return 0;
        }

        uint256 assets_ = totalAssets();
        return assets_ >= depositCap ? 0 : depositCap - assets_;
    }

    function maxMint(
        address receiver
    ) public view override returns (uint256) {
        uint256 assets_ = maxDeposit(receiver);
        return assets_ == 0 ? 0 : previewDeposit(assets_);
    }

    function maxWithdraw(
        address owner_
    ) public view override returns (uint256) {
        uint256 ownerShares = balanceOf(owner_);
        if (ownerShares == 0) {
            return 0;
        }

        uint256 ownerAssets = previewRedeem(ownerShares);
        uint256 availableAssets = totalAssets();
        return ownerAssets > availableAssets ? availableAssets : ownerAssets;
    }

    // v0 assumes strategy liquidity is fully pullable on demand via the single mock adapter.
    // Real adapters with unwind delays, queues, or market frictions may require maxRedeem and
    // maxWithdraw to cap against realizable liquidity rather than raw share ownership.
    function maxRedeem(
        address owner_
    ) public view override returns (uint256) {
        return balanceOf(owner_);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override nonReentrant returns (uint256 shares) {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (withdrawOnly()) {
            revert Errors.DepositsDisabled();
        }

        uint256 depositCap = RISK_ENGINE.getDepositCap(address(this));
        if (depositCap == 0) {
            revert Errors.DepositsDisabled();
        }

        uint256 totalAssetsAfter = totalAssets() + assets;
        if (totalAssetsAfter > depositCap) {
            revert Errors.DepositCapExceeded(totalAssetsAfter, depositCap);
        }

        shares = previewDeposit(assets);
        if (shares == 0) {
            revert Errors.NoSharesMinted();
        }

        return super.deposit(assets, receiver);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override nonReentrant returns (uint256 assets_) {
        if (shares == 0) {
            revert Errors.ZeroAmount();
        }
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (withdrawOnly()) {
            revert Errors.DepositsDisabled();
        }

        assets_ = previewMint(shares);
        uint256 depositCap = RISK_ENGINE.getDepositCap(address(this));
        if (depositCap == 0) {
            revert Errors.DepositsDisabled();
        }

        uint256 totalAssetsAfter = totalAssets() + assets_;
        if (totalAssetsAfter > depositCap) {
            revert Errors.DepositCapExceeded(totalAssetsAfter, depositCap);
        }

        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner_
    ) public override nonReentrant returns (uint256 shares) {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (receiver == address(0) || owner_ == address(0)) {
            revert Errors.ZeroAddress();
        }

        return super.withdraw(assets, receiver, owner_);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner_
    ) public override nonReentrant returns (uint256 assets_) {
        if (shares == 0) {
            revert Errors.ZeroAmount();
        }
        if (receiver == address(0) || owner_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        uint256 maxShares = maxRedeem(owner_);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner_, shares, maxShares);
        }

        // Settle full-supply redemptions against live assets so the decimals offset does not
        // leave unrecoverable dust after the last share exits.
        assets_ = shares == totalSupply() ? totalAssets() : previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner_, assets_, shares);

        return assets_;
    }

    function setStrategy(
        IStrategy newStrategy
    ) external onlyOwner {
        if (address(newStrategy) == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (address(strategy) != address(0) && strategy.totalAssets() != 0) {
            revert Errors.StrategyNotEmpty(address(strategy), strategy.totalAssets());
        }
        if (newStrategy.totalAssets() != 0) {
            revert Errors.StrategyNotEmpty(address(newStrategy), newStrategy.totalAssets());
        }
        if (newStrategy.asset() != asset()) {
            revert Errors.StrategyAssetMismatch(asset(), newStrategy.asset());
        }
        if (newStrategy.vault() != address(this)) {
            revert Errors.StrategyVaultMismatch(address(this), newStrategy.vault());
        }

        address previousStrategy = address(strategy);
        strategy = newStrategy;
        emit Events.StrategyUpdated(previousStrategy, address(newStrategy));
    }

    function allocateToStrategy(
        uint256 assets
    ) external onlyOwner nonReentrant {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (withdrawOnly()) {
            revert Errors.AllocationDisabled();
        }
        if (address(strategy) == address(0)) {
            revert Errors.StrategyNotSet();
        }

        uint256 currentAllocation = strategy.totalAssets();
        uint256 maxAllowed =
            totalAssets().mulDiv(RISK_ENGINE.getMaxAllocationBps(address(this)), BPS_DENOMINATOR);
        uint256 requestedAllocation = currentAllocation + assets;
        if (requestedAllocation > maxAllowed) {
            revert Errors.AllocationCapExceeded(requestedAllocation, maxAllowed);
        }

        IERC20(asset()).forceApprove(address(strategy), 0);
        IERC20(asset()).forceApprove(address(strategy), assets);
        strategy.deposit(assets);
        IERC20(asset()).forceApprove(address(strategy), 0);

        emit Events.StrategyAllocated(address(strategy), assets);
    }

    function harvestStrategy() external onlyOwner nonReentrant {
        if (address(strategy) == address(0)) {
            revert Errors.StrategyNotSet();
        }

        strategy.harvest();
        emit Events.StrategyHarvested(address(strategy), strategy.totalAssets());
    }

    function emergencyPause() external nonReentrant {
        if (msg.sender != owner() && msg.sender != guardian) {
            revert Errors.GuardianOnlyOrOwner();
        }

        localEmergencyPaused = true;
        localWithdrawOnly = true;

        emit Events.PauseUpdated(msg.sender, true);
        emit Events.LocalWithdrawOnlySet(msg.sender, true);

        if (address(strategy) != address(0)) {
            uint256 idleBefore = IERC20(asset()).balanceOf(address(this));
            strategy.unwindAll();
            uint256 assetsReturned = IERC20(asset()).balanceOf(address(this)) - idleBefore;
            emit Events.StrategyUnwound(address(strategy), assetsReturned);
        }
    }

    function clearEmergencyPause() external onlyOwner {
        localEmergencyPaused = false;
        emit Events.PauseUpdated(msg.sender, false);
    }

    function setWithdrawOnly(
        bool enabled
    ) external {
        if (msg.sender != owner() && msg.sender != guardian) {
            revert Errors.GuardianOnlyOrOwner();
        }
        if (!enabled && msg.sender != owner()) {
            revert Errors.OnlyOwnerCanDisable();
        }

        localWithdrawOnly = enabled;
        emit Events.LocalWithdrawOnlySet(msg.sender, enabled);
    }

    function setGuardian(
        address newGuardian
    ) external onlyOwner {
        guardian = newGuardian;
        emit Events.GuardianUpdated(newGuardian);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner_,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner_) {
            _spendAllowance(owner_, caller, shares);
        }

        _burn(owner_, shares);
        _ensureLiquidity(assets);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner_, assets, shares);
    }

    function _ensureLiquidity(
        uint256 assets
    ) internal {
        uint256 idleAssets = IERC20(asset()).balanceOf(address(this));
        if (idleAssets >= assets) {
            return;
        }
        if (address(strategy) == address(0)) {
            revert Errors.InsufficientLiquidAssets(idleAssets, assets);
        }

        strategy.withdraw(assets - idleAssets, address(this));

        uint256 updatedIdleAssets = IERC20(asset()).balanceOf(address(this));
        if (updatedIdleAssets < assets) {
            revert Errors.InsufficientLiquidAssets(updatedIdleAssets, assets);
        }
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return DECIMALS_OFFSET;
    }
}
