// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract TestUtils {
    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }
}
