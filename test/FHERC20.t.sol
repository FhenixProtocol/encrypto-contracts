// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {FHERC20} from "./FHERC20_Harness.sol";
import {TestSetup} from "./TestSetup.sol";

contract FHERC20Test is TestSetup {
    function setUp() public override {
        super.setUp();
    }

    // TESTS

    function test_Constructor() public view {
        assertEq(XXX.name(), xxxName, "FHERC20 name correct");
        assertEq(XXX.symbol(), xxxSymbol, "FHERC20 symbol correct");
        assertEq(XXX.decimals(), xxxDecimals, "FHERC20 decimals correct");
        assertEq(
            XXX.balanceOfIsIndicator(),
            true,
            "FHERC20 balanceOfIsIndicator is true"
        );
        assertEq(
            XXX.indicatorTick(),
            10 ** (xxxDecimals - 4),
            "FHERC20 indicatorTick correct"
        );
    }

    function test_Mint() public {
        assertEq(XXX.totalSupply(), 0, "Total supply init 0");

        // 1st TX, indicated + 5001, true + 1e18

        uint256 value = 1e18;

        _prepExpectFHERC20BalancesChange(XXX, bob);

        _expectFHERC20Transfer(XXX, address(0), bob);
        XXX.mint(bob, value);

        _expectFHERC20BalancesChange(
            XXX,
            bob,
            _ticksToIndicated(XXX, 5001),
            int256(value)
        );

        assertEq(XXX.totalSupply(), value, "Total supply increases");

        // 2nd TX, indicated + 1, true + 1e18

        _prepExpectFHERC20BalancesChange(XXX, bob);

        _expectFHERC20Transfer(XXX, address(0), bob);
        XXX.mint(bob, value);

        _expectFHERC20BalancesChange(
            XXX,
            bob,
            _ticksToIndicated(XXX, 1),
            int256(value)
        );

        // Revert

        vm.expectPartialRevert(ERC20InvalidReceiver.selector);
        XXX.mint(address(0), value);
    }

    function test_Burn() public {
        XXX.mint(bob, 10e18);

        // 1st TX, indicated - 1, true - 1e18

        assertEq(XXX.totalSupply(), 10e18, "Total supply init 10e18");

        _prepExpectFHERC20BalancesChange(XXX, bob);

        _expectFHERC20Transfer(XXX, bob, address(0));
        XXX.burn(bob, 1e18);

        _expectFHERC20BalancesChange(
            XXX,
            bob,
            -1 * _ticksToIndicated(XXX, 1),
            -1 * 1e18
        );

        assertEq(XXX.totalSupply(), 9e18, "Total supply reduced by 1e18");

        // Revert

        vm.expectPartialRevert(ERC20InvalidSender.selector);
        XXX.burn(address(0), 1e18);
    }

    function test_ERC20FunctionsRevert() public {
        XXX.mint(bob, 10e18);
        XXX.mint(alice, 10e18);

        // Transfer

        vm.expectRevert(FHERC20.FHERC20IncompatibleFunction.selector);
        vm.prank(bob);
        XXX.transfer(alice, 1e18);

        // TransferFrom

        vm.expectRevert(FHERC20.FHERC20IncompatibleFunction.selector);
        vm.prank(bob);
        XXX.transferFrom(alice, bob, 1e18);

        // Approve

        vm.expectRevert(FHERC20.FHERC20IncompatibleFunction.selector);
        vm.prank(bob);
        XXX.approve(alice, 1e18);

        // Allowance

        vm.expectRevert(FHERC20.FHERC20IncompatibleFunction.selector);
        XXX.allowance(bob, alice);
    }

    function test_EncTransfer() public {
        XXX.mint(bob, 10e18);
        XXX.mint(alice, 10e18);

        // Reversion - Transfer to 0 address

        vm.expectRevert(
            abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(0))
        );
        vm.prank(bob);
        XXX.encTransfer(address(0), 1e18);

        // Success

        _prepExpectFHERC20BalancesChange(XXX, bob);
        _prepExpectFHERC20BalancesChange(XXX, alice);

        _expectFHERC20Transfer(XXX, bob, alice);
        vm.prank(bob);
        XXX.encTransfer(alice, 1e18);

        _expectFHERC20BalancesChange(
            XXX,
            bob,
            -1 * _ticksToIndicated(XXX, 1),
            -1 * 1e18
        );
        _expectFHERC20BalancesChange(
            XXX,
            alice,
            _ticksToIndicated(XXX, 1),
            1e18
        );
    }

    function test_EncTransferFrom() public {
        XXX.mint(bob, 10e18);
        XXX.mint(alice, 10e18);
        FHERC20.FHERC20_EIP712_Permit memory permit;

        // Reversion - Transfer from 0 address

        permit = generateTransferFromPermit(XXX, bobPK, bob, address(0), 1e18);

        vm.expectRevert(
            abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(0))
        );
        vm.prank(bob);
        XXX.encTransferFrom(bob, address(0), 1e18, permit);

        // Success - Bob -> Alice (called by Bob, nonce = 0)

        permit = generateTransferFromPermit(XXX, bobPK, bob, alice, 1e18);

        _prepExpectFHERC20BalancesChange(XXX, bob);
        _prepExpectFHERC20BalancesChange(XXX, alice);

        _expectFHERC20Transfer(XXX, bob, alice);
        XXX.encTransferFrom(bob, alice, 1e18, permit);

        _expectFHERC20BalancesChange(
            XXX,
            bob,
            -1 * _ticksToIndicated(XXX, 1),
            -1 * 1e18
        );
        _expectFHERC20BalancesChange(
            XXX,
            alice,
            _ticksToIndicated(XXX, 1),
            1e18
        );

        // Success - Bob -> Alice (called by Bob, nonce = 1)

        permit = generateTransferFromPermit(XXX, bobPK, bob, alice, 1e18);

        _prepExpectFHERC20BalancesChange(XXX, bob);
        _prepExpectFHERC20BalancesChange(XXX, alice);

        _expectFHERC20Transfer(XXX, bob, alice);
        XXX.encTransferFrom(bob, alice, 1e18, permit);

        _expectFHERC20BalancesChange(
            XXX,
            bob,
            -1 * _ticksToIndicated(XXX, 1),
            -1 * 1e18
        );
        _expectFHERC20BalancesChange(
            XXX,
            alice,
            _ticksToIndicated(XXX, 1),
            1e18
        );

        // Success - Alice -> Bob (called by Bob)

        permit = generateTransferFromPermit(XXX, alicePK, alice, bob, 1e18);

        _prepExpectFHERC20BalancesChange(XXX, alice);
        _prepExpectFHERC20BalancesChange(XXX, bob);

        _expectFHERC20Transfer(XXX, alice, bob);
        XXX.encTransferFrom(alice, bob, 1e18, permit);

        _expectFHERC20BalancesChange(
            XXX,
            alice,
            -1 * _ticksToIndicated(XXX, 1),
            -1 * 1e18
        );
        _expectFHERC20BalancesChange(
            XXX,
            bob,
            1 * _ticksToIndicated(XXX, 1),
            1 * 1e18
        );
    }

    function test_EncTransferFrom_PermitReversions() public {
        XXX.mint(bob, 10e18);
        XXX.mint(alice, 10e18);
        FHERC20.FHERC20_EIP712_Permit memory permit;

        // Valid

        permit = generateTransferFromPermit(XXX, bobPK, bob, alice, 1e18);
        XXX.encTransferFrom(bob, alice, 1e18, permit);

        // Deadline passed - ERC2612ExpiredSignature

        permit = generateTransferFromPermit(
            XXX,
            bobPK,
            bob,
            alice,
            1e18,
            XXX.nonces(bob),
            0
        );
        vm.warp(block.timestamp + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                FHERC20.ERC2612ExpiredSignature.selector,
                permit.deadline
            )
        );
        XXX.encTransferFrom(bob, alice, 1e18, permit);

        // FHERC20EncTransferFromOwnerMismatch bob -> eve

        permit = generateTransferFromPermit(XXX, bobPK, eve, alice, 1e18);
        vm.expectRevert(
            abi.encodeWithSelector(
                FHERC20.FHERC20EncTransferFromOwnerMismatch.selector,
                bob,
                eve
            )
        );
        XXX.encTransferFrom(bob, alice, 1e18, permit);

        // FHERC20EncTransferFromOwnerMismatch eve -> bob

        permit = generateTransferFromPermit(XXX, bobPK, bob, alice, 1e18);
        vm.expectRevert(
            abi.encodeWithSelector(
                FHERC20.FHERC20EncTransferFromOwnerMismatch.selector,
                eve,
                bob
            )
        );
        XXX.encTransferFrom(eve, alice, 1e18, permit);

        // FHERC20EncTransferFromSpenderMismatch

        permit = generateTransferFromPermit(XXX, bobPK, bob, alice, 1e18);
        vm.expectRevert(
            abi.encodeWithSelector(
                FHERC20.FHERC20EncTransferFromSpenderMismatch.selector,
                eve,
                alice
            )
        );
        XXX.encTransferFrom(bob, eve, 1e18, permit);

        // FHERC20EncTransferFromValueMismatch

        permit = generateTransferFromPermit(XXX, bobPK, bob, alice, 1e18);
        vm.expectRevert(
            abi.encodeWithSelector(
                FHERC20.FHERC20EncTransferFromValueMismatch.selector,
                2e18,
                1e18
            )
        );
        XXX.encTransferFrom(bob, alice, 2e18, permit);

        // Signer != owner - ERC2612InvalidSigner

        permit = generateTransferFromPermit(XXX, alicePK, bob, alice, 1e18);
        vm.expectRevert(
            abi.encodeWithSelector(
                FHERC20.ERC2612InvalidSigner.selector,
                alice,
                bob
            )
        );
        XXX.encTransferFrom(bob, alice, 1e18, permit);

        // Invalid nonce - ERC2612InvalidSigner

        permit = generateTransferFromPermit(
            XXX,
            bobPK,
            bob,
            alice,
            1e18,
            XXX.nonces(bob) - 1,
            1 days
        );
        vm.expectPartialRevert(FHERC20.ERC2612InvalidSigner.selector);
        XXX.encTransferFrom(bob, alice, 1e18, permit);
    }
}
