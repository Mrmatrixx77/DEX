// SPDX-License-Identifier: MIT

pragma solidity^0.8.17;

import '../core/interfaces/IFactory.sol';
import '../core//interfaces/ITradingPairExchange.sol';
import '../core/TradingPairExchange.sol';
import './interfaces/IRouter.sol';
import './libraries/DEXLibrary.sol';
import './libraries/TransferHelper.sol';



contract Router is IRouter {
    address public immutable factoryAddr;

    constructor(address _factoryAddr) {
        factoryAddr = _factoryAddr;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "DEX: EXPIRED");
        _;
    }

    function _depositLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        if (
            IFactory(factoryAddr).getTradingPair(tokenA, tokenB) == address(0)
        ) {
            IFactory(factoryAddr).createTradingPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = DEXLibrary.getReserves(
            factoryAddr,
            tokenA,
            tokenB
        );

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = DEXLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                //tokenB is worth MORE than LP thinks, so a smaller amount is required
                require(
                    amountBOptimal >= amountBMin,
                    "DEXLibrary: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                //tokenB is worth LESS than LP thinks, so a higher amount is required
                uint amountAOptimal = DEXLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "DEXLibrary: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function depositLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        ensure(deadline)
        returns (uint amountA, uint amountB, uint liquidity)
    {
        (amountA, amountB) = _depositLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = DEXLibrary.pairFor(factoryAddr, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ITradingPairExchange(pair).mint(to);
    }

    function withdrawLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountAReturned, uint amountBReturned) {
        address pair = DEXLibrary.pairFor(factoryAddr, tokenA, tokenB);
        ITradingPairExchange(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amountASent, uint amountBSent) = ITradingPairExchange(pair).burn(to);
        // (address token0,) = DEXLibrary.sortTokens(tokenA, tokenB);

        amountAReturned = amountASent;
        amountBReturned = amountBSent;

        require(amountASent >= amountAMin, 'DEX: INSUFFICIENT_A_AMOUNT');
        require(amountBSent >= amountBMin, 'DEX: INSUFFICIENT_B_AMOUNT');
    }
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? DEXLibrary.pairFor(factoryAddr, output, path[i + 2]) : _to;
            (DEXLibrary.pairFor(factoryAddr, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB
    ) external override returns (uint amountA, uint amountB) {}
}