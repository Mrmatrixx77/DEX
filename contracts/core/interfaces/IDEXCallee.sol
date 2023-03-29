// SPDX-License-Identifier: MIT
pragma solidity^0.8.17;

interface IDEXCallee {
    function DEXCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}