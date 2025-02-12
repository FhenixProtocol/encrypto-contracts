// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {TestSetup} from "./TestSetup.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract MockTaskManagerTests is TestSetup {
    function setUp() public override {
        super.setUp();
    }

    function test_mock_trivialEncrypt() public {
        uint256 ctHash;
        {
            bool boolValue = true;
            ebool eboolValue = FHE.asEbool(boolValue);
            ctHash = ebool.unwrap(eboolValue);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(taskManager.getFromMockStorage(ctHash), boolValue ? 1 : 0);
        }
        {
            uint8 uint8Value = 10;
            euint8 euint8Value = FHE.asEuint8(uint8Value);
            ctHash = euint8.unwrap(euint8Value);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(taskManager.getFromMockStorage(ctHash), uint8Value);
        }
        {
            uint16 uint16Value = 1000;
            euint16 euint16Value = FHE.asEuint16(uint16Value);
            ctHash = euint16.unwrap(euint16Value);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(taskManager.getFromMockStorage(ctHash), uint16Value);
        }
        {
            uint32 uint32Value = 1000000;
            euint32 euint32Value = FHE.asEuint32(uint32Value);
            ctHash = euint32.unwrap(euint32Value);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(taskManager.getFromMockStorage(ctHash), uint32Value);
        }
        {
            uint64 uint64Value = 1000000000;
            euint64 euint64Value = FHE.asEuint64(uint64Value);
            ctHash = euint64.unwrap(euint64Value);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(taskManager.getFromMockStorage(ctHash), uint64Value);
        }
        {
            uint128 uint128Value = 1000000000000;
            euint128 euint128Value = FHE.asEuint128(uint128Value);
            ctHash = euint128.unwrap(euint128Value);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(taskManager.getFromMockStorage(ctHash), uint128Value);
        }
        {
            uint256 uint256Value = 1000000000000000;
            euint256 euint256Value = FHE.asEuint256(uint256Value);
            ctHash = euint256.unwrap(euint256Value);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(taskManager.getFromMockStorage(ctHash), uint256Value);
        }
        {
            address addressValue = 0x888888CfAebbEd5554c3F36BfBD233f822e9455f;
            eaddress eaddressValue = FHE.asEaddress(addressValue);
            ctHash = eaddress.unwrap(eaddressValue);

            assertEq(taskManager.inMockStorage(ctHash), true);
            assertEq(
                address(uint160(taskManager.getFromMockStorage(ctHash))),
                addressValue
            );
        }
    }
}
