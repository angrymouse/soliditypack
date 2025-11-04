// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SolidityPackEncoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title MinimalContractOldAPI
 * @notice Minimal contract using the OLD verbose API
 * @dev Used to measure bytecode size impact
 */
contract MinimalContractOldAPI {
    function encode() external pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 3);

        SolidityPackEncoder.encodeKey(enc, "name");
        SolidityPackEncoder.encodeString(enc, "Alice");

        SolidityPackEncoder.encodeKey(enc, "age");
        SolidityPackEncoder.encodeUint(enc, 30);

        SolidityPackEncoder.encodeKey(enc, "balance");
        SolidityPackEncoder.encodeUint(enc, 1000000);

        return SolidityPackEncoder.getEncoded(enc);
    }
}

/**
 * @title MinimalContractNewAPI
 * @notice Minimal contract using the NEW convenience API
 * @dev Used to measure bytecode size impact
 */
contract MinimalContractNewAPI {
    function encode() external pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 3);

        SolidityPackEncoder.encodeFieldString(enc, "name", "Alice");
        SolidityPackEncoder.encodeFieldUint(enc, "age", 30);
        SolidityPackEncoder.encodeFieldUint(enc, "balance", 1000000);

        return SolidityPackEncoder.getEncoded(enc);
    }
}

/**
 * HOW TO MEASURE BYTECODE SIZE:
 *
 * 1. Compile both contracts:
 *    npx hardhat compile
 *
 * 2. Check artifact sizes:
 *    ls -lh artifacts/contracts/examples/BytecodeSizeDemo.sol/
 *
 * 3. Or programmatically:
 *    const oldAPI = await ethers.getContractFactory("MinimalContractOldAPI");
 *    const newAPI = await ethers.getContractFactory("MinimalContractNewAPI");
 *    console.log("Old API bytecode:", oldAPI.bytecode.length / 2, "bytes");
 *    console.log("New API bytecode:", newAPI.bytecode.length / 2, "bytes");
 *
 * EXPECTED RESULT:
 * Both contracts should have IDENTICAL or nearly identical bytecode size
 * because the optimizer inlines the convenience functions.
 *
 * The convenience functions are simple wrappers:
 *   function encodeFieldString(enc, key, value) {
 *       encodeKey(enc, key);
 *       return encodeString(enc, value);
 *   }
 *
 * The Solidity optimizer (runs: 200) will:
 * 1. Inline these tiny functions
 * 2. Result in the same machine code as calling encodeKey + encodeString directly
 * 3. Zero runtime gas overhead
 * 4. Minimal to zero bytecode size increase
 */
