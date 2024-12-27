// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {EasyDefi} from "../../src/EasyDefi.sol";
import {DeployEasyDefi} from "../../script/DeployEasyDefi.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract EasyDefiTest is Test {
    event PoolCreated(address tokenA, address tokenB, uint256 id, uint256 timestamp);
    event LiquidityAdded(
        address user, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 timestamp
    );
    event LiquidityRemoved(
        address user, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 timestamp
    );

    event Swap(address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 timestamp);

    EasyDefi easydefi;

    address USER_1 = makeAddr("user_1");

    ERC20Mock tokenA;
    ERC20Mock tokenB;
    ERC20Mock tokenC;

    uint256 constant AMOUNT = 100000000 * 10 ** 18;
    uint256 constant BPS_DIVIDER = 10000;
    uint256 constant MINIMUM_LIQUIDITY = 1000;
    uint256 constant POOL_FEE = 30;

    function setUp() external {
        DeployEasyDefi deployEasyDefi = new DeployEasyDefi();
        easydefi = deployEasyDefi.run();

        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        tokenC = new ERC20Mock();

        deal(address(tokenA), msg.sender, AMOUNT);
        deal(address(tokenB), msg.sender, AMOUNT);
        deal(address(tokenC), msg.sender, AMOUNT);

        deal(address(tokenA), USER_1, AMOUNT);
        deal(address(tokenB), USER_1, AMOUNT);
        deal(address(tokenC), USER_1, AMOUNT);

        vm.startPrank(msg.sender);
        tokenA.approve(address(easydefi), AMOUNT);
        tokenB.approve(address(easydefi), AMOUNT);
        tokenC.approve(address(easydefi), AMOUNT);
        vm.stopPrank();

        vm.startPrank(USER_1);
        tokenA.approve(address(easydefi), AMOUNT);
        tokenB.approve(address(easydefi), AMOUNT);
        tokenC.approve(address(easydefi), AMOUNT);
        vm.stopPrank();
    }

    modifier prankOwner() {
        vm.startPrank(msg.sender);
        _;
        vm.stopPrank();
    }

    modifier prankOwnerCreatePool() {
        vm.startPrank(msg.sender);
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);
        vm.stopPrank();
        _;
    }

    ///////////////////////// GETTER AND UTILS /////////////////////////
    // function test_getAmountOut() public view {
    //     uint256 amountIn = 100 * 10 ** 18;
    //     uint256 reserveIn = 1000 * 10 ** 18;
    //     uint256 reserveOut = 1000 * 10 ** 18;

    //     uint256 amountInWithFee = amountIn * (BPS_DIVIDER - POOL_FEE);
    //     uint256 numerator = amountInWithFee * reserveOut;
    //     uint256 denominator = ((reserveIn * BPS_DIVIDER) + amountInWithFee);

    //     uint256 expectedResult = numerator / denominator;
    //     uint256 actualResult = easydefi.getAmountOut(
    //         amountIn,
    //         reserveIn,
    //         reserveOut,
    //         POOL_FEE
    //     );

    //     assertEq(expectedResult, actualResult);
    // }

    ///////////////////////// FEE COLLECTOR /////////////////////////
    function test_SetFeeCollectorZeroAddress() public prankOwner {
        vm.expectRevert();
        easydefi.setFeeCollector(address(0));
    }

    function test_SetFeeCollectorSameAddress() public prankOwner {
        address currentFeeCollector = USER_1;
        easydefi.setFeeCollector(currentFeeCollector);

        vm.expectRevert();
        easydefi.setFeeCollector(currentFeeCollector);
    }

    function test_SetFeeCollectorNonOwner() public {
        vm.startPrank(USER_1);
        vm.expectRevert();
        easydefi.setFeeCollector(address(1));
        vm.stopPrank();
    }

    function test_SetFeeCollectorSuccessful() public prankOwner {
        address newFeeCollector = USER_1;
        easydefi.setFeeCollector(newFeeCollector);
        // We would need a getter function to verify this
        // assertEq(easydefi.getFeeCollector(), newFeeCollector);
    }

    function test_ClaimFeeZeroAddress() public prankOwner {
        vm.expectRevert();
        easydefi.claimFee(address(0));
    }

    function test_ClaimFeeNoFeesToClaim() public prankOwner {
        vm.expectRevert();
        easydefi.claimFee(address(tokenA));
    }

    function test_ClaimFeeUser() public {
        vm.startPrank(USER_1);
        vm.expectRevert();
        easydefi.claimFee(address(tokenA));
        vm.stopPrank();
    }

    function test_ClaimFeeSuccessful() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;
        uint256 swapAmount = 100 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        easydefi.swap(address(tokenA), address(tokenB), swapAmount);
        vm.stopPrank();

        uint256 expectedFee = (swapAmount * POOL_FEE) / BPS_DIVIDER;
        assertEq(easydefi.feeCollected(address(tokenA)), expectedFee);

        uint256 feeCollectorBalanceBefore = tokenA.balanceOf(address(this));

        vm.prank(msg.sender);
        easydefi.claimFee(address(tokenA));

        uint256 feeCollectorBalanceAfter = tokenA.balanceOf(address(this));
        assertEq(feeCollectorBalanceAfter - feeCollectorBalanceBefore, expectedFee);
        assertEq(easydefi.feeCollected(address(tokenA)), 0);
    }

    function test_GetReservesNonExistantPool() public view {
        (uint256 reserveA, uint256 reserveB) = easydefi.getReserves(address(address(0)), address(tokenB));

        assertEq(reserveA, 0);
        assertEq(reserveB, 0);
    }

    function test_Sort() public view {
        address token0 = address(tokenA);
        address token1 = address(tokenB);

        (uint256 reserveA, uint256 reserveB) = easydefi.getReserves(token0, token1);

        (uint256 reserveAReverse, uint256 reserveBReverse) = easydefi.getReserves(token1, token0);

        assertEq(reserveA, reserveAReverse);
        assertEq(reserveB, reserveBReverse);
    }

    function test_PoolsList() public prankOwnerCreatePool {
        EasyDefi.Pool[] memory poolsList = easydefi.getPoolsList();
        assertEq(poolsList[0].tokenA, address(tokenA));
        assertEq(poolsList[0].tokenB, address(tokenB));
        assertEq(poolsList[0].reserveA, MINIMUM_LIQUIDITY);
        assertEq(poolsList[0].reserveB, MINIMUM_LIQUIDITY);
        assertEq(poolsList[0].fee, POOL_FEE);
    }

    ///////////////////////// POOL CREATION /////////////////////////
    function test_CreatePoolUser() public {
        vm.startPrank(USER_1);
        vm.expectRevert();
        easydefi.createPool(address(tokenA), address(tokenB), 10);
        vm.stopPrank();
    }

    function test_CreatePoolTokenAOrTokenBCantBeAddressZero() public prankOwner {
        vm.expectRevert();
        easydefi.createPool(address(tokenA), address(0), POOL_FEE);
    }

    function test_CreatePoolWithInvalidFee() public prankOwner {
        vm.expectRevert();
        easydefi.createPool(address(tokenA), address(tokenB), 100001);
    }

    function test_CreatePoolTokenACantBeEqualToTokenB() public prankOwner {
        vm.expectRevert();
        easydefi.createPool(address(tokenA), address(tokenA), POOL_FEE);
    }

    function test_CreatePoolAlreadyExist() public prankOwner {
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);
        vm.expectRevert();
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);
    }

    function test_createPoolIncrementPoolId() public prankOwner {
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);
        (address sortedA, address sortedB) = (address(tokenA) < address(tokenB))
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        uint256 currentId = easydefi.getPoolIds(address(sortedA), address(sortedB));

        assertEq(currentId, 1);

        easydefi.createPool(address(tokenB), address(tokenC), POOL_FEE);

        (address _sortedB, address sortedC) = (address(tokenB) < address(tokenC))
            ? (address(tokenB), address(tokenC))
            : (address(tokenC), address(tokenB));

        uint256 nextId = easydefi.getPoolIds(address(_sortedB), address(sortedC));

        assertEq(nextId, currentId + 1);
    }

    function test_CreatePoolUpdateMappings() public prankOwner {
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);

        uint256 _totalPoolShares = easydefi.totalPoolShares(1);
        assertEq(_totalPoolShares, MINIMUM_LIQUIDITY);
    }

    function test_CreatePoolPushPoolToStructAndMappingPoolExist() public prankOwner {
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);

        EasyDefi.Pool[] memory pools = easydefi.getPoolsList();
        EasyDefi.Pool memory pool = pools[0];

        assertEq(pool.fee, POOL_FEE);
    }

    function test_CreatePoolPushPoolToPoolList() public prankOwner {
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);
        EasyDefi.Pool[] memory poolsList = easydefi.getPoolsList();

        assertEq(poolsList.length, 1);
        assertEq(poolsList[0].tokenA, address(tokenA));
        assertEq(poolsList[0].tokenB, address(tokenB));
        assertEq(poolsList[0].reserveA, MINIMUM_LIQUIDITY);
        assertEq(poolsList[0].reserveB, MINIMUM_LIQUIDITY);
        assertEq(poolsList[0].fee, POOL_FEE);
    }

    function test_CreatePoolEmitEvent() public prankOwner {
        vm.expectEmit(false, false, false, true);
        emit PoolCreated(address(tokenA), address(tokenB), 1, 1);
        easydefi.createPool(address(tokenA), address(tokenB), POOL_FEE);
    }

    ///////////////////////// ADD LIQUIDITY /////////////////////////
    function test_AddLiquidityNonExistantPool() public {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        vm.expectRevert();
        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        vm.stopPrank();
    }

    function test_AddLiquidityRevertWithZeroAmounts() public prankOwnerCreatePool {
        vm.expectRevert();
        easydefi.addLiquidity(address(tokenA), address(tokenB), 0, 0);

        vm.expectRevert();
        easydefi.addLiquidity(address(tokenA), address(tokenB), 0, 10);

        vm.expectRevert();
        easydefi.addLiquidity(address(tokenA), address(tokenB), 10, 0);
    }

    function test_AddLiquidityTokensTransfers() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        uint256 userTokenABalanceBefore = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceBefore = tokenB.balanceOf(USER_1);

        uint256 contractTokenABalanceBefore = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceBefore = tokenB.balanceOf(address(easydefi));

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 userTokenABalanceAfter = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceAfter = tokenB.balanceOf(USER_1);

        uint256 contractTokenABalanceAfter = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceAfter = tokenB.balanceOf(address(easydefi));

        assertEq(userTokenABalanceAfter, userTokenABalanceBefore - amountA);
        assertEq(userTokenBBalanceAfter, userTokenBBalanceBefore - amountB);

        assertEq(contractTokenABalanceAfter, contractTokenABalanceBefore + amountA);
        assertEq(contractTokenBBalanceAfter, contractTokenBBalanceBefore + amountB);
    }

    function test_AddLiquidityOptimalAmountsCalculation() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 3000 * 10 ** 18;

        (uint256 optimalAmountA, uint256 optimalAmountB) =
            easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        assertEq(optimalAmountA, amountA);
        assertEq(optimalAmountB, amountA);

        vm.stopPrank();
    }

    function test_AddLiquidityUpdatePoolReserves() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        EasyDefi.Pool[] memory poolsBefore = easydefi.getPoolsList();
        EasyDefi.Pool memory poolBefore = poolsBefore[0];

        uint256 reserveABefore = poolBefore.reserveA;
        uint256 reserveBBefore = poolBefore.reserveB;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        EasyDefi.Pool[] memory poolsAfter = easydefi.getPoolsList();
        EasyDefi.Pool memory poolAfter = poolsAfter[0];

        uint256 reserveAAfter = poolAfter.reserveA;
        uint256 reserveBAfter = poolAfter.reserveB;

        assertEq(reserveAAfter, reserveABefore + amountA);
        assertEq(reserveBAfter, reserveBBefore + amountB);

        vm.stopPrank();
    }

    function test_AddLiquidityUpdateShares() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        uint256 totalPoolSharesBefore = easydefi.totalPoolShares(1);
        uint256 userSharesBefore = easydefi.shares(USER_1, 1);

        (uint256 reserveABefore,) = easydefi.getReserves(address(tokenA), address(tokenB));

        (uint256 optimalAmountA,) = easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 shares = (optimalAmountA * totalPoolSharesBefore) / reserveABefore;

        uint256 totalPoolSharesAfter = easydefi.totalPoolShares(1);
        uint256 userSharesAfter = easydefi.shares(USER_1, 1);

        assertEq(totalPoolSharesAfter, totalPoolSharesBefore + shares);
        assertEq(userSharesAfter - userSharesBefore, shares);

        vm.stopPrank();
    }

    function test_AddLiquidityEmitEvent() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        vm.expectEmit(false, false, false, true);
        emit LiquidityAdded(USER_1, address(tokenA), address(tokenB), amountA, amountB, 1);

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        vm.stopPrank();
    }

    ///////////////////////// REMOVE LIQUIDITY /////////////////////////
    function test_RemoveLiquidityNonExistantPool() public {
        vm.startPrank(USER_1);

        uint256 shares = 2000 * 10 ** 18;

        vm.expectRevert();
        easydefi.removeLiquidity(address(tokenA), address(tokenB), shares);

        vm.stopPrank();
    }

    function test_RemoveLiquidityWithoutShares() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 shares = 2000 * 10 ** 18;

        vm.expectRevert();

        easydefi.removeLiquidity(address(tokenA), address(tokenB), shares);

        vm.stopPrank();
    }

    function test_RemoveLiquidityAmountsOutCalculation() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 shares = easydefi.shares(USER_1, 1);
        uint256 totalShares = easydefi.totalPoolShares(1);

        EasyDefi.Pool[] memory pools = easydefi.getPoolsList();
        EasyDefi.Pool memory pool = pools[0];

        uint256 expectedAmountA = (shares * pool.reserveA) / totalShares;
        uint256 expectedAmountB = (shares * pool.reserveB) / totalShares;

        uint256 userTokenABalanceBefore = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceBefore = tokenB.balanceOf(USER_1);
        uint256 contractTokenABalanceBefore = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceBefore = tokenB.balanceOf(address(easydefi));

        easydefi.removeLiquidity(address(tokenA), address(tokenB), shares);

        uint256 userTokenABalanceAfter = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceAfter = tokenB.balanceOf(USER_1);
        uint256 contractTokenABalanceAfter = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceAfter = tokenB.balanceOf(address(easydefi));

        assertEq(userTokenABalanceAfter - userTokenABalanceBefore, expectedAmountA);
        assertEq(userTokenBBalanceAfter - userTokenBBalanceBefore, expectedAmountB);
        assertEq(contractTokenABalanceBefore - contractTokenABalanceAfter, expectedAmountA);
        assertEq(contractTokenBBalanceBefore - contractTokenBBalanceAfter, expectedAmountB);

        vm.stopPrank();
    }

    function test_RemoveLiquidityTokensTransfers() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 userTokenABalanceBefore = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceBefore = tokenB.balanceOf(USER_1);

        uint256 contractTokenABalanceBefore = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceBefore = tokenB.balanceOf(address(easydefi));

        uint256 shares = easydefi.shares(USER_1, 1);
        uint256 totalShares = easydefi.totalPoolShares(1);

        // Calculate expected withdrawal amounts based on shares
        uint256 expectedAmountA = (shares * contractTokenABalanceBefore) / totalShares;
        uint256 expectedAmountB = (shares * contractTokenBBalanceBefore) / totalShares;

        easydefi.removeLiquidity(address(tokenA), address(tokenB), shares);

        uint256 userTokenABalanceAfter = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceAfter = tokenB.balanceOf(USER_1);

        uint256 contractTokenABalanceAfter = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceAfter = tokenB.balanceOf(address(easydefi));

        assertEq(userTokenABalanceAfter, userTokenABalanceBefore + expectedAmountA);
        assertEq(userTokenBBalanceAfter, userTokenBBalanceBefore + expectedAmountB);

        assertEq(contractTokenABalanceAfter, contractTokenABalanceBefore - expectedAmountA);
        assertEq(contractTokenBBalanceAfter, contractTokenBBalanceBefore - expectedAmountB);

        vm.stopPrank();
    }

    function test_RemoveLiquidityUpdatePoolReserves() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        EasyDefi.Pool[] memory poolsBefore = easydefi.getPoolsList();
        EasyDefi.Pool memory poolBefore = poolsBefore[0];

        uint256 reserveABefore = poolBefore.reserveA;
        uint256 reserveBBefore = poolBefore.reserveB;

        uint256 shares = easydefi.shares(USER_1, 1);
        uint256 totalShares = easydefi.totalPoolShares(1);

        uint256 expectedAmountA = (shares * reserveABefore) / totalShares;
        uint256 expectedAmountB = (shares * reserveBBefore) / totalShares;

        easydefi.removeLiquidity(address(tokenA), address(tokenB), shares);

        EasyDefi.Pool[] memory poolsAfter = easydefi.getPoolsList();
        EasyDefi.Pool memory poolAfter = poolsAfter[0];

        uint256 reserveAAfter = poolAfter.reserveA;
        uint256 reserveBAfter = poolAfter.reserveB;

        assertEq(reserveAAfter, reserveABefore - expectedAmountA);
        assertEq(reserveBAfter, reserveBBefore - expectedAmountB);

        vm.stopPrank();
    }

    function test_RemoveLiquidityUpdateShares() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 totalPoolSharesBefore = easydefi.totalPoolShares(1);

        uint256 shares = easydefi.shares(USER_1, 1);

        easydefi.removeLiquidity(address(tokenA), address(tokenB), shares);

        uint256 totalPoolSharesAfter = easydefi.totalPoolShares(1);
        uint256 userSharesAfter = easydefi.shares(USER_1, 1);

        assertEq(totalPoolSharesAfter, totalPoolSharesBefore - shares);
        assertEq(userSharesAfter, 0);

        vm.stopPrank();
    }

    function test_RemoveLiquidityEmitEvent() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 shares = easydefi.shares(USER_1, 1);
        uint256 totalShares = easydefi.totalPoolShares(1);

        (uint256 reserveA, uint256 reserveB) = easydefi.getReserves(address(tokenA), address(tokenB));

        uint256 expectedAmountA = (shares * reserveA) / totalShares;
        uint256 expectedAmountB = (shares * reserveB) / totalShares;

        vm.expectEmit(false, false, false, true);
        emit LiquidityRemoved(USER_1, address(tokenA), address(tokenB), expectedAmountA, expectedAmountB, 1);
        easydefi.removeLiquidity(address(tokenA), address(tokenB), shares);

        vm.stopPrank();
    }

    ///////////////////////// SWAP /////////////////////////
    function test_SwapTokenAOrTokenBCantBeAddressZero() public prankOwnerCreatePool {
        uint256 amountIn = 100 * 10 ** 18;

        vm.expectRevert();
        easydefi.swap(address(tokenA), address(0), amountIn);
    }

    function test_SwapWithSameTokenAddresses() public prankOwnerCreatePool {
        uint256 amountIn = 100 * 10 ** 18;

        vm.expectRevert();
        easydefi.createPool(address(tokenA), address(tokenA), amountIn);
    }

    function test_SwapWithZeroAmountIn() public {
        vm.startPrank(USER_1);

        vm.expectRevert();
        easydefi.swap(address(tokenA), address(tokenB), 0);

        vm.stopPrank();
    }

    function test_SwapNonExistantPool() public {
        vm.startPrank(USER_1);

        uint256 amountA = 100 * 10 ** 18;

        vm.expectRevert();
        easydefi.swap(address(tokenA), address(tokenB), amountA);

        vm.stopPrank();
    }

    function test_SwapUpdateReserves() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountIn = 100 * 10 ** 18;

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        EasyDefi.Pool[] memory poolsBefore = easydefi.getPoolsList();
        EasyDefi.Pool memory poolBefore = poolsBefore[0];

        uint256 reserveABefore = poolBefore.reserveA;
        uint256 reserveBBefore = poolBefore.reserveB;
        uint256 fee = poolBefore.fee;

        uint256 feeAmount = (amountIn * fee) / BPS_DIVIDER;
        uint256 amountInAfterFee = amountIn - feeAmount;

        uint256 expectedAmountOut = easydefi.getAmountOut(amountInAfterFee, reserveABefore, reserveBBefore);

        easydefi.swap(address(tokenA), address(tokenB), amountIn);

        EasyDefi.Pool[] memory poolsAfter = easydefi.getPoolsList();
        EasyDefi.Pool memory poolAfter = poolsAfter[0];

        uint256 reserveAAfter = poolAfter.reserveA;
        uint256 reserveBAfter = poolAfter.reserveB;

        assertEq(reserveAAfter, reserveABefore + amountInAfterFee);
        assertEq(reserveBAfter, reserveBBefore - expectedAmountOut);

        vm.stopPrank();
    }

    function test_SwapTokenTransfers() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;
        uint256 amountIn = 100 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 userTokenABalanceBefore = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceBefore = tokenB.balanceOf(USER_1);
        uint256 contractTokenABalanceBefore = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceBefore = tokenB.balanceOf(address(easydefi));

        uint256 feeAmount = (amountIn * POOL_FEE) / BPS_DIVIDER;
        uint256 amountInAfterFee = amountIn - feeAmount;

        uint256 expectedAmountOut =
            easydefi.getAmountOut(amountInAfterFee, contractTokenABalanceBefore, contractTokenBBalanceBefore);

        easydefi.swap(address(tokenA), address(tokenB), amountIn);

        uint256 userTokenABalanceAfter = tokenA.balanceOf(USER_1);
        uint256 userTokenBBalanceAfter = tokenB.balanceOf(USER_1);
        uint256 contractTokenABalanceAfter = tokenA.balanceOf(address(easydefi));
        uint256 contractTokenBBalanceAfter = tokenB.balanceOf(address(easydefi));

        assertEq(userTokenABalanceBefore - userTokenABalanceAfter, amountIn);
        assertEq(userTokenBBalanceAfter - userTokenBBalanceBefore, expectedAmountOut);

        assertEq(contractTokenABalanceAfter - contractTokenABalanceBefore, amountIn);
        assertEq(contractTokenBBalanceBefore - contractTokenBBalanceAfter, expectedAmountOut);

        vm.stopPrank();
    }

    function test_SwapBothDirections() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        uint256 swapAmount = 100 * 10 ** 18;
        uint256 amountOut1 = easydefi.swap(address(tokenA), address(tokenB), swapAmount);
        assertGt(amountOut1, 0);

        uint256 amountOut2 = easydefi.swap(address(tokenB), address(tokenA), swapAmount);
        assertGt(amountOut2, 0);

        vm.stopPrank();
    }

    function test_AddLiquidityBothPaths() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountA1 = 2000 * 10 ** 18;
        uint256 amountB1 = 3000 * 10 ** 18;
        (uint256 optimalA1, uint256 optimalB1) =
            easydefi.addLiquidity(address(tokenA), address(tokenB), amountA1, amountB1);
        assertEq(optimalA1, amountA1);
        assertLt(optimalB1, amountB1);

        uint256 amountA2 = 3000 * 10 ** 18;
        uint256 amountB2 = 2000 * 10 ** 18;
        (uint256 optimalA2, uint256 optimalB2) =
            easydefi.addLiquidity(address(tokenA), address(tokenB), amountA2, amountB2);
        assertLt(optimalA2, amountA2);
        assertEq(optimalB2, amountB2);

        vm.stopPrank();
    }

    function test_SwapEmitEvent() public prankOwnerCreatePool {
        vm.startPrank(USER_1);

        uint256 amountIn = 100 * 10 ** 18;

        uint256 amountA = 2000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        easydefi.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);

        EasyDefi.Pool[] memory pools = easydefi.getPoolsList();
        EasyDefi.Pool memory pool = pools[0];

        uint256 reserveA = pool.reserveA;
        uint256 reserveB = pool.reserveB;
        uint256 fee = pool.fee;

        uint256 feeAmount = (amountIn * fee) / BPS_DIVIDER;
        uint256 amountInAfterFee = amountIn - feeAmount;

        uint256 expectedAmountOut = easydefi.getAmountOut(amountInAfterFee, reserveA, reserveB);

        vm.expectEmit(false, false, false, true);
        emit Swap(USER_1, address(tokenA), address(tokenB), amountIn, expectedAmountOut, 1);
        easydefi.swap(address(tokenA), address(tokenB), amountIn);
        vm.stopPrank();
    }
}
