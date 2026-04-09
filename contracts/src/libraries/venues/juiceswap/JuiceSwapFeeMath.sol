// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library JuiceSwapFeeMath {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    struct TickFeeData {
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
    }

    function getFeeGrowthInside(
        int24 currentTick,
        int24 tickLower,
        int24 tickUpper,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        TickFeeData memory lower,
        TickFeeData memory upper
    ) internal pure returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (currentTick >= tickLower) {
            feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
        } else {
            unchecked {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
            }
        }

        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (currentTick < tickUpper) {
            feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
        } else {
            unchecked {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
            }
        }

        unchecked {
            feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        }
    }

    function getPendingFees(
        uint128 liquidity,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    ) internal pure returns (uint256 pending0, uint256 pending1) {
        pending0 = uint256(tokensOwed0);
        pending1 = uint256(tokensOwed1);

        if (liquidity == 0) {
            return (pending0, pending1);
        }

        uint256 delta0X128;
        uint256 delta1X128;
        unchecked {
            delta0X128 = feeGrowthInside0X128 - feeGrowthInside0LastX128;
            delta1X128 = feeGrowthInside1X128 - feeGrowthInside1LastX128;
        }

        pending0 += Math.mulDiv(delta0X128, uint256(liquidity), Q128);
        pending1 += Math.mulDiv(delta1X128, uint256(liquidity), Q128);
    }
}
