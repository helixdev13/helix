// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { RewardDistributor } from "../src/periphery/RewardDistributor.sol";
import { HLXToken, MINTER_ROLE } from "../src/token/HLXToken.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract RewardDistributorTest is Test {
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant OTHER = address(0xBAD);

    MockERC20 internal stakingToken;
    HLXToken internal rewardToken;
    RewardDistributor internal distributor;

    function setUp() public {
        stakingToken = new MockERC20("Vault Share", "vHLX", 18);
        rewardToken = new HLXToken(address(this));

        distributor = new RewardDistributor(
            address(stakingToken), address(rewardToken), address(this)
        );

        stakingToken.mint(ALICE, 1000e18);
        stakingToken.mint(BOB, 1000e18);

        vm.prank(ALICE);
        stakingToken.approve(address(distributor), type(uint256).max);
        vm.prank(BOB);
        stakingToken.approve(address(distributor), type(uint256).max);

        rewardToken.grantRole(MINTER_ROLE, address(this));
    }

    function testStakeAndBalance() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        assertEq(distributor.balanceOf(ALICE), 100e18);
        assertEq(distributor.totalSupply(), 100e18);
        assertEq(stakingToken.balanceOf(address(distributor)), 100e18);
    }

    function testWithdraw() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        vm.prank(ALICE);
        distributor.withdraw(50e18);

        assertEq(distributor.balanceOf(ALICE), 50e18);
        assertEq(distributor.totalSupply(), 50e18);
        assertEq(stakingToken.balanceOf(ALICE), 950e18);
    }

    function testEarnedAccumulatesOverTime() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        rewardToken.mint(address(this), 1000e18);
        rewardToken.approve(address(distributor), 1000e18);
        distributor.notifyRewardAmount(700e18);

        vm.warp(block.timestamp + 7 days / 2);

        uint256 earned = distributor.earned(ALICE);
        assertGt(earned, 0);
        assertLe(earned, 350e18 + 1);
    }

    function testClaimRewards() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        rewardToken.mint(address(this), 1000e18);
        rewardToken.approve(address(distributor), 1000e18);
        distributor.notifyRewardAmount(700e18);

        vm.warp(block.timestamp + 7 days);

        vm.prank(ALICE);
        distributor.claimRewards();

        assertGt(rewardToken.balanceOf(ALICE), 699e18);
        assertEq(distributor.earned(ALICE), 0);
    }

    function testMultiUserProportionalDistribution() public {
        vm.prank(ALICE);
        distributor.stake(100e18);
        vm.prank(BOB);
        distributor.stake(300e18);

        rewardToken.mint(address(this), 1000e18);
        rewardToken.approve(address(distributor), 1000e18);
        distributor.notifyRewardAmount(700e18);

        vm.warp(block.timestamp + 7 days);

        uint256 aliceEarned = distributor.earned(ALICE);
        uint256 bobEarned = distributor.earned(BOB);

        assertGt(aliceEarned, 0);
        assertGt(bobEarned, aliceEarned);

        uint256 ratio = bobEarned * 100 / aliceEarned;
        assertEq(ratio, 300);
    }

    function testExitWithdrawsAndClaims() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        rewardToken.mint(address(this), 1000e18);
        rewardToken.approve(address(distributor), 1000e18);
        distributor.notifyRewardAmount(700e18);

        vm.warp(block.timestamp + 7 days);

        vm.prank(ALICE);
        distributor.exit();

        assertEq(distributor.balanceOf(ALICE), 0);
        assertGt(rewardToken.balanceOf(ALICE), 699e18);
        assertEq(stakingToken.balanceOf(ALICE), 1000e18);
    }

    function testRewardPeriodExpires() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        rewardToken.mint(address(this), 1000e18);
        rewardToken.approve(address(distributor), 1000e18);
        distributor.notifyRewardAmount(700e18);

        vm.warp(block.timestamp + 14 days);

        uint256 earned = distributor.earned(ALICE);
        assertGe(earned, 699e18);
    }

    function testNotifyRewardAmountExtendsPeriod() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        rewardToken.mint(address(this), 2000e18);
        rewardToken.approve(address(distributor), 2000e18);
        distributor.notifyRewardAmount(700e18);

        vm.warp(block.timestamp + 3 days);

        distributor.notifyRewardAmount(700e18);

        vm.warp(block.timestamp + 7 days);

        uint256 earned = distributor.earned(ALICE);
        assertGt(earned, 700e18);
    }

    function testStakeRevertsOnZero() public {
        vm.expectRevert(Errors.ZeroAmount.selector);
        vm.prank(ALICE);
        distributor.stake(0);
    }

    function testWithdrawRevertsOnZero() public {
        vm.prank(ALICE);
        distributor.stake(100e18);

        vm.expectRevert(Errors.ZeroAmount.selector);
        vm.prank(ALICE);
        distributor.withdraw(0);
    }

    function testNotifyRewardAmountOnlyOwner() public {
        rewardToken.mint(address(this), 100e18);
        rewardToken.approve(address(distributor), 100e18);

        vm.expectRevert();
        vm.prank(OTHER);
        distributor.notifyRewardAmount(100e18);
    }

    function testSetRewardsDurationOnlyAfterPeriodFinish() public {
        rewardToken.mint(address(this), 1000e18);
        rewardToken.approve(address(distributor), 1000e18);
        distributor.notifyRewardAmount(700e18);

        vm.expectRevert(abi.encodeWithSelector(Errors.DeadlineExpired.selector, block.timestamp, distributor.periodFinish()));
        distributor.setRewardsDuration(14 days);

        vm.warp(block.timestamp + 8 days);
        distributor.setRewardsDuration(14 days);
        assertEq(distributor.rewardsDuration(), 14 days);
    }
}
