// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {FHERC20} from "./FHERC20_Harness.sol";
import {ERC20_Harness} from "./ERC20_Harness.sol";
import {ConfidentialETH} from "../src/ConfidentialETH.sol";
import {TestSetup} from "./TestSetup.sol";

contract ConfidentialETHTest is TestSetup {
    IWETH public wETH;
    ConfidentialETH public eETH;

    function setUp() public override {
        super.setUp();

        wETH = new WETH_Harness();
        vm.label(address(wETH), "wETH");

        eETH = new ConfidentialETH(wETH);
        vm.label(address(eETH), "eETH");
    }

    // TESTS

    function test_Constructor() public view {
        assertEq(
            eETH.name(),
            "Confidential Wrapped ETHER",
            "ConfidentialETH name correct"
        );
        assertEq(eETH.symbol(), "eETH", "ConfidentialETH symbol correct");
        assertEq(eETH.decimals(), 8, "ConfidentialETH decimals correct");
        assertEq(
            address(eETH.erc20()),
            address(wETH),
            "ConfidentialETH underlying ERC20 correct"
        );
    }

    function test_FHERC20InvalidErc20() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfidentialETH.FHERC20InvalidErc20.selector,
                address(eETH)
            )
        );
        new ConfidentialETH(eETH, "eETH");
    }

    function test_isFherc20() public {
        assertEq(eETH.isFherc20(), true, "eETH is FHERC20");
    }

    function test_Symbol() public {
        ERC20_Harness TEST = new ERC20_Harness("Test Token", "TEST", 18);
        ConfidentialETH eTEST = new ConfidentialETH(TEST, "");

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
        assertEq(eETH.totalSupply(), 0, "Total supply init 0");

        // Mint wETH
        wETH.mint(bob, 10e8);
        vm.prank(bob);
        wETH.approve(address(eETH), 10e8);

        // 1st TX, indicated + 5001, true + 1e8

        uint256 value = 1e8;

        _prepExpectERC20BalancesChange(wETH, bob);
        _prepExpectFHERC20BalancesChange(eETH, bob);

        _expectERC20Transfer(wETH, bob, address(eETH), value);
        _expectFHERC20Transfer(eETH, address(0), bob);

        vm.prank(bob);
        eETH.encrypt(bob, uint128(value));

        _expectERC20BalancesChange(wETH, bob, -1 * int256(value));
        _expectFHERC20BalancesChange(
            eETH,
            bob,
            _ticksToIndicated(eETH, 5001),
            int256(value)
        );

        assertEq(eETH.totalSupply(), value, "Total supply increases");

        // 2nd TX, indicated + 1, true + 1e8

        _prepExpectERC20BalancesChange(wETH, bob);
        _prepExpectFHERC20BalancesChange(eETH, bob);

        _expectERC20Transfer(wETH, bob, address(eETH), value);
        _expectFHERC20Transfer(eETH, address(0), bob);

        vm.prank(bob);
        eETH.encrypt(bob, uint128(value));

        _expectERC20BalancesChange(wETH, bob, -1 * int256(value));
        _expectFHERC20BalancesChange(
            eETH,
            bob,
            _ticksToIndicated(eETH, 1),
            int256(value)
        );
    }

    function test_decrypt() public {
        assertEq(eETH.totalSupply(), 0, "Total supply init 0");

        // Mint and encrypt wETH
        wETH.mint(bob, 10e8);
        vm.prank(bob);
        wETH.approve(address(eETH), 10e8);
        vm.prank(bob);
        eETH.encrypt(bob, 10e8);

        // TX

        uint256 value = 1e8;

        _prepExpectERC20BalancesChange(wETH, bob);
        _prepExpectFHERC20BalancesChange(eETH, bob);

        _expectFHERC20Transfer(eETH, bob, address(0));
        _expectERC20Transfer(wETH, address(eETH), bob, value);

        vm.prank(bob);
        eETH.decrypt(bob, uint128(value));

        _expectERC20BalancesChange(wETH, bob, int256(value));
        _expectFHERC20BalancesChange(
            eETH,
            bob,
            -1 * _ticksToIndicated(eETH, 1),
            -1 * int256(value)
        );

        assertEq(eETH.totalSupply(), 10e8 - value, "Total supply decreases");
    }
}
