// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

/// @notice Helix reward token with owner-controlled minting.
/// @dev The deployer receives both the default admin and minter roles.
contract HLXToken is ERC20, AccessControl {
    /// @notice Deploy the HLX token and grant the initial owner admin and minter access.
    /// @param initialOwner Account that receives the initial admin and minter roles.
    constructor(
        address initialOwner
    ) ERC20("Helix Reward Token", "HLX") {
        if (initialOwner == address(0)) {
            revert();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
    }

    /// @notice Mint HLX to `to`.
    /// @param to Recipient of the mint.
    /// @param amount Amount to mint.
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
