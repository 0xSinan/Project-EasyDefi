// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

pragma solidity ^0.8.28;

contract EasyDefi is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event LiquidityAdded(
        address user, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 timestamp
    );
    event LiquidityRemoved(
        address user, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 timestamp
    );
    event Swap(address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 timestamp);

    event PoolCreated(address tokenA, address tokenB, uint256 id, uint256 timestamp);

    struct Pool {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 fee;
    }

    /// @dev Maps pool ID to Pool struct containing pool information
    mapping(uint256 => Pool) pools;

    /// @dev Maps token pair addresses to their pool ID (token addresses must be sorted)
    /// @dev First address -> Second address -> Pool ID
    mapping(address => mapping(address => uint256)) public getPoolIds;

    /// @dev Maps pool ID to total shares
    mapping(uint256 => uint256) public totalPoolShares;

    /// @dev Maps user address to their shares in a pool
    mapping(address => mapping(uint256 => uint256)) public shares;

    /// @dev Maps collected fees for each address
    mapping(address => uint256) public feeCollected;

    /// @dev Array of all pools
    Pool[] poolsList;

    /// @dev Address that collects fees
    address private feeCollector;

    /// @dev Minimum basis points divisor for fee calculations (100% = 10000)
    uint256 constant BPS_DIVIDER = 10000;

    /// @dev Minimum liquidity required to initialize a pool, prevents first depositor manipulation
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    /// @dev Counter for generating unique pool IDs, starts at 1
    uint256 nextPoolId = 1;

    constructor(address _feeCollector) Ownable(msg.sender) {
        feeCollector = _feeCollector;
    }

    /**
     * @notice Updates the fee collector address
     * @dev Only callable by the owner of the contract
     * @param _newCollector The address of the new fee collector
     */
    function setFeeCollector(address _newCollector) external onlyOwner {
        require(_newCollector != address(0), "zero address");
        require(_newCollector != feeCollector, "same address");
        feeCollector = _newCollector;
    }

    /**
     * @notice Claims accumulated fees for a specific token
     * @dev Only callable by the owner of the contract. Transfers collected fees to the fee collector
     * @param _token The address of the token to claim fees
     */
    function claimFee(address _token) external onlyOwner {
        require(_token != address(0), "invalid token");
        uint256 feeBalance = feeCollected[_token];
        require(feeBalance > 0, "no fees to claim");
        feeCollected[_token] = 0;
        IERC20(_token).safeTransfer(feeCollector, feeBalance);
    }

    /**
     * @notice Returns all pools that exist in the contract
     * @dev Returns the array of Pool structs
     * @return Array of Pool structs containing all pool information
     */
    function getPoolsList() external view returns (Pool[] memory) {
        return poolsList;
    }

    /**
     * @notice Internal helper to sort token addresses
     * @dev Ensures consistent pool identification regardless of token input order
     * @param _tokenA First token address
     * @param _tokenB Second token address
     * @return Tuple of sorted addresses (lower address first)
     */
    function sort(address _tokenA, address _tokenB) internal pure returns (address, address) {
        return _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
    }

    /**
     * @notice Get the current reserves for a pool
     * @dev Internal function to fetch reserves using token addresses
     * @param _tokenA The address of the first token
     * @param _tokenB The address of the second token
     * @return Reserve of token A
     * @return Reserve of token B
     */
    function getReserves(address _tokenA, address _tokenB) public view returns (uint256, uint256) {
        (address tokenA, address tokenB) = sort(_tokenA, _tokenB);
        uint256 id = getPoolIds[tokenA][tokenB];
        Pool memory pool = pools[id];
        return (pool.reserveA, pool.reserveB);
    }

    /**
     * @notice Calculate the output amount for a given input amount and pair reserves
     * @dev Uses the constant product formula (x * y = k) and includes fee calculation. Callable within the contract
     * @param _amountIn The input amount of tokens
     * @param _reserveIn The reserve of the input token
     * @param _reserveOut The reserve of the output token
     * @return uint256 The calculated output amount after fees
     */
    function getAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) public pure returns (uint256) {
        uint256 numerator = _amountIn * _reserveOut;
        uint256 denominator = _reserveIn + _amountIn;
        return (numerator / denominator);
    }

    /**
     * @notice Allow the owner to create a new liquidity pool with two tokens
     * @dev Only callable by the owner of the contract
     * @param _tokenA The address of the first token
     * @param _tokenB The address of the second token
     * @param _fee The fee percentage in basis points (BPS)
     */
    function createPool(address _tokenA, address _tokenB, uint256 _fee) external onlyOwner {
        require(_tokenA != address(0) && _tokenB != address(0) && _tokenA != _tokenB, "invalid tokens");

        require(_fee < BPS_DIVIDER, "invalid fee");

        (address tokenA, address tokenB) = sort(_tokenA, _tokenB);
        require(getPoolIds[tokenA][tokenB] == 0, "pool already exist");

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), MINIMUM_LIQUIDITY);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), MINIMUM_LIQUIDITY);

        Pool memory pool = Pool(tokenA, tokenB, MINIMUM_LIQUIDITY, MINIMUM_LIQUIDITY, _fee);

        totalPoolShares[nextPoolId] = MINIMUM_LIQUIDITY;
        pools[nextPoolId] = pool;
        getPoolIds[tokenA][tokenB] = nextPoolId;
        poolsList.push(pool);

        emit PoolCreated(tokenA, tokenB, nextPoolId, block.timestamp);

        nextPoolId++;
    }

    /**
     * @notice Swap an exact amount of input tokens for output tokens
     * @dev Calculates output amount based (x * y = k) and handles the token transfer
     * @param _tokenIn The address of the token to swap from
     * @param _tokenOut The address of the token to swap to
     * @param _amountIn The amount of input tokens to swap
     * @return _amountOut The amount of output tokens received from the swap
     */
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn)
        external
        nonReentrant
        returns (uint256 _amountOut)
    {
        require(_tokenIn != address(0) && _tokenOut != address(0) && _tokenIn != _tokenOut, "invalid tokens");

        require(_amountIn > 0, "invalid amount");

        (address tokenA, address tokenB) = sort(_tokenIn, _tokenOut);
        uint256 id = getPoolIds[tokenA][tokenB];

        require(id != 0, "pool doesn't exist");

        Pool storage pool = pools[id];

        uint256 feeAmount = (_amountIn * pool.fee) / BPS_DIVIDER;
        uint256 amountInAfterFee = _amountIn - feeAmount;

        if (_tokenIn == pool.tokenA) {
            _amountOut = getAmountOut(amountInAfterFee, pool.reserveA, pool.reserveB);
            require(_amountOut <= pool.reserveB, "insufficient liquidity");
        } else {
            _amountOut = getAmountOut(amountInAfterFee, pool.reserveB, pool.reserveA);
            require(_amountOut <= pool.reserveA, "insufficient liquidity");
        }

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);

        feeCollected[_tokenIn] += feeAmount;

        if (_tokenIn == pool.tokenA) {
            pool.reserveA += amountInAfterFee;
            pool.reserveB -= _amountOut;
        } else {
            pool.reserveB += amountInAfterFee;
            pool.reserveA -= _amountOut;
        }

        poolsList[id - 1] = pool;

        IERC20(_tokenOut).safeTransfer(msg.sender, _amountOut);

        emit Swap(msg.sender, _tokenIn, _tokenOut, _amountIn, _amountOut, block.timestamp);
    }

    /**
     * @notice Add liquidity to an existing pool while maintaining the price ratio
     * @dev Calculates optimal amounts to preserve (x * y = k)
     * @param _tokenA The address of the first token
     * @param _tokenB The address of the second token
     * @param _amountA The desired amount of first token to add
     * @param _amountB The desired amount of second token to add
     * @return optimalAmountA The actual amount of first token added
     * @return optimalAmountB The actual amount of second token added
     */
    function addLiquidity(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB)
        external
        nonReentrant
        returns (uint256 optimalAmountA, uint256 optimalAmountB)
    {
        (address tokenA, address tokenB) = sort(_tokenA, _tokenB);
        uint256 id = getPoolIds[tokenA][tokenB];
        require(id != 0, "pool doesn't exist");

        require(_amountA > 0 && _amountB > 0, "amounts must be > 0");

        Pool storage pool = pools[id];

        uint256 quotientB = (_amountA * pool.reserveB) / pool.reserveA;
        uint256 quotientA = (_amountB * pool.reserveA) / pool.reserveB;

        if (quotientB <= _amountB) {
            optimalAmountA = _amountA;
            optimalAmountB = quotientB;
        } else {
            optimalAmountA = quotientA;
            optimalAmountB = _amountB;
        }

        uint256 _shares = (optimalAmountA * totalPoolShares[id]) / pool.reserveA;

        IERC20(pool.tokenA).safeTransferFrom(msg.sender, address(this), optimalAmountA);
        IERC20(pool.tokenB).safeTransferFrom(msg.sender, address(this), optimalAmountB);

        pool.reserveA += optimalAmountA;
        pool.reserveB += optimalAmountB;

        totalPoolShares[id] += _shares;
        shares[msg.sender][id] += _shares;
        poolsList[id - 1] = pool;

        emit LiquidityAdded(msg.sender, pool.tokenA, pool.tokenB, optimalAmountA, optimalAmountB, block.timestamp);

        return (optimalAmountA, optimalAmountB);
    }

    /**
     * @notice Remove liquidity from a pool and receive both tokens
     * @dev Burns shares and transfers tokens proportional to share amount
     * @param _tokenA The address of the first token
     * @param _tokenB The address of the second token
     * @param _shares The amount of shares to burn
     */
    function removeLiquidity(address _tokenA, address _tokenB, uint256 _shares) external nonReentrant {
        (address tokenA, address tokenB) = sort(_tokenA, _tokenB);
        uint256 id = getPoolIds[tokenA][tokenB];
        require(id != 0, "pool doesn't exist");

        require(shares[msg.sender][id] >= _shares, "!shares to withdraw");

        Pool storage pool = pools[id];

        uint256 amountA = (_shares * pool.reserveA) / totalPoolShares[id];
        uint256 amountB = (_shares * pool.reserveB) / totalPoolShares[id];

        pool.reserveA -= amountA;
        pool.reserveB -= amountB;

        shares[msg.sender][id] -= _shares;
        totalPoolShares[id] -= _shares;
        poolsList[id - 1] = pool;

        IERC20(pool.tokenA).safeTransfer(msg.sender, amountA);
        IERC20(pool.tokenB).safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, pool.tokenA, pool.tokenB, amountA, amountB, block.timestamp);
    }
}
