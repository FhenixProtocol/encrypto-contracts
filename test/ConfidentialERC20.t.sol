// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {FHERC20} from "./FHERC20_Harness.sol";
import {ERC20_Harness} from "./ERC20_Harness.sol";
import {ConfidentialERC20} from "../src/ConfidentialERC20NonFHE.sol";
import {TestSetup} from "./TestSetup.sol";

contract FHERC20Test is TestSetup {
    function setUp() public override {
        super.setUp();
    }

    // TESTS

    function test_Constructor() public view {
        assertEq(
            eBTC.name(),
            "Confidential Wrapped BTC",
            "ConfidentialERC20 name correct"
        );
        assertEq(eBTC.symbol(), "eBTC", "ConfidentialERC20 symbol correct");
        assertEq(eBTC.decimals(), 8, "ConfidentialERC20 decimals correct");
        assertEq(
            address(eBTC.erc20()),
            address(wBTC),
            "ConfidentialERC20 underlying ERC20 correct"
        );
    }

    function test_Symbol() public {
        ERC20_Harness TEST = new ERC20_Harness("Test Token", "TEST", 18);
        ConfidentialERC20 eTEST = new ConfidentialERC20(TEST, "");

        assertEq(eTEST.name(), "Confidential Test Token", "eTEST name correct");
        assertEq(eTEST.symbol(), "eTEST", "eTEST symbol correct");
        assertEq(eTEST.decimals(), TEST.decimals(), "eTEST decimals correct");
        assertEq(
            address(eTEST.erc20()),
            address(TEST),
            "eTEST underlying ERC20 correct"
        );

        eTEST.updateSymbol("encTEST");
        assertEq(eTEST.symbol(), "encTEST", "eTEST symbol updated correct");
    }

    function test_encrypt() public {
        assertEq(eBTC.totalSupply(), 0, "Total supply init 0");

        // Mint wBTC
        wBTC.mint(bob, 10e8);
        vm.prank(bob);
        wBTC.approve(address(eBTC), 10e8);

        // 1st TX, indicated + 5001, true + 1e8

        uint256 value = 1e8;

        _prepExpectERC20BalancesChange(wBTC, bob);
        _prepExpectFHERC20BalancesChange(eBTC, bob);

        _expectERC20Transfer(wBTC, bob, address(eBTC), value);
        _expectFHERC20Transfer(eBTC, address(0), bob);

        vm.prank(bob);
        eBTC.encrypt(bob, uint128(value));

        _expectERC20BalancesChange(wBTC, bob, -1 * int256(value));
        _expectFHERC20BalancesChange(
            eBTC,
            bob,
            _ticksToIndicated(eBTC, 5001),
            int256(value)
        );

        assertEq(eBTC.totalSupply(), value, "Total supply increases");

        // 2nd TX, indicated + 1, true + 1e8

        _prepExpectERC20BalancesChange(wBTC, bob);
        _prepExpectFHERC20BalancesChange(eBTC, bob);

        _expectERC20Transfer(wBTC, bob, address(eBTC), value);
        _expectFHERC20Transfer(eBTC, address(0), bob);

        vm.prank(bob);
        eBTC.encrypt(bob, uint128(value));

        _expectERC20BalancesChange(wBTC, bob, -1 * int256(value));
        _expectFHERC20BalancesChange(
            eBTC,
            bob,
            _ticksToIndicated(eBTC, 1),
            int256(value)
        );
    }

    function test_decrypt() public {
        assertEq(eBTC.totalSupply(), 0, "Total supply init 0");

        // Mint and encrypt wBTC
        wBTC.mint(bob, 10e8);
        vm.prank(bob);
        wBTC.approve(address(eBTC), 10e8);
        vm.prank(bob);
        eBTC.encrypt(bob, 10e8);

        // TX

        uint256 value = 1e8;

        _prepExpectERC20BalancesChange(wBTC, bob);
        _prepExpectFHERC20BalancesChange(eBTC, bob);

        _expectFHERC20Transfer(eBTC, bob, address(0));
        _expectERC20Transfer(wBTC, address(eBTC), bob, value);

        vm.prank(bob);
        eBTC.decrypt(bob, uint128(value));

        _expectERC20BalancesChange(wBTC, bob, int256(value));
        _expectFHERC20BalancesChange(
            eBTC,
            bob,
            -1 * _ticksToIndicated(eBTC, 1),
            -1 * int256(value)
        );

        assertEq(eBTC.totalSupply(), 10e8 - value, "Total supply decreases");
    }
}
