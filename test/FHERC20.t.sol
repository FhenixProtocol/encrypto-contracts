// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FHERC20, FHERC20_Harness} from "./FHERC20_Harness.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {SigUtils} from "./SigUtils.sol";

contract FHERC20Test is Test, IERC20Errors {
    // USERS

    address public deployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address public sender = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address public dead = 0x000000000000000000000000000000000000dEaD;

    address payable public bob;
    uint256 public bobPK;
    address payable public alice;
    uint256 public alicePK;
    address payable public carol = payable(address(102));
    address payable public eve = payable(address(103));
    address payable[4] public users;

    SigUtils internal sigUtils;

    function initUsers() public {
        (address bobTemp, uint256 bobPKTemp) = makeAddrAndKey("bob");
        (address aliceTemp, uint256 alicePKTemp) = makeAddrAndKey("alice");
        bob = payable(bobTemp);
        bobPK = bobPKTemp;
        alice = payable(aliceTemp);
        alicePK = alicePKTemp;
        users = [bob, alice, carol, eve];
    }

    // LABELS

    function label() public {
        vm.label(deployer, "deployer");
        vm.label(sender, "sender");
        vm.label(dead, "dead");

        vm.label(bob, "bob");
        vm.label(alice, "alice");
        vm.label(carol, "carol");
        vm.label(eve, "eve");

        vm.label(address(sigUtils), "sigUtils");

        vm.label(address(XXX), "XXX");
    }

    // TOKEN

    FHERC20_Harness public XXX;
    string public xxxName = "Test FHERC20 XXX";
    string public xxxSymbol = "eXXX";
    uint8 public xxxDecimals = 18;

    // SETUP

    function setUp() public {
        initUsers();

        XXX = new FHERC20_Harness(xxxName, xxxSymbol, xxxDecimals);
        sigUtils = new SigUtils();

        label();
    }

    // UTILS

    function formatWithDecimals(
        int256 value,
        uint8 decimals,
        uint8 decimalsToShow
    ) public pure returns (string memory) {
        require(decimalsToShow <= decimals, "Too many decimals to show");

        // Handle sign
        bool isNegative = value < 0;
        uint256 absValue = isNegative ? uint256(-value) : uint256(value);

        // Factor for rounding (10^(decimals - decimalsToShow))
        uint256 roundFactor = 10 ** (decimals - decimalsToShow);
        uint256 roundedValue = (absValue + roundFactor / 2) / roundFactor; // Apply rounding

        // Convert rounded value to string
        string memory strValue = Strings.toString(roundedValue);
        bytes memory strBytes = bytes(strValue);
        uint256 len = strBytes.length;

        if (decimalsToShow == 0) {
            return
                isNegative ? string(abi.encodePacked("-", strValue)) : strValue; // No decimal places required
        }

        if (len <= decimalsToShow) {
            // Add leading zeros for small values
            string memory leadingZeros = new string(decimalsToShow - len + 2); // "0."
            bytes memory leadingBytes = bytes(leadingZeros);
            leadingBytes[0] = "0";
            leadingBytes[1] = ".";
            for (uint256 i = 2; i < leadingBytes.length; i++) {
                leadingBytes[i] = "0";
            }
            return
                isNegative
                    ? string(
                        abi.encodePacked("-", string(leadingBytes), strValue)
                    )
                    : string(abi.encodePacked(string(leadingBytes), strValue));
        } else {
            uint256 integerPartLength = len - decimalsToShow;
            bytes memory result = new bytes(len + 1);

            for (uint256 i = 0; i < integerPartLength; i++) {
                result[i] = strBytes[i];
            }

            result[integerPartLength] = ".";

            for (uint256 i = integerPartLength; i < len; i++) {
                result[i + 1] = strBytes[i];
            }

            return
                isNegative
                    ? string(abi.encodePacked("-", string(result)))
                    : string(result);
        }
    }

    function formatIndicatedValue(
        FHERC20 token,
        int256 value
    ) public view returns (string memory) {
        return formatWithDecimals(value, token.decimals(), 4);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function _expectFHERC20Transfer(
        FHERC20 token,
        address from,
        address to
    ) public {
        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(from, to, token.indicatorTick());
    }

    function _ticksToIndicated(
        FHERC20 token,
        int256 ticks
    ) public view returns (int256) {
        return ticks * int256(token.indicatorTick());
    }

    mapping(address user => uint256 balance) public indicatedBalances;
    mapping(address user => uint256 balance) public trueBalances;

    function _prepExpectFHERC20BalancesChange(
        FHERC20 token,
        address account
    ) public {
        indicatedBalances[account] = token.balanceOf(account);
        trueBalances[account] = token.encBalanceOf(account);
    }
    function _expectFHERC20BalancesChange(
        FHERC20 token,
        address account,
        int256 expectedIndicatedChange,
        int256 expectedTrueChange
    ) public view {
        uint256 currIndicated = token.balanceOf(account);
        int256 indicatedChange = int256(currIndicated) -
            int256(indicatedBalances[account]);

        assertEq(
            expectedIndicatedChange,
            indicatedChange,
            string.concat(
                token.symbol(),
                " expected INDICATED balance change incorrect. Expected: ",
                formatIndicatedValue(token, expectedIndicatedChange),
                ", received: ",
                formatIndicatedValue(token, indicatedChange)
            )
        );

        uint256 currTrue = token.encBalanceOf(account);
        int256 trueChange = int256(currTrue) - int256(trueBalances[account]);

        assertEq(
            expectedTrueChange,
            trueChange,
            string.concat(
                token.symbol(),
                " expected TRUE balance change incorrect. Expected: ",
                Strings.toStringSigned(expectedTrueChange),
                ", received: ",
                Strings.toStringSigned(trueChange)
            )
        );
    }

    function generateTransferFromPermit(
        FHERC20 token,
        uint256 privateKey,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) public view returns (FHERC20.FHERC20_EIP712_Permit memory permit) {
        SigUtils.Permit memory sigUtilsPermit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: value,
            nonce: nonce,
            deadline: block.timestamp + deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(
            token.DOMAIN_SEPARATOR(),
            sigUtilsPermit
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        permit = FHERC20.FHERC20_EIP712_Permit({
            owner: owner,
            spender: spender,
            value: value,
            deadline: block.timestamp + deadline,
            v: v,
            r: r,
            s: s
        });
    }

    function generateTransferFromPermit(
        FHERC20 token,
        uint256 privateKey,
        address owner,
        address spender,
        uint256 value
    ) public view returns (FHERC20.FHERC20_EIP712_Permit memory permit) {
        permit = generateTransferFromPermit(
            token,
            privateKey,
            owner,
            spender,
            value,
            token.nonces(owner),
            1 days
        );
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
