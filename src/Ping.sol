// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/UniswapV3Pool.sol";


import "forge-std/console.sol";

contract UNIdata {

	address owner;

	ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

	constructor() {
		owner = msg.sender;


	}

	modifier onlyOwner() {
		require(msg.sender == owner, "NO");
		_;
	}

	function getSeriesData() public onlyOwner {
		address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

		uint24 fee = 500;

		address poolAddress = PoolAddress.getPoolKey(USDC, WETH, fee);
		UniswapV3Pool pool = UniswapV3Pool(poolAddress);

		uint32[] memory secondsAgos = new uint32[](2);
		secondsAgos[0] = 3600; // 1 hour
		secondsAgos[1] = 0;

		(int56[] tickCumulatives, uint160[] secondsPerLiquidityCumulativeX128s) = pool.observe(secondsAgos);

		for (uint i = 0; i < tickCumulatives.length; i++) {
			console.log(tickCumulatives[i]);
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
