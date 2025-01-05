# EasyDefi 🚀

A contract for a decentralized exchange (DEX) implementation with AMM (Automated Market Maker) functionality.

## Features ✨

- Create liquidity pools for any ERC20 token pairs (only the owner)
- Add/Remove liquidity to existing pools
- Swap tokens using constant product formula (x \* y = k)
- Fee collection system for swaps
- Reentrancy protection
- Safe ERC20 token handling

## Demo Tokens

The project includes two ERC20 tokens for testing and demonstration:

### AlyraToken (ALY)

```solidity
contract AlyraToken is ERC20, Ownable {
    constructor() ERC20("AlyraToken", "ALY") {
        _mint(msg.sender, 10000000000000000000 * 10 ** 18);
    }
}
```

### LiquidAlyraToken (sALY)

```solidity
contract LiquidAlyraToken is ERC20, Ownable {
    constructor() ERC20("LiquidAlyraToken", "sALY") {
        _mint(msg.sender, 10000000000000000000 * 10 ** 18);
    }
}
```

Both tokens are pre-minted with a large supply for testing purposes.

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- Solidity ^0.8.28

### Installation

1. Clone the repository

```bash
git clone <repository-url>
```

2. Install dependencies

```bash
forge install
```

3. Build

```bash
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run a specific test
forge test --match-test testFunctionName

# Run tests with gas reporting
forge test --gas-report
```

## Core Functions 📚

### Pool Management

- `createPool(address _tokenA, address _tokenB, uint256 _fee)`: Create a new liquidity pool
- `addLiquidity(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB)`: Add liquidity to a pool
- `removeLiquidity(address _tokenA, address _tokenB, uint256 _shares)`: Remove liquidity from a pool

### Trading

- `swap(address _tokenIn, address _tokenOut, uint256 _amountIn)`: Swap tokens

### Fee Management

- `setFeeCollector(address _newCollector)`: Update fee collector address
- `claimFee(address _token)`: Collect accumulated fees

## Security Features

- ReentrancyGuard for swap operations
- Ownership controls for admin functions
- SafeERC20 for token transfers
- Minimum liquidity requirement
- Input validation and checks

## Deployment

1. Create a `.env` file with your configuration:

```env
RPC_URL=your_rpc_url
PRIVATE_KEY=your_private_key
```

2. Deploy using Forge script:

```bash
forge script script/DeployEasyDefi.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY
forge script script/DeployTokens.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## Additional Commands

```bash
# Local blockchain
anvil

# Contract interaction
cast <subcommand>

# Help
forge --help
anvil --help
cast --help
```

## License 📄

This project is licensed under the MIT License.
