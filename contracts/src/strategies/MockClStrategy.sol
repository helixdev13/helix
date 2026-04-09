// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IStrategy } from "../interfaces/IStrategy.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";

contract MockClStrategy is IStrategy {
    using SafeERC20 for IERC20;

    IERC20 public immutable ASSET_TOKEN;
    address public immutable VAULT;

    constructor(
        IERC20 asset_,
        address vault_
    ) {
        if (address(asset_) == address(0) || vault_ == address(0)) {
            revert Errors.ZeroAddress();
        }

        ASSET_TOKEN = asset_;
        VAULT = vault_;
    }

    modifier onlyVault() {
        _onlyVault();
        _;
    }

    function _onlyVault() internal view {
        if (msg.sender != VAULT) {
            revert Errors.Unauthorized();
        }
    }

    function asset() external view returns (address) {
        return address(ASSET_TOKEN);
    }

    function vault() external view returns (address) {
        return VAULT;
    }

    function deposit(
        uint256 assets
    ) external onlyVault {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }

        ASSET_TOKEN.safeTransferFrom(msg.sender, address(this), assets);
    }

    function withdraw(
        uint256 assets,
        address receiver
    ) external onlyVault {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }

        ASSET_TOKEN.safeTransfer(receiver, assets);
    }

    function totalAssets() public view returns (uint256) {
        return ASSET_TOKEN.balanceOf(address(this));
    }

    function harvest() external onlyVault {
        emit Events.StrategyHarvested(address(this), totalAssets());
    }

    function unwindAll() external onlyVault {
        uint256 assets_ = totalAssets();
        if (assets_ != 0) {
            ASSET_TOKEN.safeTransfer(VAULT, assets_);
        }
    }
}
