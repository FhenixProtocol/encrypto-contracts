// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TaskManager} from "./MockTaskManager.sol";
import {ACL} from "./ACL.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract FhenixMocks is Test {
    // MOCKS
    TaskManager public taskManager;
    ACL public acl;

    address public constant TM_ADMIN = address(128);

    function etchFhenixMocks() internal {
        deployCodeTo(
            "MockTaskManager.sol:TaskManager",
            abi.encode(TM_ADMIN, 0, 1),
            TASK_MANAGER_ADDRESS
        );
        taskManager = TaskManager(TASK_MANAGER_ADDRESS);

        acl = new ACL();
        vm.label(address(acl), "ACL");

        vm.prank(TM_ADMIN);
        taskManager.setACLContract(address(acl));
    }

    // Unseal a sealed value returned by FHE.sealoutput
    // In the mocked task manager, the sealed value is an xored value of the original value and a mask derived from the public key
    function xorUnseal(
        string memory sealedData,
        bytes32 publicKey
    ) internal pure returns (uint256 result) {
        bytes32 mask = keccak256(abi.encodePacked(publicKey));
        bytes32 xored = hexStringToBytes32(sealedData) ^ mask;
        return uint256(xored);
    }

    function hexStringToBytes32(
        string memory hexString
    ) public pure returns (bytes32) {
        require(
            bytes(hexString).length == 66 &&
                bytes(hexString)[0] == "0" &&
                bytes(hexString)[1] == "x",
            "Invalid hex string"
        );

        bytes32 result;
        for (uint256 i = 2; i < 66; i++) {
            result =
                (result << 4) |
                bytes32(uint256(fromHexChar(uint8(bytes(hexString)[i]))));
        }
        return result;
    }

    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (c >= 48 && c <= 57) {
            return c - 48; // '0' - '9'
        } else if (c >= 97 && c <= 102) {
            return c - 87; // 'a' - 'f'
        } else if (c >= 65 && c <= 70) {
            return c - 55; // 'A' - 'F'
        } else {
            revert("Invalid hex char");
        }
    }

    // Generic function to create an encrypted value of a given type
    // The hash returned is a pointer to the value in the mocked task manager
    function FHE_asEncrypted(
        uint8 utype,
        uint256 value
    ) internal returns (uint256) {
        if (utype == Utils.EBOOL_TFHE) {
            return ebool.unwrap(FHE.asEbool(value == 1));
        } else if (utype == Utils.EUINT8_TFHE) {
            return euint8.unwrap(FHE.asEuint8(uint8(value)));
        } else if (utype == Utils.EUINT16_TFHE) {
            return euint16.unwrap(FHE.asEuint16(uint16(value)));
        } else if (utype == Utils.EUINT32_TFHE) {
            return euint32.unwrap(FHE.asEuint32(uint32(value)));
        } else if (utype == Utils.EUINT64_TFHE) {
            return euint64.unwrap(FHE.asEuint64(uint64(value)));
        } else if (utype == Utils.EUINT128_TFHE) {
            return euint128.unwrap(FHE.asEuint128(uint128(value)));
        } else if (utype == Utils.EUINT256_TFHE) {
            return euint256.unwrap(FHE.asEuint256(uint256(value)));
        } else if (utype == Utils.EADDRESS_TFHE) {
            return eaddress.unwrap(FHE.asEaddress(address(uint160(value))));
        } else {
            revert("Invalid utype");
        }
    }

    function stripTrivialEncryptMask(
        uint256 ctHash
    ) internal returns (uint256 strippedCtHash) {
        // Strip the trivial encrypt mask
        strippedCtHash = taskManager.MOCK_stripTrivialEncryptMask(ctHash);

        // Replace the hash with the stripped hash in storage
        taskManager.MOCK_replaceHash(ctHash, strippedCtHash);
    }

    // Generic internal function to create encrypted input types
    function createInEncrypted(
        uint8 utype,
        uint256 value,
        int32 securityZone
    ) internal returns (bytes memory) {
        uint256 ctHash = FHE_asEncrypted(utype, value);
        uint256 strippedCtHash = stripTrivialEncryptMask(ctHash);
        return
            abi.encode(
                securityZone,
                strippedCtHash,
                utype,
                "MOCK" // signature
            );
    }

    // Derived functions that use the generic createInEncrypted
    function createInEbool(
        bool value,
        int32 securityZone
    ) internal returns (inEbool memory) {
        return
            abi.decode(
                createInEncrypted(
                    Utils.EBOOL_TFHE,
                    value ? 1 : 0,
                    securityZone
                ),
                (inEbool)
            );
    }

    function createInEuint8(
        uint8 value,
        int32 securityZone
    ) internal returns (inEuint8 memory) {
        return
            abi.decode(
                createInEncrypted(Utils.EUINT8_TFHE, value, securityZone),
                (inEuint8)
            );
    }

    function createInEuint16(
        uint16 value,
        int32 securityZone
    ) internal returns (inEuint16 memory) {
        return
            abi.decode(
                createInEncrypted(Utils.EUINT16_TFHE, value, securityZone),
                (inEuint16)
            );
    }

    function createInEuint32(
        uint32 value,
        int32 securityZone
    ) internal returns (inEuint32 memory) {
        return
            abi.decode(
                createInEncrypted(Utils.EUINT32_TFHE, value, securityZone),
                (inEuint32)
            );
    }

    function createInEuint64(
        uint64 value,
        int32 securityZone
    ) internal returns (inEuint64 memory) {
        return
            abi.decode(
                createInEncrypted(Utils.EUINT64_TFHE, value, securityZone),
                (inEuint64)
            );
    }

    function createInEuint128(
        uint128 value,
        int32 securityZone
    ) internal returns (inEuint128 memory) {
        return
            abi.decode(
                createInEncrypted(Utils.EUINT128_TFHE, value, securityZone),
                (inEuint128)
            );
    }

    function createInEuint256(
        uint256 value,
        int32 securityZone
    ) internal returns (inEuint256 memory) {
        return
            abi.decode(
                createInEncrypted(Utils.EUINT256_TFHE, value, securityZone),
                (inEuint256)
            );
    }

    function createInEaddress(
        address value,
        int32 securityZone
    ) internal returns (inEaddress memory) {
        return
            abi.decode(
                createInEncrypted(
                    Utils.EADDRESS_TFHE,
                    uint256(uint160(value)),
                    securityZone
                ),
                (inEaddress)
            );
    }

    // Overloads with default securityZone=0 for backward compatibility
    function createInEbool(bool value) internal returns (inEbool memory) {
        return createInEbool(value, 0);
    }

    function createInEuint8(uint8 value) internal returns (inEuint8 memory) {
        return createInEuint8(value, 0);
    }

    function createInEuint16(uint16 value) internal returns (inEuint16 memory) {
        return createInEuint16(value, 0);
    }

    function createInEuint32(uint32 value) internal returns (inEuint32 memory) {
        return createInEuint32(value, 0);
    }

    function createInEuint64(uint64 value) internal returns (inEuint64 memory) {
        return createInEuint64(value, 0);
    }

    function createInEuint128(
        uint128 value
    ) internal returns (inEuint128 memory) {
        return createInEuint128(value, 0);
    }

    function createInEuint256(
        uint256 value
    ) internal returns (inEuint256 memory) {
        return createInEuint256(value, 0);
    }

    function createInEaddress(
        address value
    ) internal returns (inEaddress memory) {
        return createInEaddress(value, 0);
    }
}
