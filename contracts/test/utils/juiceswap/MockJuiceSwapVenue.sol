// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { MockERC20 } from "../../../src/mocks/MockERC20.sol";
import { IJuiceSwapFactory } from "../../../src/interfaces/venues/juiceswap/IJuiceSwapFactory.sol";
import { IJuiceSwapPool } from "../../../src/interfaces/venues/juiceswap/IJuiceSwapPool.sol";
import {
    IJuiceSwapPositionManager
} from "../../../src/interfaces/venues/juiceswap/IJuiceSwapPositionManager.sol";
import {
    IJuiceSwapSwapRouter
} from "../../../src/interfaces/venues/juiceswap/IJuiceSwapSwapRouter.sol";
import { JuiceSwapFeeMath } from "../../../src/libraries/venues/juiceswap/JuiceSwapFeeMath.sol";
import {
    JuiceSwapLiquidityMath
} from "../../../src/libraries/venues/juiceswap/JuiceSwapLiquidityMath.sol";
import { JuiceSwapTickMath } from "../../../src/libraries/venues/juiceswap/JuiceSwapTickMath.sol";

contract MockJuiceSwapFactory is IJuiceSwapFactory {
    mapping(uint24 fee => int24 spacing) private _tickSpacings;
    mapping(bytes32 key => address pool) private _pools;

    constructor() {
        _tickSpacings[500] = 10;
        _tickSpacings[3000] = 60;
        _tickSpacings[10_000] = 200;
    }

    function setFeeAmountTickSpacing(
        uint24 fee,
        int24 spacing
    ) external {
        _tickSpacings[fee] = spacing;
    }

    function feeAmountTickSpacing(
        uint24 fee
    ) external view returns (int24) {
        return _tickSpacings[fee];
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool) {
        return _pools[_poolKey(tokenA, tokenB, fee)];
    }

    function deployPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint160 sqrtPriceX96,
        int24 tick
    ) external returns (MockJuiceSwapPool pool) {
        int24 spacing = _tickSpacings[fee];
        require(spacing != 0, "FEE");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        bytes32 key = _poolKey(token0, token1, fee);
        require(_pools[key] == address(0), "POOL_EXISTS");

        pool =
            new MockJuiceSwapPool(address(this), token0, token1, fee, spacing, sqrtPriceX96, tick);
        _pools[key] = address(pool);
    }

    function _poolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (bytes32) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encode(token0, token1, fee));
    }
}

