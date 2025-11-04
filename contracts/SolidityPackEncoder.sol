// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SolidityPackTypes.sol";

/**
 * @title SolidityPackEncoder
 * @notice Ultra gas-efficient encoding for SolidityPack format
 * @dev Encoder-only library to save bytecode in contracts that only encode
 */

library SolidityPackEncoder {
    using SolidityPackTypes for *;

    // ============ ENCODER FUNCTIONS ============

    function newEncoder() internal pure returns (SolidityPackTypes.Encoder memory) {
        return SolidityPackTypes.Encoder(
            new bytes(SolidityPackTypes.INITIAL_BUFFER_SIZE),
            0
        );
    }

    function encodeBool(
        SolidityPackTypes.Encoder memory enc,
        bool value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        _ensureCapacity(enc, 1);
        enc.buffer[enc.pos++] = bytes1(value ? SolidityPackTypes.TRUE : SolidityPackTypes.FALSE);
        return enc;
    }

    function encodeNil(
        SolidityPackTypes.Encoder memory enc
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        _ensureCapacity(enc, 1);
        enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.NIL);
        return enc;
    }

    function encodeUint(
        SolidityPackTypes.Encoder memory enc,
        uint256 value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        if (value <= SolidityPackTypes.FIXINT_POS_MAX) {
            _ensureCapacity(enc, 1);
            enc.buffer[enc.pos++] = bytes1(uint8(value));
        } else if (value <= type(uint8).max) {
            _ensureCapacity(enc, 2);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.UINT8);
            enc.buffer[enc.pos++] = bytes1(uint8(value));
        } else if (value <= type(uint16).max) {
            _ensureCapacity(enc, 3);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.UINT16);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                mstore8(ptr, shr(8, value))
                mstore8(add(ptr, 1), value)
            }
            enc.pos += 2;
        } else if (value <= type(uint32).max) {
            _ensureCapacity(enc, 5);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.UINT32);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                mstore8(ptr, shr(24, value))
                mstore8(add(ptr, 1), shr(16, value))
                mstore8(add(ptr, 2), shr(8, value))
                mstore8(add(ptr, 3), value)
            }
            enc.pos += 4;
        } else if (value <= type(uint64).max) {
            _ensureCapacity(enc, 9);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.UINT64);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                mstore8(ptr, shr(56, value))
                mstore8(add(ptr, 1), shr(48, value))
                mstore8(add(ptr, 2), shr(40, value))
                mstore8(add(ptr, 3), shr(32, value))
                mstore8(add(ptr, 4), shr(24, value))
                mstore8(add(ptr, 5), shr(16, value))
                mstore8(add(ptr, 6), shr(8, value))
                mstore8(add(ptr, 7), value)
            }
            enc.pos += 8;
        } else if (value <= type(uint128).max) {
            _ensureCapacity(enc, 17);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.UINT128);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                for { let i := 0 } lt(i, 16) { i := add(i, 1) } {
                    mstore8(add(ptr, i), shr(sub(120, mul(i, 8)), value))
                }
            }
            enc.pos += 16;
        } else {
            _ensureCapacity(enc, 33);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.UINT256);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                mstore(ptr, value)
            }
            enc.pos += 32;
        }
        return enc;
    }

    function encodeInt(
        SolidityPackTypes.Encoder memory enc,
        int256 value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        if (value >= 0) {
            return encodeUint(enc, uint256(value));
        }

        if (value >= -32) {
            _ensureCapacity(enc, 1);
            enc.buffer[enc.pos++] = bytes1(
                uint8(SolidityPackTypes.FIXINT_NEG_BASE + uint8(int8(value + 32)))
            );
        } else if (value >= type(int8).min) {
            _ensureCapacity(enc, 2);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.INT8);
            enc.buffer[enc.pos++] = bytes1(uint8(int8(value)));
        } else if (value >= type(int16).min) {
            _ensureCapacity(enc, 3);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.INT16);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                mstore8(ptr, shr(8, value))
                mstore8(add(ptr, 1), value)
            }
            enc.pos += 2;
        } else if (value >= type(int32).min) {
            _ensureCapacity(enc, 5);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.INT32);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                mstore8(ptr, shr(24, value))
                mstore8(add(ptr, 1), shr(16, value))
                mstore8(add(ptr, 2), shr(8, value))
                mstore8(add(ptr, 3), value)
            }
            enc.pos += 4;
        } else {
            _ensureCapacity(enc, 33);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.INT256);
            assembly {
                let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
                mstore(ptr, value)
            }
            enc.pos += 32;
        }
        return enc;
    }

    function encodeAddress(
        SolidityPackTypes.Encoder memory enc,
        address value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        _ensureCapacity(enc, 21);
        enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.ADDRESS);
        assembly {
            let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
            mstore(ptr, shl(96, value))
        }
        enc.pos += 20;
        return enc;
    }

    function encodeBytes32(
        SolidityPackTypes.Encoder memory enc,
        bytes32 value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        _ensureCapacity(enc, 33);
        enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.BYTES32_TYPE);
        assembly {
            let ptr := add(add(mload(enc), 32), mload(add(enc, 32)))
            mstore(ptr, value)
        }
        enc.pos += 32;
        return enc;
    }

    function encodeBytes(
        SolidityPackTypes.Encoder memory enc,
        bytes memory value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        uint256 len = value.length;
        if (len <= 255) {
            _ensureCapacity(enc, len + 2);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.BYTES8);
            enc.buffer[enc.pos++] = bytes1(uint8(len));
        } else {
            _ensureCapacity(enc, len + 3);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.BYTES16);
            enc.buffer[enc.pos++] = bytes1(uint8(len >> 8));
            enc.buffer[enc.pos++] = bytes1(uint8(len));
        }

        // Proper memory copying with tail handling
        assembly {
            let src := add(value, 32)
            let dst := add(add(mload(enc), 32), mload(add(enc, 32)))
            let remaining := len

            // Copy 32-byte chunks
            for { let i := 0 } lt(i, len) { i := add(i, 32) } {
                mstore(add(dst, i), mload(add(src, i)))
            }
        }
        enc.pos += len;
        return enc;
    }

    function encodeString(
        SolidityPackTypes.Encoder memory enc,
        string memory value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        bytes memory b = bytes(value);
        uint256 len = b.length;

        if (len <= 31) {
            _ensureCapacity(enc, len + 1);
            enc.buffer[enc.pos++] = bytes1(uint8(SolidityPackTypes.FIXSTR_BASE + len));
        } else if (len <= 255) {
            _ensureCapacity(enc, len + 2);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.STR8);
            enc.buffer[enc.pos++] = bytes1(uint8(len));
        } else {
            _ensureCapacity(enc, len + 3);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.STR16);
            enc.buffer[enc.pos++] = bytes1(uint8(len >> 8));
            enc.buffer[enc.pos++] = bytes1(uint8(len));
        }

        // Same safe copying approach
        assembly {
            let src := add(b, 32)
            let dst := add(add(mload(enc), 32), mload(add(enc, 32)))
            for { let i := 0 } lt(i, len) { i := add(i, 32) } {
                mstore(add(dst, i), mload(add(src, i)))
            }
        }
        enc.pos += len;
        return enc;
    }

    function startArray(
        SolidityPackTypes.Encoder memory enc,
        uint256 length
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        if (length <= 15) {
            _ensureCapacity(enc, 1);
            enc.buffer[enc.pos++] = bytes1(uint8(SolidityPackTypes.FIXARRAY_BASE + length));
        } else if (length <= 255) {
            _ensureCapacity(enc, 2);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.ARRAY8);
            enc.buffer[enc.pos++] = bytes1(uint8(length));
        } else {
            _ensureCapacity(enc, 3);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.ARRAY16);
            enc.buffer[enc.pos++] = bytes1(uint8(length >> 8));
            enc.buffer[enc.pos++] = bytes1(uint8(length));
        }
        return enc;
    }

    function startMap(
        SolidityPackTypes.Encoder memory enc,
        uint256 length
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        if (length <= 15) {
            _ensureCapacity(enc, 1);
            enc.buffer[enc.pos++] = bytes1(uint8(SolidityPackTypes.FIXMAP_BASE + length));
        } else if (length <= 255) {
            _ensureCapacity(enc, 2);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.MAP8);
            enc.buffer[enc.pos++] = bytes1(uint8(length));
        } else {
            _ensureCapacity(enc, 3);
            enc.buffer[enc.pos++] = bytes1(SolidityPackTypes.MAP16);
            enc.buffer[enc.pos++] = bytes1(uint8(length >> 8));
            enc.buffer[enc.pos++] = bytes1(uint8(length));
        }
        return enc;
    }

    // ============ NESTED OBJECT SUPPORT ============

    /**
     * @notice Start encoding a nested object (map with string keys)
     * @dev Call this, then encode key-value pairs using encodeKey/encode* pattern
     */
    function startObject(
        SolidityPackTypes.Encoder memory enc,
        uint256 numFields
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        return startMap(enc, numFields);
    }

    /**
     * @notice Encode a field key in an object
     * @dev Optimized for short field names
     */
    function encodeKey(
        SolidityPackTypes.Encoder memory enc,
        string memory key
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        return encodeString(enc, key);
    }

    /**
     * @notice Helper to encode nested array of uints
     */
    function encodeUintArray(
        SolidityPackTypes.Encoder memory enc,
        uint256[] memory values
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        startArray(enc, values.length);
        for (uint256 i = 0; i < values.length; i++) {
            encodeUint(enc, values[i]);
        }
        return enc;
    }

    /**
     * @notice Helper to encode nested array of addresses
     */
    function encodeAddressArray(
        SolidityPackTypes.Encoder memory enc,
        address[] memory values
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        startArray(enc, values.length);
        for (uint256 i = 0; i < values.length; i++) {
            encodeAddress(enc, values[i]);
        }
        return enc;
    }

    /**
     * @notice Helper to encode nested array of strings
     */
    function encodeStringArray(
        SolidityPackTypes.Encoder memory enc,
        string[] memory values
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        startArray(enc, values.length);
        for (uint256 i = 0; i < values.length; i++) {
            encodeString(enc, values[i]);
        }
        return enc;
    }

    // ============ CONVENIENCE FUNCTIONS FOR OBJECT FIELDS ============

    /**
     * @notice Convenience function to encode key + uint value in one call
     * @dev Reduces 2 lines to 1 for object field encoding
     */
    function encodeFieldUint(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        uint256 value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeUint(enc, value);
    }

    /**
     * @notice Convenience function to encode key + string value in one call
     */
    function encodeFieldString(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        string memory value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeString(enc, value);
    }

    /**
     * @notice Convenience function to encode key + address value in one call
     */
    function encodeFieldAddress(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        address value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeAddress(enc, value);
    }

    /**
     * @notice Convenience function to encode key + bool value in one call
     */
    function encodeFieldBool(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        bool value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeBool(enc, value);
    }

    /**
     * @notice Convenience function to encode key + bytes32 value in one call
     */
    function encodeFieldBytes32(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        bytes32 value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeBytes32(enc, value);
    }

    /**
     * @notice Convenience function to encode key + bytes value in one call
     */
    function encodeFieldBytes(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        bytes memory value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeBytes(enc, value);
    }

    /**
     * @notice Convenience function to encode key + int256 value in one call
     */
    function encodeFieldInt(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        int256 value
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeInt(enc, value);
    }

    /**
     * @notice Convenience function to encode key + uint array value in one call
     */
    function encodeFieldUintArray(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        uint256[] memory values
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeUintArray(enc, values);
    }

    /**
     * @notice Convenience function to encode key + address array value in one call
     */
    function encodeFieldAddressArray(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        address[] memory values
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeAddressArray(enc, values);
    }

    /**
     * @notice Convenience function to encode key + string array value in one call
     */
    function encodeFieldStringArray(
        SolidityPackTypes.Encoder memory enc,
        string memory key,
        string[] memory values
    ) internal pure returns (SolidityPackTypes.Encoder memory) {
        encodeKey(enc, key);
        return encodeStringArray(enc, values);
    }

    function getEncoded(
        SolidityPackTypes.Encoder memory enc
    ) internal pure returns (bytes memory) {
        bytes memory result = new bytes(enc.pos);
        assembly {
            let src := add(mload(enc), 32)
            let dst := add(result, 32)
            // Safe to copy in 32-byte chunks as long as we only copy enc.pos bytes total
            let remaining := mload(add(enc, 32))
            for { let i := 0 } lt(i, remaining) { i := add(i, 32) } {
                mstore(add(dst, i), mload(add(src, i)))
            }
        }
        return result;
    }

    // ============ INTERNAL HELPERS ============

    function _ensureCapacity(
        SolidityPackTypes.Encoder memory enc,
        uint256 required
    ) private pure {
        uint256 needed = enc.pos + required;
        if (needed <= enc.buffer.length) return;

        uint256 currentSize = enc.buffer.length;
        uint256 newSize;

        if (currentSize < SolidityPackTypes.GROWTH_THRESHOLD) {
            newSize = (currentSize * 3) / 2;
            if (newSize < needed) {
                newSize = needed;
            }
            newSize += SolidityPackTypes.MIN_GROWTH_MARGIN;
        } else {
            uint256 growth = needed - currentSize;
            uint256 margin = growth / 4;
            if (margin < SolidityPackTypes.MIN_GROWTH_MARGIN) {
                margin = SolidityPackTypes.MIN_GROWTH_MARGIN;
            }
            newSize = needed + margin;
        }

        bytes memory newBuffer = new bytes(newSize);
        assembly {
            let src := add(mload(enc), 32)
            let dst := add(newBuffer, 32)
            let len := mload(add(enc, 32))

            for { let i := 0 } lt(i, len) { i := add(i, 32) } {
                mstore(add(dst, i), mload(add(src, i)))
            }
        }
        enc.buffer = newBuffer;
    }
}
