// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";

contract HLXTokenTest is Test {
    HLXToken internal hlx;
    address internal constant OWNER = address(0xCAFE);
    address internal constant MINTER = address(0xB0B);
    address internal constant OTHER = address(0xBAD);

    function setUp() public {
        hlx = new HLXToken(OWNER);
    }

    function testMintSucceedsForMinter() public {
        vm.prank(OWNER);
        hlx.grantRole(MINTER_ROLE, MINTER);

        vm.prank(MINTER);
        hlx.mint(address(this), 100e18);
        assertEq(hlx.balanceOf(address(this)), 100e18);
    }

    function testMintRevertsForNonMinter() public {
        vm.prank(OTHER);
        vm.expectRevert();
        hlx.mint(address(this), 100e18);
    }

    function testOwnerIsDefaultAdminAndMinter() public view {
        assertTrue(hlx.hasRole(hlx.DEFAULT_ADMIN_ROLE(), OWNER));
        assertTrue(hlx.hasRole(MINTER_ROLE, OWNER));
    }

    function testNoMaxSupply() public {
        vm.startPrank(OWNER);
        hlx.mint(address(this), 1_000_000_000e18);
        assertEq(hlx.totalSupply(), 1_000_000_000e18);
        hlx.mint(address(this), 1_000_000_000e18);
        assertEq(hlx.totalSupply(), 2_000_000_000e18);
        vm.stopPrank();
    }

    function testTransferAndApprove() public {
        vm.prank(OWNER);
        hlx.mint(address(this), 100e18);

        hlx.transfer(OTHER, 50e18);
        assertEq(hlx.balanceOf(address(this)), 50e18);
        assertEq(hlx.balanceOf(OTHER), 50e18);

        hlx.approve(OTHER, 30e18);
        assertEq(hlx.allowance(address(this), OTHER), 30e18);
    }
}
