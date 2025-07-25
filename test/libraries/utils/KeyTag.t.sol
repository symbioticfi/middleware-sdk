// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {KeyTags} from "../../../src/libraries/utils/KeyTags.sol";

contract KeyTagTest is Test {
    using KeyTags for uint128;
    using KeyTags for uint8;

    function setUp() public {}

    function test_GetKeyTagValid() public {
        uint8 type_ = 3;
        uint8 identifier = 10;
        uint8 keyTag = KeyTags.getKeyTag(type_, identifier);

        assertEq(keyTag, 0x3A);
    }

    function test_GetKeyTagInvalidType() public {
        uint8 type_ = 8;
        uint8 identifier = 2;

        vm.expectRevert(KeyTags.InvalidKeyType.selector);
        this.getKeyTag(type_, identifier);
    }

    function getKeyTag(uint8 type_, uint8 identifier) public pure returns (uint8) {
        return KeyTags.getKeyTag(type_, identifier);
    }

    function test_GetKeyTagInvalidIdentifier() public {
        uint8 type_ = 3;
        uint8 identifier = 16;

        vm.expectRevert(KeyTags.InvalidKeyTag.selector);
        this.getKeyTag(type_, identifier);
    }

    function test_GetType() public {
        uint8 keyTag = 0x6F;
        uint8 expectedType = 6;
        uint8 resultType = KeyTags.getType(keyTag);
        assertEq(resultType, expectedType);
    }

    function test_GetTag() public {
        uint8 keyTag = 0x6F;
        uint8 expectedTag = 15;
        uint8 resultTag = KeyTags.getTag(keyTag);
        assertEq(resultTag, expectedTag);
    }

    function test_GetTypeRevertWhenTooLarge() public {
        uint8 invalid = 128;

        vm.expectRevert(KeyTags.InvalidKeyTag.selector);
        this.getType(invalid);
    }

    function getType(
        uint8 keyTag
    ) public pure returns (uint8) {
        return KeyTags.getType(keyTag);
    }

    function test_GetTagRevertWhenTooLarge() public {
        uint8 invalid = 130;

        vm.expectRevert(KeyTags.InvalidKeyTag.selector);
        this.getTag(invalid);
    }

    function getTag(
        uint8 keyTag
    ) public pure returns (uint8) {
        return KeyTags.getTag(keyTag);
    }

    function test_ContainsAddRemove() public {
        uint128 bitmask = 0;

        uint8 keyTag = 10;
        assertFalse(bitmask.contains(keyTag));

        bitmask = bitmask.add(keyTag);
        assertTrue(bitmask.contains(keyTag));

        bitmask = bitmask.remove(keyTag);
        assertFalse(bitmask.contains(keyTag));
    }

    function test_AddMultiple() public {
        uint128 bitmask;
        bitmask = bitmask.add(2);
        bitmask = bitmask.add(5);
        bitmask = bitmask.add(127);

        assertTrue(bitmask.contains(2));
        assertTrue(bitmask.contains(5));
        assertTrue(bitmask.contains(127));

        assertFalse(bitmask.contains(3));
        assertFalse(bitmask.contains(126));
        assertFalse(bitmask.contains(125));
    }

    function test_SerializeUniqueKeyTags() public {
        uint8[] memory tags = new uint8[](4);
        tags[0] = 0;
        tags[1] = 2;
        tags[2] = 5;
        tags[3] = 10;

        uint128 bitmask = KeyTags.serialize(tags);

        assertTrue(bitmask.contains(0));
        assertTrue(bitmask.contains(2));
        assertTrue(bitmask.contains(5));
        assertTrue(bitmask.contains(10));

        assertFalse(bitmask.contains(1));
        assertFalse(bitmask.contains(3));
        assertFalse(bitmask.contains(11));
    }

    function serialize(
        uint8[] memory tags
    ) public pure returns (uint128) {
        return KeyTags.serialize(tags);
    }

    function test_SerializeRevertOnDuplicate() public {
        uint8[] memory tags = new uint8[](3);
        tags[0] = 2;
        tags[1] = 2;
        tags[2] = 5;

        vm.expectRevert(KeyTags.DuplicateKeyTag.selector);
        this.serialize(tags);
    }

    function test_DeserializeBitmask() public {
        uint128 bitmask;
        bitmask = bitmask.add(3);
        bitmask = bitmask.add(10);
        bitmask = bitmask.add(127);

        uint8[] memory tags = KeyTags.deserialize(bitmask);

        assertEq(tags.length, 3, "expected 3 tags in the array");
        assertEq(tags[0], 3);
        assertEq(tags[1], 10);
        assertEq(tags[2], 127);
    }
}
