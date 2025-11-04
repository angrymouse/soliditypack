// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SolidityPackEncoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title ImprovedAPIExample
 * @notice Demonstrates the improved Solidity API for encoding objects
 * @dev Shows both the old verbose way and the new concise way
 */
contract ImprovedAPIExample {

    /**
     * @notice OLD WAY: Verbose encoding with separate key and value calls
     * @dev Requires 2 lines per field (encodeKey + encodeValue)
     */
    function encodeUserDataOldWay() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Start object with 4 fields
        SolidityPackEncoder.startObject(enc, 4);

        // Each field requires 2 lines
        SolidityPackEncoder.encodeKey(enc, "name");
        SolidityPackEncoder.encodeString(enc, "Alice");

        SolidityPackEncoder.encodeKey(enc, "age");
        SolidityPackEncoder.encodeUint(enc, 30);

        SolidityPackEncoder.encodeKey(enc, "active");
        SolidityPackEncoder.encodeBool(enc, true);

        SolidityPackEncoder.encodeKey(enc, "balance");
        SolidityPackEncoder.encodeUint(enc, 1000000);

        return SolidityPackEncoder.getEncoded(enc);
    }

    /**
     * @notice NEW WAY: Concise encoding with combined field functions
     * @dev Requires only 1 line per field - 50% reduction!
     */
    function encodeUserDataNewWay() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 4);

        // Each field is just one line now!
        SolidityPackEncoder.encodeFieldString(enc, "name", "Alice");
        SolidityPackEncoder.encodeFieldUint(enc, "age", 30);
        SolidityPackEncoder.encodeFieldBool(enc, "active", true);
        SolidityPackEncoder.encodeFieldUint(enc, "balance", 1000000);

        return SolidityPackEncoder.getEncoded(enc);
    }

    /**
     * @notice Example with complex types including arrays and addresses
     */
    function encodeComplexObject() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Create some test data
        uint256[] memory scores = new uint256[](3);
        scores[0] = 95;
        scores[1] = 87;
        scores[2] = 92;

        address[] memory addresses = new address[](2);
        addresses[0] = 0x742d35cC6634c0532925A3b844bc9E7595F0beB1;
        addresses[1] = 0x1234567890123456789012345678901234567890;

        SolidityPackEncoder.startObject(enc, 5);

        // Clean and concise object encoding
        SolidityPackEncoder.encodeFieldString(enc, "name", "Bob");
        SolidityPackEncoder.encodeFieldAddress(enc, "wallet", 0x742d35cC6634c0532925A3b844bc9E7595F0beB1);
        SolidityPackEncoder.encodeFieldBytes32(enc, "hash", keccak256("test"));
        SolidityPackEncoder.encodeFieldUintArray(enc, "scores", scores);
        SolidityPackEncoder.encodeFieldAddressArray(enc, "contacts", addresses);

        return SolidityPackEncoder.getEncoded(enc);
    }

    /**
     * @notice Nested object example - you can still use manual control for nesting
     */
    function encodeNestedObject() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 3);

        // Simple fields
        SolidityPackEncoder.encodeFieldString(enc, "userId", "user123");
        SolidityPackEncoder.encodeFieldUint(enc, "version", 1);

        // Nested object - use encodeKey + startObject
        SolidityPackEncoder.encodeKey(enc, "settings");
        SolidityPackEncoder.startObject(enc, 2);
        SolidityPackEncoder.encodeFieldBool(enc, "notifications", true);
        SolidityPackEncoder.encodeFieldString(enc, "theme", "dark");

        return SolidityPackEncoder.getEncoded(enc);
    }

    /**
     * @notice Real-world example: Encode transaction data
     */
    function encodeTransaction(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes32 txHash
    ) public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 5);
        SolidityPackEncoder.encodeFieldAddress(enc, "from", from);
        SolidityPackEncoder.encodeFieldAddress(enc, "to", to);
        SolidityPackEncoder.encodeFieldUint(enc, "amount", amount);
        SolidityPackEncoder.encodeFieldUint(enc, "nonce", nonce);
        SolidityPackEncoder.encodeFieldBytes32(enc, "txHash", txHash);

        return SolidityPackEncoder.getEncoded(enc);
    }
}
