// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SolidityPackEncoder.sol";
import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";
import "../examples/ImprovedAPIExample.sol";

/**
 * @title ImprovedAPITest
 * @notice Tests for the improved field encoding API
 */
contract ImprovedAPITest {

    ImprovedAPIExample example;

    function setUp() public {
        example = new ImprovedAPIExample();
    }

    /**
     * @notice Test that old way and new way produce identical output
     */
    function testOldVsNewWayIdentical() public view {
        bytes memory oldWay = example.encodeUserDataOldWay();
        bytes memory newWay = example.encodeUserDataNewWay();

        require(keccak256(oldWay) == keccak256(newWay), "Old and new way should produce identical output");
        require(oldWay.length == newWay.length, "Lengths should match");
    }

    /**
     * @notice Test that new way can be decoded correctly
     */
    function testNewWayDecodes() public view {
        bytes memory encoded = example.encodeUserDataNewWay();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(mapLen == 4, "Should have 4 fields");

        string memory name;
        uint256 age;
        bool active;
        uint256 balance;

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("name")) {
                name = SolidityPackDecoder.decodeString(dec);
            } else if (keccak256(bytes(key)) == keccak256("age")) {
                age = SolidityPackDecoder.decodeUint(dec);
            } else if (keccak256(bytes(key)) == keccak256("active")) {
                active = SolidityPackDecoder.decodeBool(dec);
            } else if (keccak256(bytes(key)) == keccak256("balance")) {
                balance = SolidityPackDecoder.decodeUint(dec);
            }
        }

        require(keccak256(bytes(name)) == keccak256("Alice"), "Name should be Alice");
        require(age == 30, "Age should be 30");
        require(active == true, "Active should be true");
        require(balance == 1000000, "Balance should be 1000000");
    }

    /**
     * @notice Test encodeFieldUint
     */
    function testEncodeFieldUint() public pure {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 1);
        SolidityPackEncoder.encodeFieldUint(enc, "count", 42);

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(mapLen == 1, "Should have 1 field");

        string memory key = SolidityPackDecoder.decodeString(dec);
        require(keccak256(bytes(key)) == keccak256("count"), "Key should be 'count'");

        uint256 value = SolidityPackDecoder.decodeUint(dec);
        require(value == 42, "Value should be 42");
    }

    /**
     * @notice Test encodeFieldString
     */
    function testEncodeFieldString() public pure {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 1);
        SolidityPackEncoder.encodeFieldString(enc, "message", "hello");

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        SolidityPackDecoder.decodeMapLength(dec);
        SolidityPackDecoder.decodeString(dec); // skip key

        string memory value = SolidityPackDecoder.decodeString(dec);
        require(keccak256(bytes(value)) == keccak256("hello"), "Value should be 'hello'");
    }

    /**
     * @notice Test encodeFieldAddress
     */
    function testEncodeFieldAddress() public pure {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        address testAddr = 0x742d35cC6634c0532925A3b844bc9E7595F0beB1;
        SolidityPackEncoder.startObject(enc, 1);
        SolidityPackEncoder.encodeFieldAddress(enc, "wallet", testAddr);

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        SolidityPackDecoder.decodeMapLength(dec);
        SolidityPackDecoder.decodeString(dec); // skip key

        address value = SolidityPackDecoder.decodeAddress(dec);
        require(value == testAddr, "Address should match");
    }

    /**
     * @notice Test encodeFieldBool
     */
    function testEncodeFieldBool() public pure {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startObject(enc, 2);
        SolidityPackEncoder.encodeFieldBool(enc, "isActive", true);
        SolidityPackEncoder.encodeFieldBool(enc, "isPaused", false);

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        SolidityPackDecoder.decodeMapLength(dec);

        SolidityPackDecoder.decodeString(dec); // skip key
        bool val1 = SolidityPackDecoder.decodeBool(dec);

        SolidityPackDecoder.decodeString(dec); // skip key
        bool val2 = SolidityPackDecoder.decodeBool(dec);

        require(val1 == true, "First value should be true");
        require(val2 == false, "Second value should be false");
    }

    /**
     * @notice Test encodeFieldBytes32
     */
    function testEncodeFieldBytes32() public pure {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        bytes32 testHash = keccak256("test");
        SolidityPackEncoder.startObject(enc, 1);
        SolidityPackEncoder.encodeFieldBytes32(enc, "hash", testHash);

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        SolidityPackDecoder.decodeMapLength(dec);
        SolidityPackDecoder.decodeString(dec); // skip key

        bytes32 value = SolidityPackDecoder.decodeBytes32(dec);
        require(value == testHash, "Hash should match");
    }

    /**
     * @notice Test encodeFieldUintArray
     */
    function testEncodeFieldUintArray() public pure {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 10;
        numbers[1] = 20;
        numbers[2] = 30;

        SolidityPackEncoder.startObject(enc, 1);
        SolidityPackEncoder.encodeFieldUintArray(enc, "numbers", numbers);

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        SolidityPackDecoder.decodeMapLength(dec);
        SolidityPackDecoder.decodeString(dec); // skip key

        uint256 arrayLen = SolidityPackDecoder.decodeArrayLength(dec);
        require(arrayLen == 3, "Array should have 3 elements");

        require(SolidityPackDecoder.decodeUint(dec) == 10, "First element should be 10");
        require(SolidityPackDecoder.decodeUint(dec) == 20, "Second element should be 20");
        require(SolidityPackDecoder.decodeUint(dec) == 30, "Third element should be 30");
    }

    /**
     * @notice Test encodeFieldAddressArray
     */
    function testEncodeFieldAddressArray() public pure {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        address[] memory addrs = new address[](2);
        addrs[0] = 0x742d35cC6634c0532925A3b844bc9E7595F0beB1;
        addrs[1] = 0x1234567890123456789012345678901234567890;

        SolidityPackEncoder.startObject(enc, 1);
        SolidityPackEncoder.encodeFieldAddressArray(enc, "contacts", addrs);

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        SolidityPackDecoder.decodeMapLength(dec);
        SolidityPackDecoder.decodeString(dec); // skip key

        uint256 arrayLen = SolidityPackDecoder.decodeArrayLength(dec);
        require(arrayLen == 2, "Array should have 2 elements");

        require(SolidityPackDecoder.decodeAddress(dec) == addrs[0], "First address should match");
        require(SolidityPackDecoder.decodeAddress(dec) == addrs[1], "Second address should match");
    }

    /**
     * @notice Test complex object encoding
     */
    function testComplexObject() public view {
        bytes memory encoded = example.encodeComplexObject();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(mapLen == 5, "Should have 5 fields");

        // Just verify it decodes without error
        for (uint256 i = 0; i < mapLen; i++) {
            SolidityPackDecoder.decodeString(dec); // key
            SolidityPackDecoder.skip(dec); // value (any type)
        }
    }

    /**
     * @notice Test nested object encoding
     */
    function testNestedObject() public view {
        bytes memory encoded = example.encodeNestedObject();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);

        uint256 outerMapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(outerMapLen == 3, "Should have 3 fields in outer object");

        // Skip to nested object
        SolidityPackDecoder.decodeString(dec); // userId key
        SolidityPackDecoder.decodeString(dec); // userId value
        SolidityPackDecoder.decodeString(dec); // version key
        SolidityPackDecoder.decodeUint(dec);   // version value
        SolidityPackDecoder.decodeString(dec); // settings key

        // Decode nested object
        uint256 innerMapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(innerMapLen == 2, "Nested object should have 2 fields");
    }
}
