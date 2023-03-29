// SPDX-License-Identifier: MIT

pragma solidity^0.8.17;

import './interfaces/IFactory.sol';
import './interfaces/ITradingPairExchange.sol';
import './TradingPairExchange.sol';

contract Factory is IFactory {


    /// @notice fee structure is not created these address creates for further development
    /// @dev address where is fee going to be sent
    address public feeTo;

    /// @dev fee setter address
    address public feeToSetter;

    /// @dev mapping for storing address of trading pair contracts 
    mapping(address => mapping(address => address)) public getTradingPair;

    /// @dev stores all trading pairs
    address[] public allTradingPairs;

    /// @notice event emitted when a new trading pair is created
    event TradingPairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /// @dev function to create a new trading pair of tokens if not existed using create2 
     function createTradingPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'DEX: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(tokenA != address(0) && tokenB != address(0), 'DEX: ZERO_ADDRESS');
        require(getTradingPair[tokenA][tokenB] == address(0), 'DEX: TRADING_PAIR_EXISTS');

        bytes memory bytecode = type(TradingPairExchange).creationCode;


        bytes32 salt = keccak256(abi.encode(token0, token1));

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        ITradingPairExchange(pair).initialize(token0, token1);
        getTradingPair[tokenA][tokenB] = pair;
        getTradingPair[tokenB][tokenA] = pair;
        allTradingPairs.push(pair);
        emit TradingPairCreated(tokenA, tokenB, pair, allTradingPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'DEX: FORBIDDEN_TO_SET_PROTOCOL_FEE');
        feeTo = _feeTo;
    }
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}