// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {TestSetup} from "./TestSetup.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract DecryptContract is IAsyncFHEReceiver {
    mapping(address => uint256) public decryptResults;
    mapping(address => string) public sealOutputResults;

    function decrypt(inEuint8 memory inEuint8Value) public {
        euint8 euint8Value = FHE.asEuint8(inEuint8Value);
        FHE.decrypt(euint8Value);
    }

    function sealoutput(
        inEuint8 memory inEuint8Value,
        bytes32 publicKey
    ) public {
        euint8 euint8Value = FHE.asEuint8(inEuint8Value);
        FHE.sealoutput(euint8Value, publicKey);
    }

    function handleDecryptResult(
        uint256 ctHash,
        uint256 result,
        address accountId
    ) external override {
        decryptResults[accountId] = result;
    }

    function handleSealOutputResult(
        uint256 ctHash,
        string memory result,
        address accountId
    ) external override {
        sealOutputResults[accountId] = result;
    }
}

contract MockTaskManagerTests is TestSetup {
    DecryptContract decryptContract;

    function setUp() public override {
        super.setUp();
        decryptContract = new DecryptContract();
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

    function test_mock_inEuintXX() public {
        uint256 ctHash;
        {
            bool boolValue = true;

            inEbool memory inEboolValue = createInEbool(boolValue);
            assertEq(taskManager.inMockStorage(inEboolValue.hash), true);
            assertEq(taskManager.getFromMockStorage(inEboolValue.hash), 1);

            ebool eboolValue = FHE.asEbool(inEboolValue);
            ctHash = ebool.unwrap(eboolValue);

            assertEq(inEboolValue.hash, ctHash);
        }

        {
            uint8 uint8Value = 10;
            inEuint8 memory inEuint8Value = createInEuint8(uint8Value);
            assertEq(taskManager.inMockStorage(inEuint8Value.hash), true);
            assertEq(
                taskManager.getFromMockStorage(inEuint8Value.hash),
                uint8Value
            );

            euint8 euint8Value = FHE.asEuint8(inEuint8Value);
            ctHash = euint8.unwrap(euint8Value);

            assertEq(inEuint8Value.hash, ctHash);
        }

        {
            uint16 uint16Value = 1000;
            inEuint16 memory inEuint16Value = createInEuint16(uint16Value);
            assertEq(taskManager.inMockStorage(inEuint16Value.hash), true);
            assertEq(
                taskManager.getFromMockStorage(inEuint16Value.hash),
                uint16Value
            );

            euint16 euint16Value = FHE.asEuint16(inEuint16Value);
            ctHash = euint16.unwrap(euint16Value);

            assertEq(inEuint16Value.hash, ctHash);
        }

        {
            uint32 uint32Value = 1000000;
            inEuint32 memory inEuint32Value = createInEuint32(uint32Value);
            assertEq(taskManager.inMockStorage(inEuint32Value.hash), true);
            assertEq(
                taskManager.getFromMockStorage(inEuint32Value.hash),
                uint32Value
            );

            euint32 euint32Value = FHE.asEuint32(inEuint32Value);
            ctHash = euint32.unwrap(euint32Value);

            assertEq(inEuint32Value.hash, ctHash);
        }

        {
            uint64 uint64Value = 1000000000;
            inEuint64 memory inEuint64Value = createInEuint64(uint64Value);
            assertEq(taskManager.inMockStorage(inEuint64Value.hash), true);
            assertEq(
                taskManager.getFromMockStorage(inEuint64Value.hash),
                uint64Value
            );

            euint64 euint64Value = FHE.asEuint64(inEuint64Value);
            ctHash = euint64.unwrap(euint64Value);

            assertEq(inEuint64Value.hash, ctHash);
        }

        {
            uint128 uint128Value = 1000000000000;
            inEuint128 memory inEuint128Value = createInEuint128(uint128Value);
            assertEq(taskManager.inMockStorage(inEuint128Value.hash), true);
            assertEq(
                taskManager.getFromMockStorage(inEuint128Value.hash),
                uint128Value
            );

            euint128 euint128Value = FHE.asEuint128(inEuint128Value);
            ctHash = euint128.unwrap(euint128Value);

            assertEq(inEuint128Value.hash, ctHash);
        }

        {
            uint256 uint256Value = 1000000000000000;
            inEuint256 memory inEuint256Value = createInEuint256(uint256Value);
            assertEq(taskManager.inMockStorage(inEuint256Value.hash), true);
            assertEq(
                taskManager.getFromMockStorage(inEuint256Value.hash),
                uint256Value
            );

            euint256 euint256Value = FHE.asEuint256(inEuint256Value);
            ctHash = euint256.unwrap(euint256Value);

            assertEq(inEuint256Value.hash, ctHash);
        }

        {
            address addressValue = 0x888888CfAebbEd5554c3F36BfBD233f822e9455f;
            inEaddress memory inEaddressValue = createInEaddress(addressValue);
            assertEq(taskManager.inMockStorage(inEaddressValue.hash), true);
            assertEq(
                address(
                    uint160(
                        taskManager.getFromMockStorage(inEaddressValue.hash)
                    )
                ),
                addressValue
            );

            eaddress eaddressValue = FHE.asEaddress(inEaddressValue);
            ctHash = eaddress.unwrap(eaddressValue);

            assertEq(inEaddressValue.hash, ctHash);
        }
    }

    function test_mock_decrypt() public {
        uint160 userAddress = 512;

        uint8 uint8Value = 10;
        vm.prank(address(userAddress));
        inEuint8 memory inEuint8Value = createInEuint8(uint8Value);

        vm.prank(address(userAddress));
        decryptContract.decrypt(inEuint8Value);

        // In mocks, this happens synchronously
        uint256 result = decryptContract.decryptResults(address(userAddress));

        assertEq(result, uint8Value);
    }

    function test_mock_sealOutput() public {
        uint160 userAddress = 512;

        uint8 uint8Value = 10;
        vm.prank(address(userAddress));
        inEuint8 memory inEuint8Value = createInEuint8(uint8Value);

        vm.prank(address(userAddress));
        bytes32 publicKey = bytes32("HELLO0x1234567890abcdef");
        decryptContract.sealoutput(inEuint8Value, publicKey);

        // In mocks, this happens synchronously
        string memory result = decryptContract.sealOutputResults(
            address(userAddress)
        );

        uint256 unsealed = xorUnseal(result, publicKey);
        assertEq(unsealed, uint8Value);
    }

    function test_mock_euint32_operations() public {
        uint32 a = 100;
        uint32 b = 50;

        // Convert to encrypted values
        euint32 ea = FHE.asEuint32(a);
        euint32 eb = FHE.asEuint32(b);

        // Test unary operations
        {
            // Test not (only works on ebool)
            ebool eboolVal = FHE.asEbool(true);
            ebool notResult = FHE.not(eboolVal);
            assertEq(
                taskManager.getFromMockStorage(ebool.unwrap(notResult)),
                0
            );
        }
        {
            // Test square
            euint32 squared = FHE.square(ea);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(squared)),
                a * a
            );
        }

        // Test two-input operations
        {
            // Arithmetic operations
            euint32 sum = FHE.add(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(sum)),
                a + b
            );
        }
        {
            // Test subtraction
            euint32 diff = FHE.sub(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(diff)),
                a - b
            );
        }
        {
            // Test multiplication
            euint32 prod = FHE.mul(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(prod)),
                a * b
            );
        }
        {
            // Test division
            euint32 div = FHE.div(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(div)),
                a / b
            );
        }
        {
            // Test remainder
            euint32 rem = FHE.rem(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(rem)),
                a % b
            );
        }

        // Bitwise operations
        {
            // Test bitwise AND
            euint32 andResult = FHE.and(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(andResult)),
                a & b
            );
        }
        {
            // Test bitwise OR
            euint32 orResult = FHE.or(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(orResult)),
                a | b
            );
        }
        {
            // Test bitwise XOR
            euint32 xorResult = FHE.xor(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(xorResult)),
                a ^ b
            );
        }

        // Shift operations
        uint32 shift = 2;
        {
            // Test shift left
            euint32 es = FHE.asEuint32(shift);

            euint32 shl = FHE.shl(ea, es);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(shl)),
                a << shift
            );
        }
        {
            // Test shift right
            euint32 es = FHE.asEuint32(shift);

            euint32 shr = FHE.shr(ea, es);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(shr)),
                a >> shift
            );
        }
        {
            // Test rol
            euint32 es = FHE.asEuint32(shift);

            euint32 rol = FHE.rol(ea, es);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(rol)),
                a << shift // Note: rol is implemented as shl in the mock
            );
        }
        {
            // Test ror
            euint32 es = FHE.asEuint32(shift);

            euint32 ror = FHE.ror(ea, es);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(ror)),
                a >> shift // Note: ror is implemented as shr in the mock
            );
        }

        // Comparison operations
        {
            // Test greater than
            ebool gt = FHE.gt(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(ebool.unwrap(gt)),
                a > b ? 1 : 0
            );
        }
        {
            // Test less than
            ebool lt = FHE.lt(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(ebool.unwrap(lt)),
                a < b ? 1 : 0
            );
        }
        {
            // Test greater than or equal to
            ebool gte = FHE.gte(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(ebool.unwrap(gte)),
                a >= b ? 1 : 0
            );
        }
        {
            // Test less than or equal to
            ebool lte = FHE.lte(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(ebool.unwrap(lte)),
                a <= b ? 1 : 0
            );
        }
        {
            // Test equal to
            ebool eq = FHE.eq(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(ebool.unwrap(eq)),
                a == b ? 1 : 0
            );
        }
        {
            // Test not equal to
            ebool ne = FHE.ne(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(ebool.unwrap(ne)),
                a != b ? 1 : 0
            );
        }

        // Min/Max operations
        {
            // Test min
            euint32 min = FHE.min(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(min)),
                a < b ? a : b
            );
        }
        {
            // Test max
            euint32 max = FHE.max(ea, eb);
            assertEq(
                taskManager.getFromMockStorage(euint32.unwrap(max)),
                a > b ? a : b
            );
        }
    }
}
