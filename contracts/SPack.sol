// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SolidityPackTypes.sol";

/**
 * @title SPack
 * @notice Simplified, less verbose API with reduced bytecode usage
 * @dev Key improvements:
 *  - Direct encode functions (no Encoder management needed for simple cases)
 *  - Batch encoding helpers
 *  - Shorter function names
 *  - Automatic capacity management
 */

library SPack {
    using SolidityPackTypes for *;

    // ============ SIMPLIFIED DIRECT ENCODING ============
    // For simple cases where you just want bytes back

    function encode(bool value) internal pure returns (bytes memory) {
        bytes memory result = new bytes(1);
        result[0] = bytes1(value ? SolidityPackTypes.TRUE : SolidityPackTypes.FALSE);
        return result;
    }

    function encode(uint256 value) internal pure returns (bytes memory) {
        if (value <= 127) {
            bytes memory result = new bytes(1);
            result[0] = bytes1(uint8(value));
            return result;
        }
        // Fallback to full encoder for larger values
        return _encodeUintFull(value);
    }

    function encode(int256 value) internal pure returns (bytes memory) {
        if (value >= 0 && value <= 127) {
            bytes memory result = new bytes(1);
            result[0] = bytes1(uint8(int8(value)));
            return result;
        }
        return _encodeIntFull(value);
    }

    function encode(address value) internal pure returns (bytes memory) {
        bytes memory result = new bytes(21);
        result[0] = bytes1(SolidityPackTypes.ADDRESS);
        assembly ("memory-safe") {
            mstore(add(result, 33), shl(96, value))
        }
        return result;
    }

    function encode(string memory value) internal pure returns (bytes memory) {
        return _encodeStringDirect(value);
    }

    function encode(bytes memory value) internal pure returns (bytes memory) {
        return _encodeBytesDirect(value);
    }

    // ============ BATCH ENCODING (Most gas efficient) ============

    /// @notice Encode multiple uints in one go
    function pack(uint256 a, uint256 b) internal pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory e = _new();
        _uint(e, a);
        _uint(e, b);
        return _done(e);
    }

    function pack(uint256 a, uint256 b, uint256 c) internal pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory e = _new();
        _uint(e, a);
        _uint(e, b);
        _uint(e, c);
        return _done(e);
    }

    function pack(address a, uint256 b) internal pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory e = _new();
        _addr(e, a);
        _uint(e, b);
        return _done(e);
    }

    function pack(address a, address b, uint256 c) internal pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory e = _new();
        _addr(e, a);
        _addr(e, b);
        _uint(e, c);
        return _done(e);
    }

    // ============ BUILDER API (For complex encoding) ============

    struct Builder {
        bytes buffer;
        uint256 pos;
    }

    /// @notice Start building an encoded message
    function builder() internal pure returns (Builder memory) {
        return Builder(new bytes(256), 0);
    }

    /// @notice Encode uint (chainable)
    function u(Builder memory b, uint256 v) internal pure returns (Builder memory) {
        _ensureSpace(b, 33);
        _writeUint(b, v);
        return b;
    }

    /// @notice Encode int (chainable)
    function i(Builder memory b, int256 v) internal pure returns (Builder memory) {
        _ensureSpace(b, 33);
        _writeInt(b, v);
        return b;
    }

    /// @notice Encode address (chainable)
    function a(Builder memory b, address v) internal pure returns (Builder memory) {
        _ensureSpace(b, 21);
        _writeAddr(b, v);
        return b;
    }

    /// @notice Encode string (chainable)
    function s(Builder memory b, string memory v) internal pure returns (Builder memory) {
        _ensureSpace(b, bytes(v).length + 3);
        _writeString(b, v);
        return b;
    }

    /// @notice Encode bytes (chainable)
    function b(Builder memory b, bytes memory v) internal pure returns (Builder memory) {
        _ensureSpace(b, v.length + 3);
        _writeBytes(b, v);
        return b;
    }

    /// @notice Encode bool (chainable)
    function bool_(Builder memory b, bool v) internal pure returns (Builder memory) {
        _ensureSpace(b, 1);
        b.buffer[b.pos++] = bytes1(v ? SolidityPackTypes.TRUE : SolidityPackTypes.FALSE);
        return b;
    }

    /// @notice Encode bytes32 (chainable)
    function b32(Builder memory b, bytes32 v) internal pure returns (Builder memory) {
        _ensureSpace(b, 34);
        _writeBytes32(b, v);
        return b;
    }

    /// @notice Encode nil (chainable)
    function nil(Builder memory b) internal pure returns (Builder memory) {
        _ensureSpace(b, 1);
        b.buffer[b.pos++] = bytes1(SolidityPackTypes.NIL);
        return b;
    }

    /// @notice Start array (chainable)
    function arr(Builder memory b, uint256 len) internal pure returns (Builder memory) {
        _ensureSpace(b, 3);
        _writeArrayStart(b, len);
        return b;
    }

    /// @notice Start map (chainable)
    function map(Builder memory b, uint256 len) internal pure returns (Builder memory) {
        _ensureSpace(b, 3);
        _writeMapStart(b, len);
        return b;
    }

    /// @notice Finalize and return encoded bytes
    function done(Builder memory b) internal pure returns (bytes memory) {
        bytes memory result = new bytes(b.pos);
        assembly ("memory-safe") {
            let src := add(mload(b), 32)
            let dst := add(result, 32)
            let len := mload(add(b, 32))
            let end := add(src, len)

            for { } lt(src, end) { } {
                mstore(dst, mload(src))
                src := add(src, 32)
                dst := add(dst, 32)
            }
        }
        return result;
    }

    // ============ COMMON PATTERNS ============

    /// @notice Encode array of uints
    function array(uint256[] memory values) internal pure returns (bytes memory) {
        Builder memory b = builder();
        arr(b, values.length);
        for (uint256 i = 0; i < values.length; i++) {
            u(b, values[i]);
        }
        return done(b);
    }

    /// @notice Encode array of addresses
    function array(address[] memory values) internal pure returns (bytes memory) {
        Builder memory b = builder();
        arr(b, values.length);
        for (uint256 i = 0; i < values.length; i++) {
            a(b, values[i]);
        }
        return done(b);
    }

    /// @notice Encode array of strings
    function array(string[] memory values) internal pure returns (bytes memory) {
        Builder memory b = builder();
        arr(b, values.length);
        for (uint256 i = 0; i < values.length; i++) {
            s(b, values[i]);
        }
        return done(b);
    }

    /// @notice Encode simple object with string keys
    function object(
        string memory k1, uint256 v1,
        string memory k2, uint256 v2
    ) internal pure returns (bytes memory) {
        Builder memory b = builder();
        map(b, 2);
        s(b, k1); u(b, v1);
        s(b, k2); u(b, v2);
        return done(b);
    }

    function object(
        string memory k1, uint256 v1,
        string memory k2, address v2
    ) internal pure returns (bytes memory) {
        Builder memory b = builder();
        map(b, 2);
        s(b, k1); u(b, v1);
        s(b, k2); a(b, v2);
        return done(b);
    }

    // ============ INTERNAL WRITE FUNCTIONS ============

    function _writeUint(Builder memory b, uint256 value) private pure {
        if (value <= 127) {
            b.buffer[b.pos++] = bytes1(uint8(value));
        } else if (value <= type(uint8).max) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.UINT8);
            b.buffer[b.pos++] = bytes1(uint8(value));
        } else if (value <= type(uint16).max) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.UINT16);
            assembly ("memory-safe") {
                let ptr := add(add(mload(b), 32), mload(add(b, 32)))
                mstore8(ptr, shr(8, value))
                mstore8(add(ptr, 1), value)
            }
            b.pos += 2;
        } else if (value <= type(uint32).max) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.UINT32);
            assembly ("memory-safe") {
                let ptr := add(add(mload(b), 32), mload(add(b, 32)))
                mstore8(ptr, shr(24, value))
                mstore8(add(ptr, 1), shr(16, value))
                mstore8(add(ptr, 2), shr(8, value))
                mstore8(add(ptr, 3), value)
            }
            b.pos += 4;
        } else if (value <= type(uint64).max) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.UINT64);
            assembly ("memory-safe") {
                let ptr := add(add(mload(b), 32), mload(add(b, 32)))
                mstore8(ptr, shr(56, value))
                mstore8(add(ptr, 1), shr(48, value))
                mstore8(add(ptr, 2), shr(40, value))
                mstore8(add(ptr, 3), shr(32, value))
                mstore8(add(ptr, 4), shr(24, value))
                mstore8(add(ptr, 5), shr(16, value))
                mstore8(add(ptr, 6), shr(8, value))
                mstore8(add(ptr, 7), value)
            }
            b.pos += 8;
        } else {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.UINT256);
            assembly ("memory-safe") {
                let ptr := add(add(mload(b), 32), mload(add(b, 32)))
                mstore(ptr, value)
            }
            b.pos += 32;
        }
    }

    function _writeInt(Builder memory b, int256 value) private pure {
        if (value >= 0) {
            _writeUint(b, uint256(value));
        } else if (value >= -32) {
            b.buffer[b.pos++] = bytes1(
                uint8(SolidityPackTypes.FIXINT_NEG_BASE + uint8(int8(value + 32)))
            );
        } else if (value >= type(int8).min) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.INT8);
            b.buffer[b.pos++] = bytes1(uint8(int8(value)));
        } else {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.INT256);
            assembly ("memory-safe") {
                let ptr := add(add(mload(b), 32), mload(add(b, 32)))
                mstore(ptr, value)
            }
            b.pos += 32;
        }
    }

    function _writeAddr(Builder memory b, address value) private pure {
        b.buffer[b.pos++] = bytes1(SolidityPackTypes.ADDRESS);
        assembly ("memory-safe") {
            let ptr := add(add(mload(b), 32), mload(add(b, 32)))
            mstore(ptr, shl(96, value))
        }
        b.pos += 20;
    }

    function _writeString(Builder memory b, string memory value) private pure {
        bytes memory byt = bytes(value);
        uint256 len = byt.length;

        if (len <= 31) {
            b.buffer[b.pos++] = bytes1(uint8(SolidityPackTypes.FIXSTR_BASE + len));
        } else if (len <= 255) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.STR8);
            b.buffer[b.pos++] = bytes1(uint8(len));
        } else {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.STR16);
            b.buffer[b.pos++] = bytes1(uint8(len >> 8));
            b.buffer[b.pos++] = bytes1(uint8(len));
        }

        assembly ("memory-safe") {
            let src := add(byt, 32)
            let dst := add(add(mload(b), 32), mload(add(b, 32)))
            let end := add(src, len)

            for { } lt(src, end) { } {
                mstore(dst, mload(src))
                src := add(src, 32)
                dst := add(dst, 32)
            }
        }
        b.pos += len;
    }

    function _writeBytes(Builder memory b, bytes memory value) private pure {
        uint256 len = value.length;

        if (len <= 255) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.BYTES8);
            b.buffer[b.pos++] = bytes1(uint8(len));
        } else {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.BYTES16);
            b.buffer[b.pos++] = bytes1(uint8(len >> 8));
            b.buffer[b.pos++] = bytes1(uint8(len));
        }

        assembly ("memory-safe") {
            let src := add(value, 32)
            let dst := add(add(mload(b), 32), mload(add(b, 32)))
            let end := add(src, len)

            for { } lt(src, end) { } {
                mstore(dst, mload(src))
                src := add(src, 32)
                dst := add(dst, 32)
            }
        }
        b.pos += len;
    }

    function _writeBytes32(Builder memory b, bytes32 value) private pure {
        b.buffer[b.pos++] = bytes1(SolidityPackTypes.BYTES32_TYPE);
        assembly ("memory-safe") {
            let ptr := add(add(mload(b), 32), mload(add(b, 32)))
            mstore(ptr, value)
        }
        b.pos += 32;
    }

    function _writeArrayStart(Builder memory b, uint256 len) private pure {
        if (len <= 15) {
            b.buffer[b.pos++] = bytes1(uint8(SolidityPackTypes.FIXARRAY_BASE + len));
        } else if (len <= 255) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.ARRAY8);
            b.buffer[b.pos++] = bytes1(uint8(len));
        } else {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.ARRAY16);
            b.buffer[b.pos++] = bytes1(uint8(len >> 8));
            b.buffer[b.pos++] = bytes1(uint8(len));
        }
    }

    function _writeMapStart(Builder memory b, uint256 len) private pure {
        if (len <= 15) {
            b.buffer[b.pos++] = bytes1(uint8(SolidityPackTypes.FIXMAP_BASE + len));
        } else if (len <= 255) {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.MAP8);
            b.buffer[b.pos++] = bytes1(uint8(len));
        } else {
            b.buffer[b.pos++] = bytes1(SolidityPackTypes.MAP16);
            b.buffer[b.pos++] = bytes1(uint8(len >> 8));
            b.buffer[b.pos++] = bytes1(uint8(len));
        }
    }

    function _ensureSpace(Builder memory b, uint256 required) private pure {
        uint256 needed = b.pos + required;
        if (needed <= b.buffer.length) return;

        uint256 newSize = b.buffer.length * 2;
        if (newSize < needed) newSize = needed + 64;

        bytes memory newBuffer = new bytes(newSize);
        assembly ("memory-safe") {
            let src := add(mload(b), 32)
            let dst := add(newBuffer, 32)
            let len := mload(add(b, 32))
            let end := add(src, len)

            for { } lt(src, end) { } {
                mstore(dst, mload(src))
                src := add(src, 32)
                dst := add(dst, 32)
            }
        }
        b.buffer = newBuffer;
    }

    // ============ HELPER FUNCTIONS FOR SIMPLE ENCODING ============

    function _encodeUintFull(uint256 value) private pure returns (bytes memory) {
        if (value <= type(uint8).max) {
            bytes memory result = new bytes(2);
            result[0] = bytes1(SolidityPackTypes.UINT8);
            result[1] = bytes1(uint8(value));
            return result;
        }
        if (value <= type(uint16).max) {
            bytes memory result = new bytes(3);
            result[0] = bytes1(SolidityPackTypes.UINT16);
            result[1] = bytes1(uint8(value >> 8));
            result[2] = bytes1(uint8(value));
            return result;
        }
        if (value <= type(uint32).max) {
            bytes memory result = new bytes(5);
            result[0] = bytes1(SolidityPackTypes.UINT32);
            assembly ("memory-safe") {
                let ptr := add(result, 33)
                mstore8(ptr, shr(24, value))
                mstore8(add(ptr, 1), shr(16, value))
                mstore8(add(ptr, 2), shr(8, value))
                mstore8(add(ptr, 3), value)
            }
            return result;
        }
        // Full uint256
        bytes memory result = new bytes(33);
        result[0] = bytes1(SolidityPackTypes.UINT256);
        assembly ("memory-safe") {
            mstore(add(result, 33), value)
        }
        return result;
    }

    function _encodeIntFull(int256 value) private pure returns (bytes memory) {
        if (value >= 0) return _encodeUintFull(uint256(value));

        if (value >= -32) {
            bytes memory result = new bytes(1);
            result[0] = bytes1(uint8(SolidityPackTypes.FIXINT_NEG_BASE + uint8(int8(value + 32))));
            return result;
        }

        bytes memory result = new bytes(33);
        result[0] = bytes1(SolidityPackTypes.INT256);
        assembly ("memory-safe") {
            mstore(add(result, 33), value)
        }
        return result;
    }

    function _encodeStringDirect(string memory value) private pure returns (bytes memory) {
        bytes memory byt = bytes(value);
        uint256 len = byt.length;
        bytes memory result;

        if (len <= 31) {
            result = new bytes(len + 1);
            result[0] = bytes1(uint8(SolidityPackTypes.FIXSTR_BASE + len));
            for (uint256 i = 0; i < len; i++) {
                result[i + 1] = byt[i];
            }
        } else if (len <= 255) {
            result = new bytes(len + 2);
            result[0] = bytes1(SolidityPackTypes.STR8);
            result[1] = bytes1(uint8(len));
            for (uint256 i = 0; i < len; i++) {
                result[i + 2] = byt[i];
            }
        } else {
            result = new bytes(len + 3);
            result[0] = bytes1(SolidityPackTypes.STR16);
            result[1] = bytes1(uint8(len >> 8));
            result[2] = bytes1(uint8(len));
            for (uint256 i = 0; i < len; i++) {
                result[i + 3] = byt[i];
            }
        }
        return result;
    }

    function _encodeBytesDirect(bytes memory value) private pure returns (bytes memory) {
        uint256 len = value.length;
        bytes memory result;

        if (len <= 255) {
            result = new bytes(len + 2);
            result[0] = bytes1(SolidityPackTypes.BYTES8);
            result[1] = bytes1(uint8(len));
            for (uint256 i = 0; i < len; i++) {
                result[i + 2] = value[i];
            }
        } else {
            result = new bytes(len + 3);
            result[0] = bytes1(SolidityPackTypes.BYTES16);
            result[1] = bytes1(uint8(len >> 8));
            result[2] = bytes1(uint8(len));
            for (uint256 i = 0; i < len; i++) {
                result[i + 3] = value[i];
            }
        }
        return result;
    }

    // Compatibility with old API
    function _new() private pure returns (SolidityPackTypes.Encoder memory) {
        return SolidityPackTypes.Encoder(new bytes(256), 0);
    }

    function _uint(SolidityPackTypes.Encoder memory e, uint256 v) private pure {
        _ensureCapacityOld(e, 33);
        _writeUintOld(e, v);
    }

    function _addr(SolidityPackTypes.Encoder memory e, address v) private pure {
        _ensureCapacityOld(e, 21);
        e.buffer[e.pos++] = bytes1(SolidityPackTypes.ADDRESS);
        assembly ("memory-safe") {
            let ptr := add(add(mload(e), 32), mload(add(e, 32)))
            mstore(ptr, shl(96, v))
        }
        e.pos += 20;
    }

    function _done(SolidityPackTypes.Encoder memory e) private pure returns (bytes memory) {
        bytes memory result = new bytes(e.pos);
        assembly ("memory-safe") {
            let src := add(mload(e), 32)
            let dst := add(result, 32)
            let len := mload(add(e, 32))
            let end := add(src, len)

            for { } lt(src, end) { } {
                mstore(dst, mload(src))
                src := add(src, 32)
                dst := add(dst, 32)
            }
        }
        return result;
    }

    function _writeUintOld(SolidityPackTypes.Encoder memory e, uint256 value) private pure {
        if (value <= 127) {
            e.buffer[e.pos++] = bytes1(uint8(value));
        } else if (value <= type(uint8).max) {
            e.buffer[e.pos++] = bytes1(SolidityPackTypes.UINT8);
            e.buffer[e.pos++] = bytes1(uint8(value));
        } else if (value <= type(uint32).max) {
            e.buffer[e.pos++] = bytes1(SolidityPackTypes.UINT32);
            assembly ("memory-safe") {
                let ptr := add(add(mload(e), 32), mload(add(e, 32)))
                mstore8(ptr, shr(24, value))
                mstore8(add(ptr, 1), shr(16, value))
                mstore8(add(ptr, 2), shr(8, value))
                mstore8(add(ptr, 3), value)
            }
            e.pos += 4;
        } else {
            e.buffer[e.pos++] = bytes1(SolidityPackTypes.UINT256);
            assembly ("memory-safe") {
                let ptr := add(add(mload(e), 32), mload(add(e, 32)))
                mstore(ptr, value)
            }
            e.pos += 32;
        }
    }

    function _ensureCapacityOld(SolidityPackTypes.Encoder memory e, uint256 required) private pure {
        uint256 needed = e.pos + required;
        if (needed <= e.buffer.length) return;

        uint256 newSize = e.buffer.length * 2;
        if (newSize < needed) newSize = needed + 64;

        bytes memory newBuffer = new bytes(newSize);
        assembly ("memory-safe") {
            let src := add(mload(e), 32)
            let dst := add(newBuffer, 32)
            let len := mload(add(e, 32))
            let end := add(src, len)

            for { } lt(src, end) { } {
                mstore(dst, mload(src))
                src := add(src, 32)
                dst := add(dst, 32)
            }
        }
        e.buffer = newBuffer;
    }
}
