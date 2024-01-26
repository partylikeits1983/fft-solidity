// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/UniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

import {SD59x18, sd} from "@prb/math/src/SD59x18.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console.sol";

contract UNIdata {
	address owner;

	ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
	address private constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "NO");
		_;
	}

	function getSeriesData() public view {
		address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

		uint24 fee = 500;
		PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(USDC, WETH, fee);
		address poolAddress = PoolAddress.computeAddress(FACTORY, key);
		UniswapV3Pool pool = UniswapV3Pool(poolAddress);

		uint size = 10;
		uint[] memory weightedPrices = new uint[](size); 
		uint decimals = IERC20Ext(USDC).decimals();

		for (uint i = 0; i < size; i++ ) {	
			uint32 twapDuration = 60 * uint32(i) + 1;
			// console.log("TWAP DURATION ", twapDuration);

			uint32[] memory secondsAgos = new uint32[](2);
			secondsAgos[0] = twapDuration;
			secondsAgos[1] = 0;

			(int56[] memory tickCumulatives, ) = pool.observe(
				secondsAgos
			);

			int tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int32(twapDuration));

			
			// console.logInt(tick);
			uint160 sqrtPriceX96 = getSqrtRatioAtTick(int24(tick));


			


			SD59x18 p1 = sd(1.0001e18).pow(sd(int(tick) * 1e18));
			SD59x18 p2 = p1.mul(sd(10e18).pow(sd(-int(decimals))));
			SD59x18 p3 = sd(1e18).div(p2);
			uint price = uint(p3.unwrap());

			console.log("PRICE", price);

			weightedPrices[i] = price;
		}

			console.log("_____________");

		for (uint i = 0; i < weightedPrices.length; i++) {
			console.log("PRICE", weightedPrices[i]);
		}


		// console.log("HERE");
	}

	function getSqrtTwapX96(address uniswapV3Pool, uint32 twapInterval) public view returns (uint160 sqrtPriceX96) {
		if (twapInterval == 0) {
			// return the current price if twapInterval == 0
			(sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
		} else {
			uint32[] memory secondsAgos = new uint32[](2);
			secondsAgos[0] = twapInterval; // from (before)
			secondsAgos[1] = 0; // to (now)

			(int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

			// tick(imprecise as it's an integer) to price
			sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
				int24((tickCumulatives[1] - tickCumulatives[0]) / int32(twapInterval))
			);
		}
	}

	function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) public pure returns (uint256 priceX96) {
		return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
	}

    error InvalidTick();

    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;


    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert InvalidTick();

            uint256 ratio =
                absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }


}

library PoolAddress {
	bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

	struct PoolKey {
		address token0;
		address token1;
		uint24 fee;
	}

	function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory) {
		if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
		return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
	}

	function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
		require(key.token0 < key.token1);
		pool = address(
			uint160(
				uint(
					keccak256(
						abi.encodePacked(
							hex"ff",
							factory,
							keccak256(abi.encode(key.token0, key.token1, key.fee)),
							POOL_INIT_CODE_HASH
						)
					)
				)
			)
		);
	}
}

interface ISwapRouter {
	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint deadline;
		uint amountIn;
		uint amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

	/// @notice Swaps amountIn of one token for as much as possible of another token
	/// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
	/// @return amountOut The amount of the received token
	function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint amountOut);

	struct ExactInputParams {
		bytes path;
		address recipient;
		uint deadline;
		uint amountIn;
		uint amountOutMinimum;
	}

	/// @notice Swaps amountIn of one token for as much as possible of another along the specified path
	/// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
	/// @return amountOut The amount of the received token
	function exactInput(ExactInputParams calldata params) external payable returns (uint amountOut);

	struct ExactOutputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 deadline;
		uint256 amountOut;
		uint256 amountInMaximum;
		uint160 sqrtPriceLimitX96;
	}

	struct ExactOutputParams {
		bytes path;
		address recipient;
		uint256 deadline;
		uint256 amountOut;
		uint256 amountInMaximum;
	}

	function exactOutputSingle(ExactOutputSingleParams memory params) external returns (uint256 amountIn);
}

interface IERC20Ext {
	function decimals() external view returns (uint);
}
