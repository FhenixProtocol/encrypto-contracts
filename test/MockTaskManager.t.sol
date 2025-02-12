// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {TestSetup} from "./TestSetup.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract DecryptContract is IAsyncFHEReceiver {
    mapping(uint256 ctHash => uint256) public decryptedRes;
    mapping(uint256 ctHash => string) public sealedRes;

    function decrypt(inEuint8 memory inEuint8Value) public {
        euint8 euint8Value = FHE.asEuint8(inEuint8Value);
        FHE.decrypt(euint8Value);
    }

    function decrypt(euint8 euint8Value) public {
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

contract MockTaskManagerTests is TestSetup {
    DecryptContract decryptContract;
    DecryptContract decryptThief;

    function setUp() public override {
        super.setUp();
        decryptContract = new DecryptContract();
        decryptThief = new DecryptContract();
    }

    function _testTrivialEncrypt(uint8 utype, uint256 value) internal {
        bytes memory result = abi.encode(FHE_asEncrypted(utype, value));
        uint256 ctHash = abi.decode(result, (uint256));

        assertEq(taskManager.inMockStorage(ctHash), true);
        assertEq(taskManager.mockStorage(ctHash), value);
    }

    function test_mock_trivialEncrypt() public {
        _testTrivialEncrypt(Utils.EBOOL_TFHE, 1);
        _testTrivialEncrypt(Utils.EUINT8_TFHE, 10);
        _testTrivialEncrypt(Utils.EUINT16_TFHE, 1000);
        _testTrivialEncrypt(Utils.EUINT32_TFHE, 1000000);
        _testTrivialEncrypt(Utils.EUINT64_TFHE, 1000000000);
        _testTrivialEncrypt(Utils.EUINT128_TFHE, 1000000000000);
        _testTrivialEncrypt(Utils.EUINT256_TFHE, 1000000000000000);
        _testTrivialEncrypt(
            Utils.EADDRESS_TFHE,
            uint256(uint160(0x888888CfAebbEd5554c3F36BfBD233f822e9455f))
        );
    }

    function test_mock_inEuintXX() public {
        uint256 ctHash;
        {
            bool boolValue = true;

            inEbool memory inEboolValue = createInEbool(boolValue);
            assertEq(taskManager.inMockStorage(inEboolValue.hash), true);
            assertEq(taskManager.mockStorage(inEboolValue.hash), 1);

            ebool eboolValue = FHE.asEbool(inEboolValue);
            ctHash = ebool.unwrap(eboolValue);

            assertEq(inEboolValue.hash, ctHash);
        }

        {
            uint8 uint8Value = 10;
            inEuint8 memory inEuint8Value = createInEuint8(uint8Value);
            assertEq(taskManager.inMockStorage(inEuint8Value.hash), true);
            assertEq(taskManager.mockStorage(inEuint8Value.hash), uint8Value);

            euint8 euint8Value = FHE.asEuint8(inEuint8Value);
            ctHash = euint8.unwrap(euint8Value);

            assertEq(inEuint8Value.hash, ctHash);
        }

        {
            uint16 uint16Value = 1000;
            inEuint16 memory inEuint16Value = createInEuint16(uint16Value);
            assertEq(taskManager.inMockStorage(inEuint16Value.hash), true);
            assertEq(taskManager.mockStorage(inEuint16Value.hash), uint16Value);

            euint16 euint16Value = FHE.asEuint16(inEuint16Value);
            ctHash = euint16.unwrap(euint16Value);

            assertEq(inEuint16Value.hash, ctHash);
        }

        {
            uint32 uint32Value = 1000000;
            inEuint32 memory inEuint32Value = createInEuint32(uint32Value);
            assertEq(taskManager.inMockStorage(inEuint32Value.hash), true);
            assertEq(taskManager.mockStorage(inEuint32Value.hash), uint32Value);

            euint32 euint32Value = FHE.asEuint32(inEuint32Value);
            ctHash = euint32.unwrap(euint32Value);

            assertEq(inEuint32Value.hash, ctHash);
        }

        {
            uint64 uint64Value = 1000000000;
            inEuint64 memory inEuint64Value = createInEuint64(uint64Value);
            assertEq(taskManager.inMockStorage(inEuint64Value.hash), true);
            assertEq(taskManager.mockStorage(inEuint64Value.hash), uint64Value);

            euint64 euint64Value = FHE.asEuint64(inEuint64Value);
            ctHash = euint64.unwrap(euint64Value);

            assertEq(inEuint64Value.hash, ctHash);
        }

        {
            uint128 uint128Value = 1000000000000;
            inEuint128 memory inEuint128Value = createInEuint128(uint128Value);
            assertEq(taskManager.inMockStorage(inEuint128Value.hash), true);
            assertEq(
                taskManager.mockStorage(inEuint128Value.hash),
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
                taskManager.mockStorage(inEuint256Value.hash),
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
                address(uint160(taskManager.mockStorage(inEaddressValue.hash))),
                addressValue
            );

            eaddress eaddressValue = FHE.asEaddress(inEaddressValue);
            ctHash = eaddress.unwrap(eaddressValue);

            assertEq(inEaddressValue.hash, ctHash);
        }
    }

    function test_mock_select() public {
        bool boolValue = true;
        ebool eboolValue = FHE.asEbool(boolValue);

        uint32 uint32A = 10;
        uint32 uint32B = 20;

        euint32 euintA = FHE.asEuint32(uint32A);
        euint32 euintB = FHE.asEuint32(uint32B);

        euint32 euintC = FHE.select(eboolValue, euintA, euintB);

        assertEq(taskManager.mockStorage(euint32.unwrap(euintC)), uint32A);

        boolValue = false;
        eboolValue = FHE.asEbool(boolValue);

        euintC = FHE.select(eboolValue, euintA, euintB);

        assertEq(taskManager.mockStorage(euint32.unwrap(euintC)), uint32B);
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
            assertEq(taskManager.mockStorage(ebool.unwrap(notResult)), 0);
        }
        {
            // Test square
            euint32 squared = FHE.square(ea);
            assertEq(taskManager.mockStorage(euint32.unwrap(squared)), a * a);
        }

        // Test two-input operations
        {
            // Arithmetic operations
            euint32 sum = FHE.add(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(sum)), a + b);
        }
        {
            // Test subtraction
            euint32 diff = FHE.sub(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(diff)), a - b);
        }
        {
            // Test multiplication
            euint32 prod = FHE.mul(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(prod)), a * b);
        }
        {
            // Test division
            euint32 div = FHE.div(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(div)), a / b);
        }
        {
            // Test remainder
            euint32 rem = FHE.rem(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(rem)), a % b);
        }

        // Bitwise operations
        {
            // Test bitwise AND
            euint32 andResult = FHE.and(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(andResult)), a & b);
        }
        {
            // Test bitwise OR
            euint32 orResult = FHE.or(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(orResult)), a | b);
        }
        {
            // Test bitwise XOR
            euint32 xorResult = FHE.xor(ea, eb);
            assertEq(taskManager.mockStorage(euint32.unwrap(xorResult)), a ^ b);
        }

        // Shift operations
        uint32 shift = 2;
        {
            // Test shift left
            euint32 es = FHE.asEuint32(shift);

            euint32 shl = FHE.shl(ea, es);
            assertEq(taskManager.mockStorage(euint32.unwrap(shl)), a << shift);
        }
        {
            // Test shift right
            euint32 es = FHE.asEuint32(shift);

            euint32 shr = FHE.shr(ea, es);
            assertEq(taskManager.mockStorage(euint32.unwrap(shr)), a >> shift);
        }
        {
            // Test rol
            euint32 es = FHE.asEuint32(shift);

            euint32 rol = FHE.rol(ea, es);
            assertEq(
                taskManager.mockStorage(euint32.unwrap(rol)),
                a << shift // Note: rol is implemented as shl in the mock
            );
        }
        {
            // Test ror
            euint32 es = FHE.asEuint32(shift);

            euint32 ror = FHE.ror(ea, es);
            assertEq(
                taskManager.mockStorage(euint32.unwrap(ror)),
                a >> shift // Note: ror is implemented as shr in the mock
            );
        }

        // Comparison operations
        {
            // Test greater than
            ebool gt = FHE.gt(ea, eb);
            assertEq(taskManager.mockStorage(ebool.unwrap(gt)), a > b ? 1 : 0);
        }
        {
            // Test less than
            ebool lt = FHE.lt(ea, eb);
            assertEq(taskManager.mockStorage(ebool.unwrap(lt)), a < b ? 1 : 0);
        }
        {
            // Test greater than or equal to
            ebool gte = FHE.gte(ea, eb);
            assertEq(
                taskManager.mockStorage(ebool.unwrap(gte)),
                a >= b ? 1 : 0
            );
        }
        {
            // Test less than or equal to
            ebool lte = FHE.lte(ea, eb);
            assertEq(
                taskManager.mockStorage(ebool.unwrap(lte)),
                a <= b ? 1 : 0
            );
        }
        {
            // Test equal to
            ebool eq = FHE.eq(ea, eb);
            assertEq(taskManager.mockStorage(ebool.unwrap(eq)), a == b ? 1 : 0);
        }
        {
            // Test not equal to
            ebool ne = FHE.ne(ea, eb);
            assertEq(taskManager.mockStorage(ebool.unwrap(ne)), a != b ? 1 : 0);
        }

        // Min/Max operations
        {
            // Test min
            euint32 min = FHE.min(ea, eb);
            assertEq(
                taskManager.mockStorage(euint32.unwrap(min)),
                a < b ? a : b
            );
        }
        {
            // Test max
            euint32 max = FHE.max(ea, eb);
            assertEq(
                taskManager.mockStorage(euint32.unwrap(max)),
                a > b ? a : b
            );
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
        uint256 result = decryptContract.decryptedRes(inEuint8Value.hash);

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
        string memory result = decryptContract.sealedRes(inEuint8Value.hash);

        uint256 unsealed = xorUnseal(result, publicKey);
        assertEq(unsealed, uint8Value);
    }

    error ACLNotAllowed(uint256 handle, address account);

    function test_ACL_not_allowed() public {
        uint160 userAddress = 512;

        uint8 uint8Value = 10;
        vm.prank(address(userAddress));
        inEuint8 memory inEuint8Value = createInEuint8(uint8Value);
        euint8 euint8Value = FHE.asEuint8(inEuint8Value);

        // Decrypt reverts (not allowed yet)

        vm.expectRevert(
            abi.encodeWithSelector(
                ACLNotAllowed.selector,
                inEuint8Value.hash,
                address(decryptThief)
            )
        );

        decryptThief.decrypt(euint8Value);

        // Allow decrypt

        vm.prank(address(userAddress));
        FHE.allow(euint8Value, address(decryptThief));

        // Decrypt succeeds

        decryptThief.decrypt(euint8Value);

        assertEq(decryptThief.decryptedRes(inEuint8Value.hash), uint8Value);
    }
}
