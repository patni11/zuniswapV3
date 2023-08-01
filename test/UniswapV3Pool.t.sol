// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//import "forge-std/Test.sol";
import "../src/UniswapV3Pool.sol";
import "./utils/ERC20Mintable.sol";
// import "forge-std/console.sol";

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

import "../src/interfaces/IUniswapV3MintCallback.sol";
import "../src/interfaces/IUniswapV3SwapCallback.sol";
import "./utils/TestUtils.sol";

contract UniswapV3PoolTest is
    Test,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    TestUtils
{
    ERC20Mintable public token0;
    ERC20Mintable public token1;
    bool shouldTransferInCallback = true;
    bool shouldSwapInCallback = true;

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
        bool shouldSwapInCallback;
        bool mintLiquidity;
    }

    bytes public userData;

    function setUp() public {
        token0 = new ERC20Mintable("Ethereum", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
        userData = abi.encode(
            UniswapV3Pool.CallbackData(
                address(token0),
                address(token1),
                address(this)
            )
        );
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
            shouldSwapInCallback: false,
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

    function uniswapV3MintCallback(
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        // here we are sending requested/required tokens to the pool onbehalf of user
        if (shouldTransferInCallback) {
            // decode data
            UniswapV3Pool.CallbackData memory extra = abi.decode(
                data,
                (UniswapV3Pool.CallbackData)
            );

            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }

    function uniswapV3SwapCallback(
        int amount0,
        int amount1,
        bytes calldata data
    ) external {
        // here we are sending requested/required tokens to the pool onbehalf of user

        if (shouldSwapInCallback) {
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
        pool.mint(
            address(this),
            -887283,
            86129,
            1517882343751509868544,
            userData
        ); //wrong lower tick
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

        pool.mint(
            address(this),
            84222,
            887290,
            1517882343751509868544,
            userData
        ); // wrong upper tick
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

        pool.mint(
            address(this),
            89222,
            86129,
            1517882343751509868544,
            userData
        ); // lower > upper
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

        pool.mint(address(this), 84222, 86129, 0, userData); // zero liq
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
            shouldTransferInCallback: false,
            shouldSwapInCallback: false,
            mintLiquidity: false
        });

        setupTestCase(params);
        // mint liquidity from pool to this address

        vm.expectRevert(encodeError("InsufficientInputAmount()"));
        pool.mint(
            address(this),
            params.lowerTick,
            params.upperTick,
            params.liquidity,
            userData
        );
    }

    function testSwapBuyEth() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            upperTick: 86129,
            lowerTick: 84222,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            shouldSwapInCallback: true,
            mintLiquidity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);
        token1.mint(address(this), 42 ether);

        uint256 userBalance0Before = token0.balanceOf(address(this));
        uint256 userBalance1Before = token1.balanceOf(address(this));

        token0.approve(address(this), 1000 ether);
        token1.approve(address(this), 2000 ether);

        (int256 amount0Delta, int256 amount1Delta) = pool.swap(
            address(this),
            userData
        );

        // testing swap worked
        assertEq(amount0Delta, -0.008396714242162444 ether);
        assertEq(amount1Delta, 42 ether);

        // testing user sent ethers
        assertEq(
            token0.balanceOf(address(this)),
            uint256(int256(userBalance0Before) - amount0Delta)
        );

        assertEq(
            token1.balanceOf(address(this)),
            uint(int256(userBalance1Before) - amount1Delta)
        );

        // testing pool got the balance
        assertEq(
            token0.balanceOf(address(pool)),
            uint256(int256(poolBalance0) + amount0Delta)
        );
        assertEq(
            token1.balanceOf(address(pool)),
            uint256(int256(poolBalance1) + amount1Delta)
        );

        // testing pool state
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, 5604469350942327889444743441197);
        assertEq(tick, 85284);
        assertEq(pool.liquidity(), 1517882343751509868544);
    }

    function testRevertSwap() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            upperTick: 86129,
            lowerTick: 84222,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            shouldSwapInCallback: false,
            mintLiquidity: true
        });

        setupTestCase(params);
        token1.mint(address(this), 42 ether);

        token0.balanceOf(address(this));
        token1.balanceOf(address(this));

        vm.expectRevert(InsufficientInputAmount.selector);
        pool.swap(address(this), userData);
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
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);

            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                params.lowerTick,
                params.upperTick,
                params.liquidity,
                userData
            );
        }

        shouldTransferInCallback = params.shouldTransferInCallback;
        shouldSwapInCallback = params.shouldSwapInCallback;
    }
}
