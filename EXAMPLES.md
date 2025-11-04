# Examples

Comprehensive examples for using SolidityPack in both JavaScript and Solidity.

## Table of Contents

- [JavaScript Examples](#javascript-examples)
  - [Basic Encoding](#basic-encoding)
  - [Basic Decoding](#basic-decoding)
  - [Working with BigInt](#working-with-bigint)
  - [Ethereum Types](#ethereum-types)
  - [Nested Objects](#nested-objects)
  - [Type Inspection](#type-inspection)
  - [Selective Decoding](#selective-decoding)
- [Solidity Examples](#solidity-examples)
  - [Basic Encoding](#solidity-basic-encoding)
  - [Basic Decoding](#solidity-basic-decoding)
  - [User Profile Example](#user-profile-example)
  - [Transaction Example](#transaction-example)
  - [Array Helpers](#array-helpers)
  - [Field Helpers](#field-helpers)
- [Cross-Platform Examples](#cross-platform-examples)

---

## JavaScript Examples

### Basic Encoding

Encode simple JavaScript objects:

```javascript
import { encode, encodeToHex } from 'soliditypack';

// Simple object
const data = { test: 42, test2: [] };
const encoded = encode(data);
console.log('0x' + encoded.toString('hex'));
// Output: 0x82a4746573742aa5746573743290

// Using encodeToHex helper
const hex = encodeToHex({ name: 'Alice', age: 30 });
console.log(hex);
// Output: 0x82a46e616d65a5416c696365a36167651e
```

### Basic Decoding

Decode encoded data back to JavaScript objects:

```javascript
import { decode } from 'soliditypack';

const hex = '0x82a4746573742aa5746573743290';
const decoded = decode(hex);
console.log(decoded);
// Output: { test: 42, test2: [] }

// Decode from Buffer
const buffer = Buffer.from('82a4746573742aa5746573743290', 'hex');
const data = decode(buffer);
```

### Working with BigInt

Handle large numbers using JavaScript BigInt:

```javascript
import { encode, decode } from 'soliditypack';

// Encoding large numbers
const weiAmount = 1500000000000000000n; // 1.5 ETH in wei
const data = {
  recipient: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1',
  amount: weiAmount,
  timestamp: Date.now()
};

const encoded = encode(data);

// Decoding returns BigInt for large numbers
const decoded = decode(encoded);
console.log(decoded.amount); // 1500000000000000000n (BigInt)
console.log(typeof decoded.amount); // 'bigint'
```

### Ethereum Types

Work with Ethereum-specific types:

```javascript
import { encode, decode } from 'soliditypack';

const transaction = {
  from: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1',
  to: '0x1234567890123456789012345678901234567890',
  amount: 1500000000000000000n,
  nonce: 42,
  txHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
  confirmed: false
};

const encoded = encode(transaction);
const decoded = decode(encoded);

console.log('From:', decoded.from);
console.log('To:', decoded.to);
console.log('Amount:', decoded.amount);
console.log('TxHash:', decoded.txHash);
```

### Nested Objects

Encode and decode complex nested structures:

```javascript
import { encode, decode } from 'soliditypack';

const complexData = {
  user: {
    name: 'Alice',
    age: 30,
    settings: {
      theme: 'dark',
      notifications: true,
      privacy: {
        public: false,
        friends: ['Bob', 'Carol']
      }
    }
  },
  metadata: {
    created: 1234567890,
    tags: ['premium', 'verified']
  }
};

const encoded = encode(complexData);
const decoded = decode(encoded);
// Perfect round-trip - structure fully preserved
console.log(decoded.user.settings.privacy.friends); // ['Bob', 'Carol']
```

### Type Inspection

Inspect types during decoding:

```javascript
import { Decoder, TypeCategory } from 'soliditypack/decoder';

const data = encode([42, 'hello', true, null, [1, 2, 3]]);
const decoder = new Decoder(data);

// Check if there's more data
console.log(decoder.hasMore()); // true

// Peek at the next type without consuming it
const category = decoder.peekCategory();
if (category === TypeCategory.ARRAY) {
  const len = decoder.decodeArrayLength();
  console.log('Array with', len, 'elements');

  for (let i = 0; i < len; i++) {
    const itemCategory = decoder.peekCategory();
    console.log('Item', i, 'category:', itemCategory);
    const value = decoder.decode();
    console.log('Item', i, 'value:', value);
  }
}
```

### Selective Decoding

Skip unwanted fields during decoding:

```javascript
import { Decoder } from 'soliditypack/decoder';

const data = {
  id: 1,
  name: 'Alice',
  secretKey: 'sensitive-data',
  email: 'alice@example.com',
  internal: { debug: true, logs: [...] }
};

const encoded = encode(data);
const decoder = new Decoder(encoded);

const mapLen = decoder.decodeMapLength();
const result = {};

for (let i = 0; i < mapLen; i++) {
  const key = decoder.decodeString();

  if (key === 'id' || key === 'name' || key === 'email') {
    // Decode only the fields we want
    result[key] = decoder.decode();
  } else {
    // Skip unwanted fields (secretKey, internal)
    decoder.skip();
  }
}

console.log(result); // { id: 1, name: 'Alice', email: 'alice@example.com' }
```

### Manual Encoding

Use the Encoder class for fine-grained control:

```javascript
import { Encoder } from 'soliditypack/encoder';

const enc = new Encoder();

// Build: { test: 42, test2: [] }
enc.startMap(2);           // Map with 2 entries
enc.encodeString('test');  // Key
enc.encodeUint(42);        // Value
enc.encodeString('test2'); // Key
enc.startArray(0);         // Empty array value

const result = enc.getEncoded(); // Buffer
const hex = enc.toHex();         // Hex string
```

---

## Solidity Examples

### Solidity Basic Encoding

Encode data in Solidity:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackEncoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract MyEncoder {
    function encodeSimpleObject() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Encode: {test: 42, test2: []}
        SolidityPackEncoder.startObject(enc, 2);

        SolidityPackEncoder.encodeKey(enc, "test");
        SolidityPackEncoder.encodeUint(enc, 42);

        SolidityPackEncoder.encodeKey(enc, "test2");
        SolidityPackEncoder.startArray(enc, 0);

        return SolidityPackEncoder.getEncoded(enc);
    }

    function encodeBasicTypes() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startArray(enc, 5);
        SolidityPackEncoder.encodeBool(enc, true);
        SolidityPackEncoder.encodeUint(enc, 42);
        SolidityPackEncoder.encodeInt(enc, -100);
        SolidityPackEncoder.encodeString(enc, "hello");
        SolidityPackEncoder.encodeNil(enc);

        return SolidityPackEncoder.getEncoded(enc);
    }
}
```

### Solidity Basic Decoding

Decode data in Solidity:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract MyDecoder {
    function decodeSimpleObject(bytes memory data)
        public
        pure
        returns (uint256 testValue)
    {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("test")) {
                testValue = SolidityPackDecoder.decodeUint(dec);
            } else {
                // Skip unknown or unwanted fields
                SolidityPackDecoder.skip(dec);
            }
        }
    }
}
```

### User Profile Example

Complete example encoding and decoding a user profile:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackEncoder.sol";
import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract UserProfile {
    struct User {
        string name;
        uint256 age;
        address wallet;
        bool active;
    }

    function encodeUser(User memory user) public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 4);

        SolidityPackEncoder.encodeFieldString(enc, "name", user.name);
        SolidityPackEncoder.encodeFieldUint(enc, "age", user.age);
        SolidityPackEncoder.encodeFieldAddress(enc, "wallet", user.wallet);
        SolidityPackEncoder.encodeFieldBool(enc, "active", user.active);

        return SolidityPackEncoder.getEncoded(enc);
    }

    function decodeUser(bytes memory data)
        public
        pure
        returns (User memory user)
    {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("name")) {
                user.name = SolidityPackDecoder.decodeString(dec);
            } else if (keccak256(bytes(key)) == keccak256("age")) {
                user.age = SolidityPackDecoder.decodeUint(dec);
            } else if (keccak256(bytes(key)) == keccak256("wallet")) {
                user.wallet = SolidityPackDecoder.decodeAddress(dec);
            } else if (keccak256(bytes(key)) == keccak256("active")) {
                user.active = SolidityPackDecoder.decodeBool(dec);
            } else {
                SolidityPackDecoder.skip(dec);
            }
        }
    }
}
```

### Transaction Example

Encode Ethereum transaction data:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackEncoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract TransactionEncoder {
    function encodeTransaction(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes32 txHash,
        bool confirmed
    ) public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 6);

        SolidityPackEncoder.encodeFieldAddress(enc, "from", from);
        SolidityPackEncoder.encodeFieldAddress(enc, "to", to);
        SolidityPackEncoder.encodeFieldUint(enc, "amount", amount);
        SolidityPackEncoder.encodeFieldUint(enc, "nonce", nonce);
        SolidityPackEncoder.encodeFieldBytes32(enc, "txHash", txHash);
        SolidityPackEncoder.encodeFieldBool(enc, "confirmed", confirmed);

        return SolidityPackEncoder.getEncoded(enc);
    }
}
```

### Array Helpers

Use array encoding helpers:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackEncoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract ArrayExample {
    function encodeArrays() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Create arrays
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 10;
        numbers[1] = 20;
        numbers[2] = 30;

        address[] memory addresses = new address[](2);
        addresses[0] = 0x742d35cC6634c0532925A3b844bc9E7595F0beB1;
        addresses[1] = 0x1234567890123456789012345678901234567890;

        string[] memory strings = new string[](2);
        strings[0] = "hello";
        strings[1] = "world";

        // Encode as object with array fields
        SolidityPackEncoder.startObject(enc, 3);

        SolidityPackEncoder.encodeFieldUintArray(enc, "numbers", numbers);
        SolidityPackEncoder.encodeFieldAddressArray(enc, "addresses", addresses);
        SolidityPackEncoder.encodeFieldStringArray(enc, "strings", strings);

        return SolidityPackEncoder.getEncoded(enc);
    }
}
```

### Field Helpers

Using field encoding helpers for cleaner code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackEncoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract FieldHelpersExample {
    // Before: Verbose approach
    function encodeVerbose() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 3);

        SolidityPackEncoder.encodeKey(enc, "name");
        SolidityPackEncoder.encodeString(enc, "Alice");

        SolidityPackEncoder.encodeKey(enc, "balance");
        SolidityPackEncoder.encodeUint(enc, 1000000);

        SolidityPackEncoder.encodeKey(enc, "active");
        SolidityPackEncoder.encodeBool(enc, true);

        return SolidityPackEncoder.getEncoded(enc);
    }

    // After: Clean approach with field helpers
    function encodeConcise() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 3);

        SolidityPackEncoder.encodeFieldString(enc, "name", "Alice");
        SolidityPackEncoder.encodeFieldUint(enc, "balance", 1000000);
        SolidityPackEncoder.encodeFieldBool(enc, "active", true);

        return SolidityPackEncoder.getEncoded(enc);
    }
}
```

---

## Cross-Platform Examples

### Encode in Solidity, Decode in JavaScript

**Solidity Contract:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackEncoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract DataProvider {
    function getUserData() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 3);
        SolidityPackEncoder.encodeFieldString(enc, "name", "Alice");
        SolidityPackEncoder.encodeFieldUint(enc, "balance", 1000000);
        SolidityPackEncoder.encodeFieldBool(enc, "active", true);

        return SolidityPackEncoder.getEncoded(enc);
    }
}
```

**JavaScript Client:**
```javascript
import { decode } from 'soliditypack';
import { ethers } from 'ethers';

async function fetchUserData() {
  const contract = new ethers.Contract(address, abi, provider);

  // Get encoded data from contract
  const encodedData = await contract.getUserData();

  // Decode with SolidityPack
  const user = decode(encodedData);

  console.log(user);
  // Output: { name: 'Alice', balance: 1000000, active: true }
}
```

### Encode in JavaScript, Decode in Solidity

**JavaScript Client:**
```javascript
import { encode } from 'soliditypack';

const userData = {
  name: 'Bob',
  age: 25,
  wallet: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1'
};

const encoded = encode(userData);

// Send to contract
await contract.processUserData(encoded);
```

**Solidity Contract:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract DataConsumer {
    event UserProcessed(string name, uint256 age, address wallet);

    function processUserData(bytes memory data) public {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        string memory name;
        uint256 age;
        address wallet;

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("name")) {
                name = SolidityPackDecoder.decodeString(dec);
            } else if (keccak256(bytes(key)) == keccak256("age")) {
                age = SolidityPackDecoder.decodeUint(dec);
            } else if (keccak256(bytes(key)) == keccak256("wallet")) {
                wallet = SolidityPackDecoder.decodeAddress(dec);
            } else {
                SolidityPackDecoder.skip(dec);
            }
        }

        emit UserProcessed(name, age, wallet);
    }
}
```

### Full Round-Trip Example

**Test in JavaScript:**
```javascript
import { encode, decode } from 'soliditypack';
import { ethers } from 'ethers';

async function roundTripTest() {
  // 1. Create data in JavaScript
  const originalData = {
    user: 'Alice',
    amount: 1000000000000000000n, // 1 ETH
    recipient: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1'
  };

  // 2. Encode with SolidityPack
  const encoded = encode(originalData);
  console.log('Encoded:', '0x' + encoded.toString('hex'));

  // 3. Send to Solidity contract
  const tx = await contract.processAndReturn(encoded);
  await tx.wait();

  // 4. Contract processes and returns encoded data
  const returnedData = await contract.getProcessedData();

  // 5. Decode in JavaScript
  const decoded = decode(returnedData);
  console.log('Decoded:', decoded);

  // 6. Verify round-trip
  console.log('Match:',
    decoded.user === originalData.user &&
    decoded.amount === originalData.amount &&
    decoded.recipient === originalData.recipient.toLowerCase()
  );
}
```

---

## Common Patterns

### Error Handling

```javascript
import { encode, decode } from 'soliditypack';

try {
  const data = { value: 3.14 };
  encode(data); // Error: Floats not supported
} catch (error) {
  console.error('Encoding error:', error.message);
}

try {
  const invalid = Buffer.from('ff', 'hex'); // Invalid MessagePack
  decode(invalid);
} catch (error) {
  console.error('Decoding error:', error.message);
}
```

### Gas Optimization

Only import what you need in Solidity:

```solidity
// For encoding only (smaller bytecode)
import "soliditypack/contracts/SolidityPackEncoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

// For decoding only (smaller bytecode)
import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";
```

### Working with Events

```solidity
contract EventExample {
    event DataEncoded(bytes data);

    function logEncodedData(string memory name, uint256 value) public {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 2);
        SolidityPackEncoder.encodeFieldString(enc, "name", name);
        SolidityPackEncoder.encodeFieldUint(enc, "value", value);

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        emit DataEncoded(encoded);
    }
}
```

```javascript
// Listen for events and decode
contract.on('DataEncoded', (encodedData) => {
  const decoded = decode(encodedData);
  console.log('Event data:', decoded);
});
```

---

For more examples, see:
- `examples/` directory in the repository
- Test files in `contracts/test/`
- [NESTED_STRUCTURES.md](NESTED_STRUCTURES.md) for complex nesting examples
- [DECODE_GUIDE.md](DECODE_GUIDE.md) for advanced decoding techniques
