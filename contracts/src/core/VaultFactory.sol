// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { HelixVault } from "../HelixVault.sol";
import { IRiskEngine } from "../interfaces/IRiskEngine.sol";
import { Errors } from "../libraries/Errors.sol";

contract VaultFactory is Ownable2Step {
    IRiskEngine public immutable RISK_ENGINE;

    address[] private _vaults;
    mapping(address vault => bool created) public isVaultFromFactory;

    event VaultCreated(
        address indexed vault,
        address indexed asset,
        address indexed initialOwner,
        address guardian,
        uint256 vaultIndex,
        string name,
        string symbol
    );

    constructor(
        IRiskEngine riskEngine_,
        address initialOwner
    ) Ownable(initialOwner) {
        if (address(riskEngine_) == address(0)) {
            revert Errors.ZeroAddress();
        }

        RISK_ENGINE = riskEngine_;
    }

    function createVault(
        IERC20 asset_,
        address initialOwner_,
        address guardian_,
        string calldata name_,
        string calldata symbol_
    ) external onlyOwner returns (HelixVault vault) {
        if (address(asset_) == address(0) || initialOwner_ == address(0)) {
            revert Errors.ZeroAddress();
        }

        vault = new HelixVault(asset_, RISK_ENGINE, initialOwner_, guardian_, name_, symbol_);

        _vaults.push(address(vault));
        isVaultFromFactory[address(vault)] = true;

        emit VaultCreated(
            address(vault),
            address(asset_),
            initialOwner_,
            guardian_,
            _vaults.length - 1,
            name_,
            symbol_
        );
    }

    function totalVaults() external view returns (uint256) {
        return _vaults.length;
    }

    function vaultAt(
        uint256 index
    ) external view returns (address) {
        return _vaults[index];
    }

    function allVaults() external view returns (address[] memory) {
        return _vaults;
    }
}