contract MockJuiceSwapPool is IJuiceSwapPool {
    struct Observation {
        uint32 timestamp;
        int56 tickCumulative;
        int24 tick;
    }

    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        bool initialized;
    }

    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint24 public immutable fee;
    int24 public immutable tickSpacing;

    uint160 private _sqrtPriceX96;
    int24 private _tick;
    uint256 private _feeGrowthGlobal0X128;
    uint256 private _feeGrowthGlobal1X128;
    uint128 private _liquidity;

    mapping(int24 tick => TickInfo info) private _ticks;
    Observation[] private _observations;

    constructor(
        address factory_,
        address token0_,
        address token1_,
        uint24 fee_,
        int24 tickSpacing_,
        uint160 sqrtPriceX96_,
        int24 tick_
    ) {
        factory = factory_;
        token0 = token0_;
        token1 = token1_;
        fee = fee_;
        tickSpacing = tickSpacing_;
        _sqrtPriceX96 = sqrtPriceX96_;
        _tick = tick_;
        _observations.push(
            Observation({ timestamp: uint32(block.timestamp), tickCumulative: 0, tick: tick_ })
        );
    }

    function feeGrowthGlobal0X128() external view returns (uint256) {
        return _feeGrowthGlobal0X128;
    }

    function feeGrowthGlobal1X128() external view returns (uint256) {
        return _feeGrowthGlobal1X128;
    }

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return (
            _sqrtPriceX96,
            _tick,
            uint16(_observations.length - 1),
            uint16(_observations.length),
            uint16(_observations.length),
            0,
            true
        );
    }

    function ticks(
        int24 tick_
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        )
    {
        TickInfo memory info = _ticks[tick_];
        return (
            info.liquidityGross,
            info.liquidityNet,
            info.feeGrowthOutside0X128,
            info.feeGrowthOutside1X128,
            info.tickCumulativeOutside,
            info.secondsPerLiquidityOutsideX128,
            info.secondsOutside,
            info.initialized
        );
    }

    function setPrice(
        uint160 newSqrtPriceX96,
        int24 newTick
    ) external {
        _pushObservation(newTick);
        _sqrtPriceX96 = newSqrtPriceX96;
        _tick = newTick;
    }

    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        )
    {
        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);

        for (uint256 i = 0; i < secondsAgos.length; ++i) {
            tickCumulatives[i] = _tickCumulativeAt(uint32(block.timestamp) - secondsAgos[i]);
        }
    }

    function registerLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) external {
        _touchTick(tickLower);
        _touchTick(tickUpper);

        TickInfo storage lower = _ticks[tickLower];
        TickInfo storage upper = _ticks[tickUpper];
        lower.liquidityGross += liquidityDelta;
        lower.liquidityNet += int128(liquidityDelta);
        upper.liquidityGross += liquidityDelta;
        upper.liquidityNet -= int128(liquidityDelta);
        _liquidity += liquidityDelta;
    }

    function unregisterLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) external {
        TickInfo storage lower = _ticks[tickLower];
        TickInfo storage upper = _ticks[tickUpper];
        require(lower.initialized && upper.initialized, "TICKS");
        require(
            lower.liquidityGross >= liquidityDelta && upper.liquidityGross >= liquidityDelta,
            "GROSS"
        );
        require(_liquidity >= liquidityDelta, "LIQUIDITY");

        lower.liquidityGross -= liquidityDelta;
        lower.liquidityNet -= int128(liquidityDelta);
        upper.liquidityGross -= liquidityDelta;
        upper.liquidityNet += int128(liquidityDelta);
        _liquidity -= liquidityDelta;
    }

    function accrueFees(
        uint256 amount0,
        uint256 amount1
    ) external {
        require(_liquidity != 0 || (amount0 == 0 && amount1 == 0), "NO_LIQUIDITY");

        if (amount0 != 0) {
            _feeGrowthGlobal0X128 += Math.mulDiv(amount0, JuiceSwapFeeMath.Q128, _liquidity);
        }
        if (amount1 != 0) {
            _feeGrowthGlobal1X128 += Math.mulDiv(amount1, JuiceSwapFeeMath.Q128, _liquidity);
        }
    }

    function _touchTick(
        int24 tick_
    ) internal {
        TickInfo storage info = _ticks[tick_];
        if (info.initialized) {
            return;
        }

        if (tick_ <= _tick) {
            info.feeGrowthOutside0X128 = _feeGrowthGlobal0X128;
            info.feeGrowthOutside1X128 = _feeGrowthGlobal1X128;
        }
        info.initialized = true;
    }

    function _pushObservation(
        int24 newTick
    ) internal {
        Observation memory last = _observations[_observations.length - 1];
        uint32 timestamp = uint32(block.timestamp);
        int56 tickCumulative = last.tickCumulative + int56(int256(last.tick))
            * int56(uint56(timestamp - last.timestamp));

        if (last.timestamp == timestamp) {
            last.tickCumulative = tickCumulative;
            last.tick = newTick;
            _observations[_observations.length - 1] = last;
            return;
        }

        _observations.push(
            Observation({ timestamp: timestamp, tickCumulative: tickCumulative, tick: newTick })
        );
    }

    function _tickCumulativeAt(
        uint32 targetTimestamp
    ) internal view returns (int56 tickCumulative) {
        Observation memory first = _observations[0];
        require(targetTimestamp >= first.timestamp, "OLD");

        Observation memory observation = first;
        for (uint256 i = _observations.length; i > 0; --i) {
            Observation memory candidate = _observations[i - 1];
            if (candidate.timestamp <= targetTimestamp) {
                observation = candidate;
                break;
            }
        }

        tickCumulative = observation.tickCumulative + int56(int256(observation.tick))
            * int56(uint56(targetTimestamp - observation.timestamp));
    }
}

