# MessagePack Compatibility

SolidityPack uses the [MessagePack](https://msgpack.org/) binary serialization format as its foundation, with extensions for Ethereum-specific types and large integers required by Solidity.

## Overview

- **Basic Types**: Fully compatible with standard MessagePack
- **Ethereum Extensions**: Custom type codes for blockchain-specific types
- **Large Integers**: Extended integer types (uint128, uint256, int128, int256)
- **No Floats**: Solidity doesn't support floating-point, so SolidityPack doesn't either

## Standard MessagePack Types

These types use the official MessagePack specification and are fully compatible with any MessagePack decoder:

### Integers

#### Positive Integers
- **Positive FixInt** (0x00-0x7F): Values 0-127
- **uint8** (0xC4): 8-bit unsigned (0-255)
- **uint16** (0xC5): 16-bit unsigned (0-65535)
- **uint32** (0xC6): 32-bit unsigned (0-4294967295)

#### Negative Integers
- **Negative FixInt** (0xE0-0xFF): Values -32 to -1
- **int8** (0xCA): 8-bit signed (-128 to 127)
- **int16** (0xCB): 16-bit signed (-32768 to 32767)
- **int32** (0xCC): 32-bit signed (-2147483648 to 2147483647)

### Strings
- **FixStr** (0xA0-0xBF): Strings up to 31 bytes
- **str8** (0xD2): Strings up to 255 bytes
- **str16** (0xD3): Strings up to 65535 bytes

All strings use UTF-8 encoding.

### Boolean & Null
- **false** (0xC2)
- **true** (0xC3)
- **nil** (0xC0)

### Arrays
- **FixArray** (0x90-0x9F): Arrays with 0-15 elements
- **array8** (0xD6): Arrays up to 255 elements
- **array16** (0xD7): Arrays up to 65535 elements

### Maps/Objects
- **FixMap** (0x80-0x8F): Maps with 0-15 key-value pairs
- **map8** (0xD8): Maps up to 255 key-value pairs
- **map16** (0xD9): Maps up to 65535 key-value pairs

### Binary Data
- **bin8** (0xD0): Byte arrays up to 255 bytes
- **bin16** (0xD1): Byte arrays up to 65535 bytes

## SolidityPack Extensions

These types extend MessagePack to support Ethereum and Solidity's large integer types. Standard MessagePack decoders will not recognize these type codes.

### Large Unsigned Integers
- **uint64** (0xC7): 64-bit unsigned integer (8 bytes)
- **uint128** (0xC8): 128-bit unsigned integer (16 bytes)
- **uint256** (0xC9): 256-bit unsigned integer (32 bytes)

Used for large numbers common in Solidity, such as token balances and wei amounts.

**Example:**
```javascript
// Encoding 1.5 ETH in wei (1500000000000000000)
const amount = 1500000000000000000n;
encode({ amount });
// Decodes back to BigInt: 1500000000000000000n
```

### Large Signed Integers
- **int64** (0xCD): 64-bit signed integer (8 bytes)
- **int128** (0xCE): 128-bit signed integer (16 bytes)
- **int256** (0xCF): 256-bit signed integer (32 bytes)

### Ethereum-Specific Types

#### Address (0xD4)
20-byte Ethereum addresses.

**Format:** 1 byte type code + 20 bytes address data

**Example:**
```javascript
encode({
  to: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1'
});
// Returns as lowercase hex string with 0x prefix
```

```solidity
SolidityPackEncoder.encodeAddress(enc, 0x742d35cC6634c0532925A3b844bc9E7595F0beB1);
```

#### Bytes32 (0xD5)
32-byte fixed-size arrays, commonly used for hashes, transaction IDs, and fixed keys.

**Format:** 1 byte type code + 32 bytes data

**Example:**
```javascript
encode({
  txHash: '0x1234....' // 32-byte hash
});
```

```solidity
bytes32 hash = keccak256("data");
SolidityPackEncoder.encodeBytes32(enc, hash);
```

## Compatibility Matrix

| Type | MessagePack Standard | SolidityPack | Can Decode with Standard MP? |
|------|---------------------|--------------|------------------------------|
| Integers (up to int32/uint32) | ✓ | ✓ | Yes |
| Integers (int64/uint64) | ✓ | ✓ | Yes* |
| Integers (128-bit, 256-bit) | ✗ | ✓ | No |
| Strings | ✓ | ✓ | Yes |
| Boolean | ✓ | ✓ | Yes |
| Null/Nil | ✓ | ✓ | Yes |
| Arrays | ✓ | ✓ | Yes** |
| Maps/Objects | ✓ | ✓ | Yes** |
| Binary Data | ✓ | ✓ | Yes |
| Float/Double | ✓ | ✗ | N/A |
| Address | ✗ | ✓ | No |
| Bytes32 | ✗ | ✓ | No |

\* If the MessagePack library supports 64-bit integers
\** As long as elements don't contain extended types

## Decoding SolidityPack Data with Standard MessagePack

You can decode basic SolidityPack-encoded data with any standard MessagePack library, as long as the data doesn't contain:
- Integers larger than 64-bit (uint128, uint256, int128, int256)
- Ethereum addresses (address type)
- Bytes32 values

### Example: Compatible Data

```javascript
// This data is fully MessagePack compatible
const data = {
  name: "Alice",
  age: 30,
  active: true,
  roles: ["admin", "user"]
};

const encoded = encode(data);
// Can be decoded by any MessagePack library
```

### Example: Extended Data

```javascript
// This data requires SolidityPack decoder
const tx = {
  from: "0x742d35cC6634c0532925A3b844bc9E7595F0beB1", // address
  amount: 1500000000000000000n, // uint256
  confirmed: false
};

const encoded = encode(tx);
// Requires SolidityPack decoder for 'from' and 'amount' fields
```

## Encoding Format Details

### Integer Encoding Strategy

SolidityPack automatically selects the most compact encoding:

**Unsigned:**
- 0-127 → FixInt (1 byte)
- 128-255 → uint8 (2 bytes)
- 256-65535 → uint16 (3 bytes)
- 65536-4294967295 → uint32 (5 bytes)
- Larger → uint64/uint128/uint256 as needed

**Signed:**
- -32 to 127 → FixInt (1 byte)
- -128 to -33 → int8 (2 bytes)
- -32768 to -129 → int16 (3 bytes)
- -2147483648 to -32769 → int32 (5 bytes)
- Smaller → int256 (33 bytes)

### String Encoding

Strings are UTF-8 encoded:
- 0-31 bytes → FixStr (1 + length bytes)
- 32-255 bytes → str8 (2 + length bytes)
- 256-65535 bytes → str16 (3 + length bytes)

### Array Encoding

Arrays encode their length followed by elements:
- 0-15 items → FixArray (1 byte header)
- 16-255 items → array8 (2 byte header)
- 256-65535 items → array16 (3 byte header)

### Map Encoding

Maps encode their count followed by key-value pairs:
- 0-15 pairs → FixMap (1 byte header)
- 16-255 pairs → map8 (2 byte header)
- 256-65535 pairs → map16 (3 byte header)

## Why MessagePack?

MessagePack was chosen as the foundation for several reasons:

1. **Compact**: 30-50% smaller than JSON for typical data
2. **Standardized**: Well-documented specification with libraries in many languages
3. **Self-describing**: Type information embedded in the format
4. **Efficient**: Fast encoding/decoding with minimal overhead
5. **Extensible**: Easy to add custom types while maintaining backward compatibility

## Limitations

### No Floating Point

Solidity does not support floating-point numbers, so SolidityPack doesn't either. Attempting to encode a JavaScript float will throw an error:

```javascript
encode({ value: 3.14 }); // Error: Floats not supported
```

Use integers or fixed-point math instead:

```javascript
// Store as basis points (1/100th of a percent)
encode({ interestRate: 314 }); // Represents 3.14%
```

### Map Keys Must Be Strings

In Solidity and JavaScript, SolidityPack only supports string keys for maps/objects:

```javascript
// ✓ Supported
encode({ name: "Alice" });

// ✗ Not supported
encode({ [123]: "value" }); // Numeric keys will be converted to strings
```

### No Timestamps

MessagePack has extension types for timestamps, but SolidityPack does not implement them. Use Unix timestamps as uint256 instead:

```javascript
encode({
  timestamp: Math.floor(Date.now() / 1000) // Unix timestamp as integer
});
```

## Future Compatibility

Future versions may add:
- **Extension types**: Custom user-defined types using MessagePack ext format
- **Larger maps/arrays**: Support for map32/array32 (16M+ elements)
- **Timestamps**: Native timestamp support as MessagePack extension

These additions will maintain backward compatibility with existing encoded data.

## References

- **MessagePack Specification**: https://github.com/msgpack/msgpack/blob/master/spec.md
- **MessagePack Libraries**: https://msgpack.org/
- **Ethereum Yellow Paper**: For address and hash specifications
