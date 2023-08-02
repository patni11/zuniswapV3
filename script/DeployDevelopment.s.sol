// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../test/utils/ERC20Mintable.sol";
import "../src/UniswapV3Pool.sol";
import "../src/Manager.sol";

contract DeployDevelopment is Script {
    uint256 wethBalance = 1 ether;
    uint256 usdcBalance = 5000 ether;
    int24 currentTick = 85176;

    uint160 currentSqrtP = 5602277097478614198912276234240;

    function run() public {
        vm.startBroadcast();
        ERC20Mintable token0 = new ERC20Mintable("Wrapped ETH", "WETH", 18);
        ERC20Mintable token1 = new ERC20Mintable("Circle USD", "USDC", 18);

        UniswapV3Pool pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            currentSqrtP,
            currentTick
        );

        Manager manager = new Manager();

        token0.mint(msg.sender, wethBalance);
        token1.mint(msg.sender, usdcBalance);

        console.log("WETH address", address(token0));
        console.log("USDC address", address(token1));
        console.log("Pool address", address(pool));
        console.log("Manager address", address(manager));

        vm.stopBroadcast();
    }
}
