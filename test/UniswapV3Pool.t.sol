// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/UniswapV3Pool.sol";
import "./utils/ERC20Mintable.sol";
import "forge-std/console.sol";
import "../src/interfaces/IUniswapV3MintCallback.sol";
import "./utils/TestUtils.sol";

contract UniswapV3PoolTest is Test, IUniswapV3MintCallback, TestUtils {
    ERC20Mintable public token0;
    ERC20Mintable public token1;
    bool shouldTransferInCallback = true;
    UniswapV3Pool pool;

    struct TestCaseParams {
        uint wethBalance;
        uint usdcBalance;
        int24 currentTick;
        int24 upperTick;
        int24 lowerTick;
        uint128 liquidity;
        uint128 currentSqrtP;
        bool shouldTransferInCallback;
        bool mintLiquidity;
    }

    function setUp() public {
        token0 = new ERC20Mintable("Ethereum", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }

    function testMintSuccess() public {
        TestCaseParams memory testParams = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            upperTick: 86129,
            lowerTick: 84222,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        uint256 poolBalance0;
        uint256 poolBalance1;

        (poolBalance0, poolBalance1) = setupTestCase(testParams);

        uint256 expectedAmount0 = 0.998976618347425280 ether;
        uint256 expectedAmount1 = 5000 ether;

        // expected amount is returned
        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );

        //expected amount is in pool
        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);

        //get the position and check it's set up correctly
        //position has key as hash so
        bytes32 key = keccak256(
            abi.encodePacked(
                address(this),
                testParams.lowerTick,
                testParams.upperTick
            )
        );
        uint128 positionLiquidity = pool.positions(key);
        assertEq(positionLiquidity, testParams.liquidity);

        //check the tick values, check the lower tick and upper tick
        (bool initialized, uint128 liquidity) = pool.ticks(
            testParams.lowerTick
        );
        assertTrue(initialized);
        assertEq(liquidity, testParams.liquidity);

        (initialized, liquidity) = pool.ticks(testParams.upperTick);
        assertTrue(initialized);
        assertEq(liquidity, testParams.liquidity);

        //finally check the sqrt price and liquidity
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, testParams.currentSqrtP);
        assertEq(tick, testParams.currentTick);
        assertEq(pool.liquidity(), testParams.liquidity);
    }

    // setups the basic testcase for any general situation
    // mints tokens to address and crates pool and mints liquidity
    function setupTestCase(
        TestCaseParams memory params
    ) internal returns (uint256 poolBalance0, uint256 poolBalance1) {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        //initialize the pool
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        // mint liquidity from pool to this address
        if (params.mintLiquidity) {
            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                params.lowerTick,
                params.upperTick,
                params.liquidity
            );
        }

        shouldTransferInCallback = params.shouldTransferInCallback;
    }

    function uniswapV3MintCallback(uint amount0, uint amount1) external {
        // here we are sending requested/required tokens to the pool onbehalf of user
        console.log(amount0);
        console.log(amount1);

        console.log(token0.balanceOf(address(this)));
        if (shouldTransferInCallback) {
            token0.transfer(msg.sender, amount0);
            token1.transfer(msg.sender, amount1);
        }
    }

    // testing failed cases when providing liquidity/minting
    // - wrong tick values - lower tick is > upper tick, tick values not in range,
    // - zero liquidity
    // - burn address
    // - test when the user does not provide the correct values in the callback, when the values are less and when the values are more

    function testLowerTickRangeRevert() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            5602277097478614198912276234240, //liq
            85176 //currentTick
        );

        vm.expectRevert(encodeError("InvalidTickRange()"));
        // mint liquidity from pool to this address
        pool.mint(address(this), -887283, 86129, 1517882343751509868544); //wrong lower tick
    }

    function testUpperTickRangeRevert() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            5602277097478614198912276234240, //liq
            85176 //currentTick
        );

        vm.expectRevert(encodeError("InvalidTickRange()"));
        // mint liquidity from pool to this address

        pool.mint(address(this), 84222, 887290, 1517882343751509868544); // wrong upper tick
    }

    function testLowerTickGreaterRevert() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            5602277097478614198912276234240, //liq
            85176 //currentTick
        );

        vm.expectRevert(encodeError("InvalidTickRange()"));
        // mint liquidity from pool to this address

        pool.mint(address(this), 89222, 86129, 1517882343751509868544); // lower > upper
    }

    function testZeroLiquidity() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            5602277097478614198912276234240, //price
            85176 //currentTick
        );

        vm.expectRevert(encodeError("ZeroLiquidity()"));
        // mint liquidity from pool to this address

        pool.mint(address(this), 84222, 86129, 0); // zero liq
    }

    function testNotEnoughTokens() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0 ether,
            usdcBalance: 0 ether,
            currentTick: 85176,
            upperTick: 86129,
            lowerTick: 84222,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        //initialize the pool
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        // mint liquidity from pool to this address
        if (params.mintLiquidity) {
            vm.expectRevert(encodeError("InsufficientInputAmount()"));
            pool.mint(
                address(this),
                params.lowerTick,
                params.upperTick,
                params.liquidity
            );
        }

        shouldTransferInCallback = params.shouldTransferInCallback;
    }
}
