// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";
import "./UniswapV3Pool.sol";

// similar to router in V2
//should provide right values to pool contract, implement mint and swap callacks
contract Manager is IUniswapV3MintCallback, IUniswapV3SwapCallback {
    function mint(
        address _poolAddr,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity,
        bytes calldata data
    ) public {
        UniswapV3Pool(_poolAddr).mint(
            msg.sender,
            lowerTick,
            upperTick,
            liquidity,
            data
        );
    }

    function swap(address _poolAddr, bytes calldata data) public {
        UniswapV3Pool(_poolAddr).swap(msg.sender, data);
    }

    function uniswapV3MintCallback(
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        UniswapV3Pool.CallbackData memory extra = abi.decode(
            data,
            (UniswapV3Pool.CallbackData)
        );

        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }

    function uniswapV3SwapCallback(
        int amount0,
        int amount1,
        bytes calldata data
    ) external {
        UniswapV3Pool.CallbackData memory extra = abi.decode(
            data,
            (UniswapV3Pool.CallbackData)
        );

        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(
                extra.payer,
                msg.sender,
                uint(amount0)
            );
        }
        if (amount1 > 0) {
            IERC20(extra.token1).transferFrom(
                extra.payer,
                msg.sender,
                uint(amount1)
            );
        }
    }
}
