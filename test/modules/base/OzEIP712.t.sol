// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {OzEIP712} from "../../../src/modules/base/OzEIP712.sol";
import {IOzEIP712} from "../../../src/interfaces/modules/base/IOzEIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TestOzEIP712 is OzEIP712 {
    function initialize(string memory _name, string memory _version) external initializer {
        __OzEIP712_init(IOzEIP712.OzEIP712InitParams({name: _name, version: _version}));
    }
}

contract OzEIP712Test is Test {
    TestOzEIP712 private testEIP712;

    function setUp() public {
        testEIP712 = new TestOzEIP712();
    }

    function test_InitializeSetsDomain() public {
        testEIP712.initialize("MyDomain", "1");

        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = testEIP712.eip712Domain();

        assertEq(fields, hex"0f", "Fields mismatch");
        assertEq(name, "MyDomain", "Name mismatch");
        assertEq(version, "1", "Version mismatch");
        assertEq(chainId, block.chainid, "ChainID mismatch");
        assertEq(verifyingContract, address(testEIP712), "Verifying contract mismatch");
        assertEq(salt, bytes32(0), "Salt mismatch");
        assertEq(extensions.length, 0, "Extensions should be empty");
    }

    function test_Location() public {
        bytes32 location =
            keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OzEIP712")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(0x3d2c0ff50cfdbe7dfc45916875eb036a27b4a0034db93b35219dc0d930df1e00, location);
    }

    function test_HashTypedDataV4() public {
        testEIP712.initialize("MyDomain", "1");

        bytes32 dummyStructHash = keccak256("dummy-struct-hash");

        bytes32 fullDigest = testEIP712.hashTypedDataV4(dummyStructHash);

        assertTrue(fullDigest != bytes32(0), "Should produce a valid typed data hash");

        bytes32 crossChainDigest = testEIP712.hashTypedDataV4CrossChain(dummyStructHash);
        assertTrue(crossChainDigest != bytes32(0), "Cross-chain typed data hash should be valid");
        assertTrue(fullDigest != crossChainDigest, "crossChainDigest must differ from normal domain");
    }

    function test_SignatureRecovery() public {
        testEIP712.initialize("MyDomain", "1");

        bytes32 structHash = keccak256("Some struct...");
        bytes32 digest = testEIP712.hashTypedDataV4(structHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        address recovered = ECDSA.recover(digest, v, r, s);

        address expected = vm.addr(1);
        assertEq(recovered, expected, "Recovered signer mismatch");
    }

    function test_ReInitialize() public {
        testEIP712.initialize("DomainA", "1");

        vm.expectRevert();
        testEIP712.initialize("DomainB", "2");
    }
}
