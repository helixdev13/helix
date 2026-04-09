// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { RiskEngine } from "../src/core/RiskEngine.sol";
import { Errors } from "../src/libraries/Errors.sol";
import { Types } from "../src/libraries/Types.sol";

contract RiskEngineTest is Test {
    address internal constant VAULT = address(0xCAFE);
    address internal constant OTHER = address(0xB0B);

    RiskEngine internal riskEngine;

    function setUp() public {
        riskEngine = new RiskEngine(address(this));
    }

    function testSetAndReadConfig() public {
        riskEngine.setConfig(VAULT, 500e18, 7500, true, false);

        Types.RiskConfig memory config = riskEngine.getConfig(VAULT);
        assertEq(config.depositCap, 500e18);
        assertEq(config.maxAllocationBps, 7500);
        assertTrue(config.paused);
        assertFalse(config.withdrawOnly);
    }

    function testOwnerCanUpdateFieldsIndividually() public {
        riskEngine.setConfig(VAULT, 500e18, 6000, false, false);

        riskEngine.setDepositCap(VAULT, 700e18);
        riskEngine.setPause(VAULT, true);
        riskEngine.setWithdrawOnly(VAULT, true);
        riskEngine.setMaxAllocationBps(VAULT, 3500);

        assertEq(riskEngine.getDepositCap(VAULT), 700e18);
        assertEq(riskEngine.getMaxAllocationBps(VAULT), 3500);
        assertTrue(riskEngine.isPaused(VAULT));
        assertTrue(riskEngine.isWithdrawOnly(VAULT));
    }

    function testNonOwnerCannotMutate() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, OTHER));
        vm.prank(OTHER);
        riskEngine.setConfig(VAULT, 1, 1, false, false);
    }

    function testRejectsInvalidBps() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBps.selector, 10_001));
        riskEngine.setConfig(VAULT, 100e18, 10_001, false, false);
    }
}
