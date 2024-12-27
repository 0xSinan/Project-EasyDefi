// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {LiquidAlyraToken} from "../../src/LiquidAlyraToken.sol";
import {AlyraToken} from "../../src/AlyraToken.sol";
import {DeployTokens} from "../../script/DeployTokens.s.sol";

contract TokensTest is Test {
    LiquidAlyraToken liquidToken;
    AlyraToken alyraToken;

    address USER_1 = makeAddr("user_1");
    address USER_2 = makeAddr("user_2");

    uint256 constant INITIAL_SUPPLY = 10000000000000000000 * 10 ** 18;
    uint256 constant TRANSFER_AMOUNT = 1000 * 10 ** 18;

    function setUp() external {
        DeployTokens deployTokens = new DeployTokens();
        (alyraToken, liquidToken) = deployTokens.run();
    }

    modifier prankOwner() {
        vm.startPrank(msg.sender);
        _;
        vm.stopPrank();
    }

    ///////////////////////// LIQUID ALYRA TOKEN /////////////////////////
    function test_LiquidTokenInitialSupply() public view {
        assertEq(liquidToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(liquidToken.balanceOf(msg.sender), INITIAL_SUPPLY);
    }

    function test_LiquidTokenName() public view {
        assertEq(liquidToken.name(), "LiquidAlyraToken");
    }

    function test_LiquidTokenSymbol() public view {
        assertEq(liquidToken.symbol(), "sALYRA");
    }

    function test_LiquidTokenTransfer() public prankOwner {
        uint256 balanceBefore = liquidToken.balanceOf(USER_1);

        liquidToken.transfer(USER_1, TRANSFER_AMOUNT);

        uint256 balanceAfter = liquidToken.balanceOf(USER_1);
        assertEq(balanceAfter - balanceBefore, TRANSFER_AMOUNT);
    }

    function test_LiquidTokenTransferFrom() public {
        vm.startPrank(msg.sender);
        liquidToken.approve(USER_1, TRANSFER_AMOUNT);
        vm.stopPrank();

        vm.startPrank(USER_1);
        liquidToken.transferFrom(msg.sender, USER_2, TRANSFER_AMOUNT);

        assertEq(liquidToken.balanceOf(USER_2), TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    ///////////////////////// ALYRA TOKEN /////////////////////////
    function test_AlyraTokenInitialSupply() public view {
        assertEq(alyraToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(alyraToken.balanceOf(msg.sender), INITIAL_SUPPLY);
    }

    function test_AlyraTokenName() public view {
        assertEq(alyraToken.name(), "AlyraToken");
    }

    function test_AlyraTokenSymbol() public view {
        assertEq(alyraToken.symbol(), "ALYRA");
    }

    function test_AlyraTokenDecimals() public view {
        assertEq(alyraToken.decimals(), 18);
    }

    function test_AlyraTokenTransfer() public prankOwner {
        uint256 balanceBefore = alyraToken.balanceOf(USER_1);

        alyraToken.transfer(USER_1, TRANSFER_AMOUNT);

        uint256 balanceAfter = alyraToken.balanceOf(USER_1);
        assertEq(balanceAfter - balanceBefore, TRANSFER_AMOUNT);
    }

    function test_AlyraTokenTransferFrom() public {
        vm.startPrank(msg.sender);
        alyraToken.approve(USER_1, TRANSFER_AMOUNT);
        vm.stopPrank();

        vm.startPrank(USER_1);
        alyraToken.transferFrom(msg.sender, USER_2, TRANSFER_AMOUNT);

        assertEq(alyraToken.balanceOf(USER_2), TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    ///////////////////////// APPROVAL TESTS /////////////////////////
    function test_LiquidTokenApproval() public {
        vm.startPrank(msg.sender);
        liquidToken.approve(USER_1, TRANSFER_AMOUNT);
        assertEq(liquidToken.allowance(msg.sender, USER_1), TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    function test_AlyraTokenApproval() public {
        vm.startPrank(msg.sender);
        alyraToken.approve(USER_1, TRANSFER_AMOUNT);
        assertEq(alyraToken.allowance(msg.sender, USER_1), TRANSFER_AMOUNT);
        vm.stopPrank();
    }
}
