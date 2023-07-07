// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV3MintCallback {
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1) external;
}