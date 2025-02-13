// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-foundry-mocks/CoFheTest.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract ExampleFHECounter is IAsyncFHEReceiver {
    euint32 public eNumber;
    mapping(uint256 ctHash => uint256) public decryptedRes;
    mapping(uint256 ctHash => string) public sealedRes;

    function setNumber(inEuint32 memory inNumber) public {
        eNumber = FHE.asEuint32(inNumber);
        FHE.allowThis(eNumber);
    }

    function increment() public {
        eNumber = FHE.add(eNumber, FHE.asEuint32(1));
        FHE.allowThis(eNumber);
    }

    function add(inEuint32 memory inNumber) public {
        eNumber = FHE.add(eNumber, FHE.asEuint32(inNumber));
        FHE.allowThis(eNumber);
    }

    function sub(inEuint32 memory inNumber) public {
        euint32 inAsEuint32 = FHE.asEuint32(inNumber);
        euint32 eSubOrZero = FHE.select(
            FHE.lte(inAsEuint32, eNumber),
            inAsEuint32,
            FHE.asEuint32(0)
        );
        eNumber = FHE.sub(eNumber, eSubOrZero);
        FHE.allowThis(eNumber);
    }

    function mul(inEuint32 memory inNumber) public {
        eNumber = FHE.mul(eNumber, FHE.asEuint32(inNumber));
        FHE.allowThis(eNumber);
    }

    function decrypt() public {
        FHE.decrypt(eNumber);
    }

    function sealoutput(bytes32 publicKey) public {
        FHE.sealoutput(eNumber, publicKey);
    }

    function handleDecryptResult(
        uint256 ctHash,
        uint256 result,
        address
    ) external override {
        decryptedRes[ctHash] = result;
    }

    function handleSealOutputResult(
        uint256 ctHash,
        string memory result,
        address
    ) external override {
        sealedRes[ctHash] = result;
    }
}

contract ExampleFHECounterTest is Test {
    CoFheTest CFT;

    ExampleFHECounter public counter;

    function setUp() public {
        CFT = new CoFheTest();

        counter = new ExampleFHECounter();

        // Set number to 5
        inEuint32 memory inNumber = CFT.createInEuint32(5);
        counter.setNumber(inNumber);
    }

    function test_setNumber() public {
        inEuint32 memory inNumber = CFT.createInEuint32(10);
        counter.setNumber(inNumber);
        CFT.assertStoredValue(counter.eNumber(), 10);
    }

    function test_increment() public {
        counter.increment();
        CFT.assertStoredValue(counter.eNumber(), 6);
    }

    function test_add() public {
        inEuint32 memory inNumber = CFT.createInEuint32(2);
        counter.add(inNumber);
        CFT.assertStoredValue(counter.eNumber(), 7);
    }

    function test_sub() public {
        inEuint32 memory inNumber = CFT.createInEuint32(3);
        counter.sub(inNumber);
        CFT.assertStoredValue(counter.eNumber(), 2);
    }

    function test_mul() public {
        inEuint32 memory inNumber = CFT.createInEuint32(2);
        counter.mul(inNumber);
        CFT.assertStoredValue(counter.eNumber(), 10);
    }

    function test_decrypt() public {
        CFT.assertStoredValue(counter.eNumber(), 5);
        counter.decrypt();
        assertEq(counter.decryptedRes(euint32.unwrap(counter.eNumber())), 5);
    }

    function test_sealoutput() public {
        CFT.assertStoredValue(counter.eNumber(), 5);

        bytes32 publicKey = bytes32("0xFakePublicKey");

        counter.sealoutput(publicKey);

        uint256 unsealed = CFT.unseal(
            counter.sealedRes(euint32.unwrap(counter.eNumber())),
            publicKey
        );

        assertEq(unsealed, 5);
    }
}
