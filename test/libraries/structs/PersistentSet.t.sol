// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {PersistentSet} from "../../../src/libraries/structs/PersistentSet.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PersistentSetTest is Test {
    using PersistentSet for PersistentSet.Bytes32Set;
    using PersistentSet for PersistentSet.AddressSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    PersistentSet.AddressSet private addressSet;
    PersistentSet.Bytes32Set private bytes32Set;

    function setUp() public {}

    function test_AddressSetAddRemoveAndContains() public {
        address alice = address(0x123);
        address bob = address(0x456);

        bool addedAlice = addressSet.add(1, alice);
        assertTrue(addedAlice, "Should have added Alice the first time");
        assertTrue(addressSet.contains(alice), "Current set should contain Alice");

        assertFalse(addressSet.containsAt(0, alice, ""), "Alice was not added at key=0");
        assertFalse(addressSet.containsAt(0, alice), "Alice was not added at key=0");
        assertTrue(addressSet.containsAt(1, alice, ""), "Alice should be present at key=1");
        assertTrue(addressSet.containsAt(1, alice), "Alice should be present at key=1");

        bool addedBob = addressSet.add(1, bob);
        assertTrue(addedBob, "Should have added Bob the first time");
        assertTrue(addressSet.contains(bob), "Current set should contain Bob as well");
        assertEq(uint256(addressSet.length()), 2, "Length must be 2 in the latest state");

        assertTrue(addressSet.containsAt(1, alice, ""), "Alice present at key=1");
        assertTrue(addressSet.containsAt(1, alice), "Alice present at key=1");
        assertTrue(addressSet.containsAt(1, bob, ""), "Bob present at key=1");
        assertTrue(addressSet.containsAt(1, bob), "Bob present at key=1");

        bool removedAlice = addressSet.remove(2, alice);
        assertTrue(removedAlice, "Should have successfully removed Alice at key=2");
        assertEq(uint256(addressSet.length()), 1, "Length must be 1 after removing Alice");

        assertFalse(addressSet.contains(alice), "Alice should no longer be present in the current set");
        assertFalse(addressSet.containsAt(2, alice, ""), "Alice removed at key=2");
        assertFalse(addressSet.containsAt(2, alice), "Alice removed at key=2");
        assertTrue(addressSet.containsAt(2, bob, ""), "Bob is still in the set at key=2");
        assertTrue(addressSet.containsAt(2, bob), "Bob is still in the set at key=2");
        assertFalse(
            addressSet.containsAt(2, address(0x789), ""), "Non-existent address should not be in the set at key=2"
        );

        bool removedAliceAgain = addressSet.remove(2, alice);
        assertFalse(removedAliceAgain, "Removing a non-existent element should return false");

        bool addedBobAgain = addressSet.add(2, bob);
        assertFalse(addedBobAgain, "Adding an already-existing element returns false");

        assertFalse(addressSet.remove(2, address(0x789)), "Removing a non-existent element should return false");
    }

    function test_AddressSetLengthAndValuesAt() public {
        address alice = address(0xA1);
        address bob = address(0xB2);
        address carol = address(0xC3);

        addressSet.add(10, alice);
        addressSet.add(10, bob);
        assertEq(uint256(addressSet.length()), 2);

        addressSet.remove(11, bob);
        addressSet.add(11, carol);

        address[] memory currentValues = addressSet.values();
        assertEq(currentValues.length, 2);
        assertEq(currentValues[0], alice);
        assertEq(currentValues[1], carol);

        assertEq(uint256(addressSet.length()), 2);

        address[] memory valuesKey10 = addressSet.valuesAt(10);
        assertEq(valuesKey10.length, 2, "At key=10, we should have 2 addresses");

        bool foundAlice;
        bool foundBob;
        for (uint256 i; i < valuesKey10.length; ++i) {
            if (valuesKey10[i] == alice) foundAlice = true;
            if (valuesKey10[i] == bob) foundBob = true;
        }
        assertTrue(foundAlice, "Should have Alice at key=10");
        assertTrue(foundBob, "Should have Bob at key=10");
    }

    function test_AddressSetAllValues() public {
        address first = address(0x111);
        address second = address(0x222);

        addressSet.add(1, first);
        addressSet.add(2, second);
        addressSet.remove(3, first);

        address[] memory registered = addressSet.values();
        assertEq(registered.length, 1, "Currently only 'second' is registered");
        assertEq(registered[0], second, "Registered address should be second");
    }

    function test_Bytes32SetAddRemoveAndContains() public {
        bytes32 data1 = keccak256("data1");
        bytes32 data2 = keccak256("data2");

        bool addedData1 = bytes32Set.add(100, data1);
        assertTrue(addedData1, "Should have added data1");
        assertTrue(bytes32Set.contains(data1), "Current set should contain data1");

        bool addedData2 = bytes32Set.add(100, data2);
        assertTrue(addedData2, "Should have added data2");
        assertTrue(bytes32Set.contains(data2), "Current set should contain data2");

        assertEq(uint256(bytes32Set.length()), 2);

        bool removedData1 = bytes32Set.remove(101, data1);
        assertTrue(removedData1, "Should have removed data1 at key=101");
        assertFalse(bytes32Set.contains(data1), "data1 should not be in the current set anymore");
        assertTrue(bytes32Set.contains(data2), "data2 still in the current set");

        assertEq(uint256(bytes32Set.length()), 1);

        bool addedData1Again = bytes32Set.add(102, data1);
        assertTrue(addedData1Again, "Should have re-added data1");
        assertTrue(bytes32Set.contains(data1), "data1 present in the current set again");

        assertEq(uint256(bytes32Set.length()), 2);

        assertTrue(bytes32Set.containsAt(101, data2, ""), "data2 at key=101");
        assertTrue(bytes32Set.containsAt(101, data2), "data2 at key=101");
        assertFalse(bytes32Set.containsAt(101, data1, ""), "data1 was removed at key=101");
        assertFalse(bytes32Set.containsAt(101, data1), "data1 was removed at key=101");
        assertFalse(bytes32Set.containsAt(101, bytes32(uint256(0x789)), ""), "data1 was removed at key=101");
        assertFalse(bytes32Set.containsAt(101, bytes32(uint256(0x789))), "data1 was removed at key=101");

        assertFalse(
            bytes32Set.remove(103, bytes32(uint256(0x789))), "Removing a non-existent element should return false"
        );
    }

    function test_Bytes32SetValuesAt() public {
        bytes32 itemA = bytes32("ITEM-A");
        bytes32 itemB = bytes32("ITEM-B");
        bytes32 itemC = bytes32("ITEM-C");

        bytes32Set.add(5, itemA);
        bytes32Set.add(5, itemB);

        assertEq(uint256(bytes32Set.length()), 2);

        bytes32Set.remove(6, itemB);
        bytes32Set.add(6, itemC);

        bytes32[] memory currentVals = bytes32Set.values();
        assertEq(currentVals.length, 2, "2 registered items");

        bool foundA;
        bool foundC;
        for (uint256 i; i < currentVals.length; ++i) {
            if (currentVals[i] == itemA) foundA = true;
            if (currentVals[i] == itemC) foundC = true;
        }
        assertTrue(foundA, "Current set should have A");
        assertTrue(foundC, "Current set should have C");

        bytes32[] memory valsKey5 = bytes32Set.valuesAt(5);
        assertEq(valsKey5.length, 2, "At key=5, length is 2");
        bool foundB;
        for (uint256 i; i < valsKey5.length; ++i) {
            if (valsKey5[i] == itemB) foundB = true;
        }
        assertTrue(foundB, "B must be present at key=5");

        bytes32[] memory valsKey6 = bytes32Set.valuesAt(6);
        assertEq(valsKey6.length, 2, "At key=6, length is 2");
    }

    function test_Bytes32SetAllValues() public {
        bytes32 x = bytes32("X");
        bytes32 y = bytes32("Y");
        bytes32Set.add(1, x);
        bytes32Set.add(2, y);
        bytes32Set.remove(3, x);

        bytes32[] memory registeredValues = bytes32Set.values();
        assertEq(registeredValues.length, 1, "Only y remains registered after removing x");
        assertEq(registeredValues[0], y);
    }

    function test_LargeAddressSetExceed256Elements() public {
        uint256 totalItems = 300;
        uint48 keyAdd = 1;

        for (uint256 i; i < totalItems; ++i) {
            address newAddr = address(uint160(0x100000 + i));
            bool added = addressSet.add(keyAdd, newAddr);
            assertTrue(added, "Should add a new address successfully");
        }

        uint256 currentLength = uint256(addressSet.length());
        assertEq(currentLength, totalItems, "Should have 300 registered addresses");

        address firstInserted = address(uint160(0x100000));
        address lastInserted = address(uint160(0x100000 + (totalItems - 1)));
        assertTrue(addressSet.contains(firstInserted), "Should contain the first inserted address");
        assertTrue(addressSet.contains(lastInserted), "Should contain the last inserted address");

        address[] memory values = addressSet.values();
        for (uint256 i; i < values.length; ++i) {
            assertEq(values[i], address(uint160(0x100000 + i)));
        }

        addressSet.remove(2, firstInserted);
        addressSet.remove(2, address(uint160(0x100000 + 257)));

        assertEq(uint256(addressSet.length()), 298, "Should have removed 2 addresses, length=298");

        assertFalse(addressSet.contains(firstInserted), "First inserted address should now be unregistered");
        assertFalse(
            addressSet.contains(address(uint160(0x100000 + 257))), "Removed address at index 257 is unregistered"
        );

        assertTrue(addressSet.containsAt(1, firstInserted, ""), "At key=1, the first address was registered");
        assertTrue(addressSet.containsAt(1, firstInserted), "At key=1, the first address was registered");
        assertTrue(
            addressSet.containsAt(1, address(uint160(0x100000 + 257)), ""),
            "At key=1, the address at index 257 was registered"
        );
        assertTrue(
            addressSet.containsAt(1, address(uint160(0x100000 + 257))),
            "At key=1, the address at index 257 was registered"
        );

        address randomExisting = address(uint160(0x100000 + 150));
        assertTrue(addressSet.contains(randomExisting), "Item at index 150 is still registered at key=2");

        address[] memory valuesAtKey1 = addressSet.valuesAt(1);
        assertEq(valuesAtKey1.length, totalItems, "Should have 300 addresses at key=1");
        for (uint256 i; i < valuesAtKey1.length; ++i) {
            assertEq(valuesAtKey1[i], address(uint160(0x100000 + i)));
        }

        address[] memory valuesAtKey2 = addressSet.valuesAt(2);
        assertEq(valuesAtKey2.length, 298, "Should have 298 addresses at key=2");
        for (uint256 i; i < valuesAtKey2.length; ++i) {
            if (i < 256) {
                assertEq(valuesAtKey2[i], address(uint160(0x100000 + i + 1)));
            } else {
                assertEq(valuesAtKey2[i], address(uint160(0x100000 + i + 2)));
            }
        }

        assertTrue(addressSet.add(2, address(uint160(0x100000 + 11_111))), "Should add an address at key=2");

        address[] memory valuesAtKey2Again = addressSet.valuesAt(2);
        assertEq(valuesAtKey2Again.length, 299, "Should have 299 addresses at key=2");
        for (uint256 i; i < valuesAtKey2Again.length - 1; ++i) {
            if (i < 256) {
                assertEq(valuesAtKey2Again[i], address(uint160(0x100000 + i + 1)));
            } else {
                assertEq(valuesAtKey2Again[i], address(uint160(0x100000 + i + 2)));
            }
        }
        assertEq(valuesAtKey2Again[valuesAtKey2Again.length - 1], address(uint160(0x100000 + 11_111)));
    }

    function remove(uint48 key, address value) public {
        addressSet.remove(key, value);
    }

    function test_RevertPersistentSet_InvalidKey() public {
        addressSet.add(100, address(0x123));
        vm.expectRevert(PersistentSet.InvalidKey.selector);
        this.remove(99, address(0x123));

        this.remove(100, address(0x123));
    }
}
