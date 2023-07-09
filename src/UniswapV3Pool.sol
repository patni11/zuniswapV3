// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./lib/Tick.sol";
import "./lib/Position.sol";
import "forge-std/interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "forge-std/console.sol";

error InvalidTickRange();
error InvalidAddress();
error ZeroLiquidity();
error InsufficientInputAmount();

contract UniswapV3Pool {
    address public immutable token0;
    address public immutable token1;

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    // Packing variables that are read together
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }

    Slot0 public slot0;

    // L
    uint128 public liquidity;

    // Tick info
    using Tick for mapping(int24 => Tick.Info);
    mapping(int24 => Tick.Info) public ticks;

    // Position Info
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    mapping(bytes32 => Position.Info) public positions;

    //EVENTS
    event Mint(
        address caller,
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount,
        uint amount0,
        uint amount1
    );

    constructor(
        address _token0,
        address _token1,
        uint160 _sqrtPriceX96,
        int24 _tick
    ) {
        token0 = _token0;
        token1 = _token1;

        slot0 = Slot0({sqrtPriceX96: _sqrtPriceX96, tick: _tick});
    }

    // function to provide liquidity. Note: Not minting any LP here

    // check for values - tick range, owner address, amount is not zero
    // calculate amount0, amount1
    // if the correct amounts are provided, update tick mapping
    // calculate the bytes32 by using hash, update position mapping

    function mint(
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount
    ) external returns (uint amount0, uint amount1) {
        if (
            lowerTick < MIN_TICK ||
            lowerTick >= upperTick ||
            upperTick > MAX_TICK
        ) revert InvalidTickRange();
        if (amount == 0) revert ZeroLiquidity();
        if (owner == address(0x0)) revert InvalidAddress();

        ticks.update(lowerTick, amount);
        ticks.update(upperTick, amount);

        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );

        position.update(amount);

        // we need to calculate these based on liquidity, currently they are hardcoded
        amount0 = 0.998976618347425280 ether;
        amount1 = 5000 ether;

        liquidity += amount;

        uint256 balance0Before;
        uint256 balance1Before;

        if (amount0 > 0) balance0Before = getBalance0();
        if (amount1 > 0) balance1Before = getBalance1();

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
            amount0,
            amount1
        );

        if (amount0 > 0 && balance0Before + amount0 > getBalance0())
            revert InsufficientInputAmount();

        if (amount1 > 0 && balance1Before + amount1 > getBalance1())
            revert InsufficientInputAmount();

        emit Mint(
            msg.sender,
            owner,
            lowerTick,
            upperTick,
            amount,
            amount0,
            amount
        );
    }

    function getBalance0() internal view returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function getBalance1() internal view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }

    function swap() external {}
}