contract MockJuiceSwapPositionManager is IJuiceSwapPositionManager {
    using SafeERC20 for IERC20;

    struct Position {
        address owner;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    IJuiceSwapFactory public immutable FACTORY;
    uint256 public nextTokenId = 1;

    mapping(uint256 tokenId => Position position) internal _positions;

    constructor(
        IJuiceSwapFactory factory_
    ) {
        FACTORY = factory_;
    }

    modifier onlyOwner(
        uint256 tokenId
    ) {
        require(_positions[tokenId].owner == msg.sender, "NOT_OWNER");
        _;
    }

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        Position memory position = _positions[tokenId];
        require(position.owner != address(0), "INVALID_TOKEN");

        return (
            0,
            address(0),
            position.token0,
            position.token1,
            position.fee,
            position.tickLower,
            position.tickUpper,
            position.liquidity,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.tokensOwed0,
            position.tokensOwed1
        );
    }

    function mint(
        MintParams calldata params
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        address poolAddress = FACTORY.getPool(params.token0, params.token1, params.fee);
        require(poolAddress != address(0), "POOL");
        require(params.recipient != address(0), "RECIPIENT");

        MockJuiceSwapPool pool = MockJuiceSwapPool(poolAddress);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint160 sqrtLower = JuiceSwapTickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtUpper = JuiceSwapTickMath.getSqrtRatioAtTick(params.tickUpper);

        liquidity = JuiceSwapLiquidityMath.getLiquidityForAmounts(
            sqrtPriceX96, sqrtLower, sqrtUpper, params.amount0Desired, params.amount1Desired
        );
        require(liquidity != 0, "ZERO_LIQUIDITY");

        (amount0, amount1) = JuiceSwapLiquidityMath.getAmountsForLiquidity(
            sqrtPriceX96, sqrtLower, sqrtUpper, liquidity
        );
        IERC20(params.token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(params.token1).safeTransferFrom(msg.sender, address(this), amount1);

        pool.registerLiquidity(params.tickLower, params.tickUpper, liquidity);
        (uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128) =
            _currentFeeGrowthInside(pool, params.tickLower, params.tickUpper);

        tokenId = nextTokenId++;
        _positions[tokenId] = Position({
            owner: params.recipient,
            token0: params.token0,
            token1: params.token1,
            fee: params.fee,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: feeGrowthInside1LastX128,
            tokensOwed0: 0,
            tokensOwed1: 0
        });
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external onlyOwner(params.tokenId) returns (uint256 amount0, uint256 amount1) {
        Position storage position = _positions[params.tokenId];
        require(params.liquidity <= position.liquidity, "INSUFFICIENT_LIQUIDITY");

        if (params.liquidity == 0) {
            return (0, 0);
        }

        MockJuiceSwapPool pool = _poolForPosition(position);
        _accruePositionFees(position, pool);

        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint160 sqrtLower = JuiceSwapTickMath.getSqrtRatioAtTick(position.tickLower);
        uint160 sqrtUpper = JuiceSwapTickMath.getSqrtRatioAtTick(position.tickUpper);

        (amount0, amount1) = JuiceSwapLiquidityMath.getAmountsForLiquidity(
            sqrtPriceX96, sqrtLower, sqrtUpper, params.liquidity
        );

        position.liquidity -= params.liquidity;
        position.tokensOwed0 += uint128(amount0);
        position.tokensOwed1 += uint128(amount1);
        pool.unregisterLiquidity(position.tickLower, position.tickUpper, params.liquidity);
    }

    function collect(
        CollectParams calldata params
    ) external onlyOwner(params.tokenId) returns (uint256 amount0, uint256 amount1) {
        Position storage position = _positions[params.tokenId];
        if (position.liquidity != 0) {
            _accruePositionFees(position, _poolForPosition(position));
        }

        amount0 = Math.min(position.tokensOwed0, params.amount0Max);
        amount1 = Math.min(position.tokensOwed1, params.amount1Max);

        if (amount0 != 0) {
            position.tokensOwed0 -= uint128(amount0);
            IERC20(position.token0).safeTransfer(params.recipient, amount0);
        }
        if (amount1 != 0) {
            position.tokensOwed1 -= uint128(amount1);
            IERC20(position.token1).safeTransfer(params.recipient, amount1);
        }
    }

    function burn(
        uint256 tokenId
    ) external onlyOwner(tokenId) {
        Position memory position = _positions[tokenId];
        require(position.liquidity == 0, "NON_ZERO_LIQUIDITY");
        require(position.tokensOwed0 == 0 && position.tokensOwed1 == 0, "UNCOLLECTED");
        delete _positions[tokenId];
    }

    function addFees(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) external {
        Position storage position = _positions[tokenId];
        require(position.owner != address(0), "INVALID_TOKEN");

        MockJuiceSwapPool pool = _poolForPosition(position);
        if (amount0 != 0) {
            MockERC20(position.token0).mint(address(this), amount0);
        }
        if (amount1 != 0) {
            MockERC20(position.token1).mint(address(this), amount1);
        }
        pool.accrueFees(amount0, amount1);
    }

    function _poolForPosition(
        Position storage position
    ) internal view returns (MockJuiceSwapPool pool) {
        pool = MockJuiceSwapPool(FACTORY.getPool(position.token0, position.token1, position.fee));
        require(address(pool) != address(0), "POOL");
    }

    function _accruePositionFees(
        Position storage position,
        MockJuiceSwapPool pool
    ) internal {
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            _currentFeeGrowthInside(pool, position.tickLower, position.tickUpper);
        (uint256 pending0, uint256 pending1) = JuiceSwapFeeMath.getPendingFees(
            position.liquidity,
            feeGrowthInside0X128,
            feeGrowthInside1X128,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.tokensOwed0,
            position.tokensOwed1
        );

        position.feeGrowthInside0LastX128 = feeGrowthInside0X128;
        position.feeGrowthInside1LastX128 = feeGrowthInside1X128;
        position.tokensOwed0 = uint128(pending0);
        position.tokensOwed1 = uint128(pending1);
    }

    function _currentFeeGrowthInside(
        MockJuiceSwapPool pool,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        (, int24 currentTick,,,,,) = pool.slot0();
        (JuiceSwapFeeMath.TickFeeData memory lower, bool lowerInitialized) =
            _tickFeeData(pool, tickLower);
        (JuiceSwapFeeMath.TickFeeData memory upper, bool upperInitialized) =
            _tickFeeData(pool, tickUpper);
        require(lowerInitialized && upperInitialized, "TICKS");

        return JuiceSwapFeeMath.getFeeGrowthInside(
            currentTick,
            tickLower,
            tickUpper,
            pool.feeGrowthGlobal0X128(),
            pool.feeGrowthGlobal1X128(),
            lower,
            upper
        );
    }

    function _tickFeeData(
        MockJuiceSwapPool pool,
        int24 tick_
    ) internal view returns (JuiceSwapFeeMath.TickFeeData memory data, bool initialized) {
        (,, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128,,,, bool tickInitialized) =
            pool.ticks(tick_);
        data = JuiceSwapFeeMath.TickFeeData({
            feeGrowthOutside0X128: feeGrowthOutside0X128,
            feeGrowthOutside1X128: feeGrowthOutside1X128
        });
        initialized = tickInitialized;
    }
}

contract MockJuiceSwapSwapRouter is IJuiceSwapSwapRouter {
    using SafeERC20 for IERC20;

    uint24 internal constant FEE_DENOMINATOR = 1_000_000;
    uint16 internal constant BPS_DENOMINATOR = 10_000;

    IJuiceSwapFactory public immutable FACTORY;
    uint16 public exactInputOutBps = BPS_DENOMINATOR;

    constructor(
        IJuiceSwapFactory factory_
    ) {
        FACTORY = factory_;
    }

    function setExactInputOutBps(
        uint16 exactInputOutBps_
    ) external {
        require(exactInputOutBps_ <= BPS_DENOMINATOR, "BPS");
        exactInputOutBps = exactInputOutBps_;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut) {
        address poolAddress = FACTORY.getPool(params.tokenIn, params.tokenOut, params.fee);
        require(poolAddress != address(0), "POOL");

        IJuiceSwapPool pool = IJuiceSwapPool(poolAddress);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);

        uint256 amountInAfterFee =
            Math.mulDiv(params.amountIn, FEE_DENOMINATOR - params.fee, FEE_DENOMINATOR);
        amountOut = params.tokenIn == pool.token0()
            ? _token0ToToken1AtSpot(amountInAfterFee, sqrtPriceX96)
            : _token1ToToken0AtSpot(amountInAfterFee, sqrtPriceX96);
        amountOut = Math.mulDiv(amountOut, exactInputOutBps, BPS_DENOMINATOR);
        require(amountOut >= params.amountOutMinimum, "MIN_OUT");

        MockERC20(params.tokenOut).mint(params.recipient, amountOut);
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external returns (uint256 amountIn) {
        address poolAddress = FACTORY.getPool(params.tokenIn, params.tokenOut, params.fee);
        require(poolAddress != address(0), "POOL");

        IJuiceSwapPool pool = IJuiceSwapPool(poolAddress);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        uint256 amountInWithoutFee = params.tokenIn == pool.token0()
            ? _token1ToToken0AtSpot(params.amountOut, sqrtPriceX96)
            : _token0ToToken1AtSpot(params.amountOut, sqrtPriceX96);
        amountIn = Math.mulDiv(
            amountInWithoutFee, FEE_DENOMINATOR, FEE_DENOMINATOR - params.fee, Math.Rounding.Ceil
        );
        require(amountIn <= params.amountInMaximum, "MAX_IN");

        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        MockERC20(params.tokenOut).mint(params.recipient, params.amountOut);
    }

    function _token0ToToken1AtSpot(
        uint256 amount0,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256) {
        uint256 priceX96 = Math.mulDiv(sqrtPriceX96, sqrtPriceX96, JuiceSwapLiquidityMath.Q96);
        return Math.mulDiv(amount0, priceX96, JuiceSwapLiquidityMath.Q96);
    }

    function _token1ToToken0AtSpot(
        uint256 amount1,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256) {
        uint256 priceX96 = Math.mulDiv(sqrtPriceX96, sqrtPriceX96, JuiceSwapLiquidityMath.Q96);
        return Math.mulDiv(amount1, JuiceSwapLiquidityMath.Q96, priceX96);
    }
}
