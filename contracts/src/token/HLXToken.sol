// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

contract HLXToken is ERC20, AccessControl {
    constructor(
        address initialOwner
    ) ERC20("Helix Reward Token", "HLX") {
        if (initialOwner == address(0)) {
            revert();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
