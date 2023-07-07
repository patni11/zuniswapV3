// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Position {
    struct Info {
        uint128 liquidity;
    }

    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 lowerTick,
        int24 upperTick
    ) internal view returns (Position.Info storage) {
        return self[keccak256(abi.encodePacked(owner, lowerTick, upperTick))];
    }

    function update(
        Position.Info storage self,
        uint128 liquidityDelta
    ) internal {
        uint128 liquidityBefore = self.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;

        self.liquidity = liquidityAfter;
    }
}
