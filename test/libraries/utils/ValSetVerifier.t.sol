// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {ValSetVerifier} from "../../../src/libraries/utils/ValSetVerifier.sol";
import {ValSetVerifierMock} from "../../mocks/ValSetVerifierMock.sol";

contract ValSetVerifierContract {
    function verifyOperator(
        ValSetVerifier.SszProof calldata validatorRootProofArr,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        ValSetVerifier.SszProof calldata operatorProof
    ) public returns (bool) {
        return ValSetVerifier.verifyOperator(
            validatorRootProofArr, validatorRootLocalIndex, validatorSetRoot, operatorProof
        );
    }

    function verifyVotingPower(
        ValSetVerifier.SszProof calldata validatorRootProofArr,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        ValSetVerifier.SszProof calldata votingPowerProof
    ) public returns (bool) {
        return ValSetVerifier.verifyVotingPower(
            validatorRootProofArr, validatorRootLocalIndex, validatorSetRoot, votingPowerProof
        );
    }

    function verifyIsActive(
        ValSetVerifier.SszProof calldata validatorRootProofArr,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        ValSetVerifier.SszProof calldata isActiveProof
    ) public returns (bool) {
        return ValSetVerifier.verifyIsActive(
            validatorRootProofArr, validatorRootLocalIndex, validatorSetRoot, isActiveProof
        );
    }

    function verifyKey(
        ValSetVerifier.SszProof calldata validatorRootProofArr,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        ValSetVerifier.SszProof calldata keyRootProof,
        uint256 keyRootLocalIndex,
        ValSetVerifier.SszProof calldata keyTagProof,
        ValSetVerifier.SszProof calldata keyPayloadHashProof
    ) public returns (bool) {
        return ValSetVerifier.verifyKey(
            validatorRootProofArr,
            validatorRootLocalIndex,
            validatorSetRoot,
            keyRootProof,
            keyRootLocalIndex,
            keyTagProof,
            keyPayloadHashProof
        );
    }

    function verifyValidatorKeyRootLocal(
        ValSetVerifier.SszProof calldata keyRootProof,
        uint256 keyRootLocalIndex,
        bytes32 validatorRoot
    ) public returns (bool) {
        return ValSetVerifier.verifyValidatorKeyRootLocal(keyRootProof, keyRootLocalIndex, validatorRoot);
    }

    function verifyVault(
        ValSetVerifier.SszProof calldata validatorRootProofArr,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        ValSetVerifier.SszProof calldata vaultRootProof,
        uint256 vaultRootLocalIndex,
        ValSetVerifier.SszProof calldata vaultChainIdProof,
        ValSetVerifier.SszProof calldata vaultVaultProof,
        ValSetVerifier.SszProof calldata vaultVotingPowerProof
    ) public returns (bool) {
        return ValSetVerifier.verifyVault(
            validatorRootProofArr,
            validatorRootLocalIndex,
            validatorSetRoot,
            vaultRootProof,
            vaultRootLocalIndex,
            vaultChainIdProof,
            vaultVaultProof,
            vaultVotingPowerProof
        );
    }

    function verifyValidatorVaultRootLocal(
        ValSetVerifier.SszProof calldata vaultRootProof,
        uint256 vaultRootLocalIndex,
        bytes32 validatorRoot
    ) public returns (bool) {
        return ValSetVerifier.verifyValidatorVaultRootLocal(vaultRootProof, vaultRootLocalIndex, validatorRoot);
    }
}

contract ValSetVerifierDataTest is Test {
    ValSetVerifierContract verifier;

    function setUp() public {
        verifier = new ValSetVerifierContract();
    }

    function test_VerifyOperator() public {
        bytes32 validatorSetRoot = 0x18d55348973a10ea84115602713982ad64bb3bfd07dc171b6e78557526cc1b43;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0xff9f44d15fbfe9c1356104b76ec962d6d20115706166c0a8e8c525e996d2f130;
        validatorRootProofArr[1] = 0x8db86f7789ed412777992ead7ff4b4e74f1d1b268af697a75ba88de2c23ad37c;
        validatorRootProofArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        validatorRootProofArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        validatorRootProofArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        validatorRootProofArr[5] = 0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30;
        validatorRootProofArr[6] = 0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1;
        validatorRootProofArr[7] = 0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c;
        validatorRootProofArr[8] = 0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193;
        validatorRootProofArr[9] = 0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1;
        validatorRootProofArr[10] = 0xffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b;
        validatorRootProofArr[11] = 0x6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220;
        validatorRootProofArr[12] = 0xb7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f;
        validatorRootProofArr[13] = 0xdf6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e;
        validatorRootProofArr[14] = 0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784;
        validatorRootProofArr[15] = 0xd49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb;
        validatorRootProofArr[16] = 0x8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb;
        validatorRootProofArr[17] = 0x8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab;
        validatorRootProofArr[18] = 0x95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4;
        validatorRootProofArr[19] = 0xf893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f;
        validatorRootProofArr[20] = 0x0400000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xc25d22a1fb9429b489654db1907bbe717d85c462ad2a9b17e59e53c3faac19fa,
            proof: validatorRootProofArr
        });

        bytes32[] memory operatorProofArr = new bytes32[](3);
        operatorProofArr[0] = 0x0186a00000000000000000000000000000000000000000000000000000000000;
        operatorProofArr[1] = 0x2ee23d6c2c22489f24e54d9ee5c7c9476fe706af320dd8a4ebb20aa5b809fd88;
        operatorProofArr[2] = 0xb18a0f326c83c9ec6e8926ed6ac5c5bf0089a0224239f761c54e91b02e38e3b6;

        bytes32 operatorLeaf = 0x12f69d5c9ac2f14265fbb1196324efb3b63a8170000000000000000000000000;
        ValSetVerifier.SszProof memory operatorProof =
            ValSetVerifier.SszProof({leaf: operatorLeaf, proof: operatorProofArr});

        assertTrue(verifier.verifyOperator(validatorRootProof, 0, validatorSetRoot, operatorProof));

        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) + 1);
        assertFalse(verifier.verifyOperator(validatorRootProof, 0, validatorSetRoot, operatorProof));
        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) - 1);

        validatorRootProof.proof[0] = bytes32(uint256(validatorRootProof.proof[0]) + 1);
        assertFalse(verifier.verifyOperator(validatorRootProof, 0, validatorSetRoot, operatorProof));
        validatorRootProof.proof[0] = bytes32(uint256(validatorRootProof.proof[0]) - 1);

        validatorSetRoot = bytes32(uint256(validatorSetRoot) + 1);
        assertFalse(verifier.verifyOperator(validatorRootProof, 0, validatorSetRoot, operatorProof));
        validatorSetRoot = bytes32(uint256(validatorSetRoot) - 1);

        operatorProof.leaf = bytes32(uint256(operatorProof.leaf) + 1);
        assertFalse(verifier.verifyOperator(validatorRootProof, 0, validatorSetRoot, operatorProof));
        operatorProof.leaf = bytes32(uint256(operatorProof.leaf) - 1);

        operatorProof.proof[0] = bytes32(uint256(operatorProof.proof[0]) + 1);
        assertFalse(verifier.verifyOperator(validatorRootProof, 0, validatorSetRoot, operatorProof));
        operatorProof.proof[0] = bytes32(uint256(operatorProof.proof[0]) - 1);

        assertFalse(verifier.verifyOperator(validatorRootProof, type(uint256).max, validatorSetRoot, operatorProof));
    }

    function test_VerifyVotingPower() public {
        bytes32 validatorSetRoot = 0x18d55348973a10ea84115602713982ad64bb3bfd07dc171b6e78557526cc1b43;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0xff9f44d15fbfe9c1356104b76ec962d6d20115706166c0a8e8c525e996d2f130;
        validatorRootProofArr[1] = 0x8db86f7789ed412777992ead7ff4b4e74f1d1b268af697a75ba88de2c23ad37c;
        validatorRootProofArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        validatorRootProofArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        validatorRootProofArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        validatorRootProofArr[5] = 0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30;
        validatorRootProofArr[6] = 0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1;
        validatorRootProofArr[7] = 0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c;
        validatorRootProofArr[8] = 0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193;
        validatorRootProofArr[9] = 0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1;
        validatorRootProofArr[10] = 0xffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b;
        validatorRootProofArr[11] = 0x6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220;
        validatorRootProofArr[12] = 0xb7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f;
        validatorRootProofArr[13] = 0xdf6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e;
        validatorRootProofArr[14] = 0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784;
        validatorRootProofArr[15] = 0xd49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb;
        validatorRootProofArr[16] = 0x8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb;
        validatorRootProofArr[17] = 0x8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab;
        validatorRootProofArr[18] = 0x95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4;
        validatorRootProofArr[19] = 0xf893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f;
        validatorRootProofArr[20] = 0x0400000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xc25d22a1fb9429b489654db1907bbe717d85c462ad2a9b17e59e53c3faac19fa,
            proof: validatorRootProofArr
        });

        bytes32[] memory votingPowerArr = new bytes32[](3);
        votingPowerArr[0] = 0x12f69d5c9ac2f14265fbb1196324efb3b63a8170000000000000000000000000;
        votingPowerArr[1] = 0x2ee23d6c2c22489f24e54d9ee5c7c9476fe706af320dd8a4ebb20aa5b809fd88;
        votingPowerArr[2] = 0xb18a0f326c83c9ec6e8926ed6ac5c5bf0089a0224239f761c54e91b02e38e3b6;
        bytes32 votingPowerLeaf = bytes32(uint256(100_000) << (256 - 3 * 8));
        ValSetVerifier.SszProof memory votingPowerProof =
            ValSetVerifier.SszProof({leaf: votingPowerLeaf, proof: votingPowerArr});

        assertTrue(verifier.verifyVotingPower(validatorRootProof, 0, validatorSetRoot, votingPowerProof));

        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) + 1);
        assertFalse(verifier.verifyVotingPower(validatorRootProof, 0, validatorSetRoot, votingPowerProof));
        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) - 1);

        validatorRootProof.proof[0] = bytes32(uint256(validatorRootProof.proof[0]) + 1);
        assertFalse(verifier.verifyVotingPower(validatorRootProof, 0, validatorSetRoot, votingPowerProof));
        validatorRootProof.proof[0] = bytes32(uint256(validatorRootProof.proof[0]) - 1);

        validatorSetRoot = bytes32(uint256(validatorSetRoot) + 1);
        assertFalse(verifier.verifyVotingPower(validatorRootProof, 0, validatorSetRoot, votingPowerProof));
        validatorSetRoot = bytes32(uint256(validatorSetRoot) - 1);

        votingPowerProof.leaf = bytes32(uint256(votingPowerProof.leaf) + 1);
        assertFalse(verifier.verifyVotingPower(validatorRootProof, 0, validatorSetRoot, votingPowerProof));
        votingPowerProof.leaf = bytes32(uint256(votingPowerProof.leaf) - 1);

        votingPowerProof.proof[0] = bytes32(uint256(votingPowerProof.proof[0]) + 1);
        assertFalse(verifier.verifyVotingPower(validatorRootProof, 0, validatorSetRoot, votingPowerProof));
        votingPowerProof.proof[0] = bytes32(uint256(votingPowerProof.proof[0]) - 1);

        assertFalse(
            verifier.verifyVotingPower(validatorRootProof, type(uint256).max, validatorSetRoot, votingPowerProof)
        );
    }

    function test_VerifyIsActive() public {
        bytes32 validatorSetRoot = 0x18d55348973a10ea84115602713982ad64bb3bfd07dc171b6e78557526cc1b43;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0xff9f44d15fbfe9c1356104b76ec962d6d20115706166c0a8e8c525e996d2f130;
        validatorRootProofArr[1] = 0x8db86f7789ed412777992ead7ff4b4e74f1d1b268af697a75ba88de2c23ad37c;
        validatorRootProofArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        validatorRootProofArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        validatorRootProofArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        validatorRootProofArr[5] = 0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30;
        validatorRootProofArr[6] = 0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1;
        validatorRootProofArr[7] = 0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c;
        validatorRootProofArr[8] = 0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193;
        validatorRootProofArr[9] = 0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1;
        validatorRootProofArr[10] = 0xffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b;
        validatorRootProofArr[11] = 0x6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220;
        validatorRootProofArr[12] = 0xb7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f;
        validatorRootProofArr[13] = 0xdf6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e;
        validatorRootProofArr[14] = 0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784;
        validatorRootProofArr[15] = 0xd49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb;
        validatorRootProofArr[16] = 0x8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb;
        validatorRootProofArr[17] = 0x8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab;
        validatorRootProofArr[18] = 0x95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4;
        validatorRootProofArr[19] = 0xf893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f;
        validatorRootProofArr[20] = 0x0400000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xc25d22a1fb9429b489654db1907bbe717d85c462ad2a9b17e59e53c3faac19fa,
            proof: validatorRootProofArr
        });

        bytes32[] memory isActiveArr = new bytes32[](3);
        isActiveArr[0] = 0x887b68c3e1c9e8e844f05f18cf293078ed6ba7316108205c3e4441ce23a0c838;
        isActiveArr[1] = 0xda641bf9e8d0732aeef573aea758062a8afc1a42a511819fd73c8fffaee4d8d5;
        isActiveArr[2] = 0xb18a0f326c83c9ec6e8926ed6ac5c5bf0089a0224239f761c54e91b02e38e3b6;

        bytes32 isActiveLeaf = bytes32(uint256(1) << 248);
        ValSetVerifier.SszProof memory isActiveProof = ValSetVerifier.SszProof({leaf: isActiveLeaf, proof: isActiveArr});
        assertTrue(verifier.verifyIsActive(validatorRootProof, 0, validatorSetRoot, isActiveProof));

        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) + 1);
        assertFalse(verifier.verifyIsActive(validatorRootProof, 0, validatorSetRoot, isActiveProof));
        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) - 1);

        validatorRootProof.proof[0] = bytes32(uint256(validatorRootProof.proof[0]) + 1);
        assertFalse(verifier.verifyIsActive(validatorRootProof, 0, validatorSetRoot, isActiveProof));
        validatorRootProof.proof[0] = bytes32(uint256(validatorRootProof.proof[0]) - 1);

        validatorSetRoot = bytes32(uint256(validatorSetRoot) + 1);
        assertFalse(verifier.verifyIsActive(validatorRootProof, 0, validatorSetRoot, isActiveProof));
        validatorSetRoot = bytes32(uint256(validatorSetRoot) - 1);

        isActiveProof.leaf = bytes32(uint256(isActiveProof.leaf) + 1);
        assertFalse(verifier.verifyIsActive(validatorRootProof, 0, validatorSetRoot, isActiveProof));
        isActiveProof.leaf = bytes32(uint256(isActiveProof.leaf) - 1);

        isActiveProof.proof[0] = bytes32(uint256(isActiveProof.proof[0]) + 1);
        assertFalse(verifier.verifyIsActive(validatorRootProof, 0, validatorSetRoot, isActiveProof));
        isActiveProof.proof[0] = bytes32(uint256(isActiveProof.proof[0]) - 1);

        assertFalse(verifier.verifyIsActive(validatorRootProof, type(uint256).max, validatorSetRoot, isActiveProof));
    }

    function test_VerifyKey() public {
        bytes32 validatorSetRoot = 0x18d55348973a10ea84115602713982ad64bb3bfd07dc171b6e78557526cc1b43;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0xff9f44d15fbfe9c1356104b76ec962d6d20115706166c0a8e8c525e996d2f130;
        validatorRootProofArr[1] = 0x8db86f7789ed412777992ead7ff4b4e74f1d1b268af697a75ba88de2c23ad37c;
        validatorRootProofArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        validatorRootProofArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        validatorRootProofArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        validatorRootProofArr[5] = 0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30;
        validatorRootProofArr[6] = 0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1;
        validatorRootProofArr[7] = 0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c;
        validatorRootProofArr[8] = 0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193;
        validatorRootProofArr[9] = 0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1;
        validatorRootProofArr[10] = 0xffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b;
        validatorRootProofArr[11] = 0x6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220;
        validatorRootProofArr[12] = 0xb7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f;
        validatorRootProofArr[13] = 0xdf6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e;
        validatorRootProofArr[14] = 0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784;
        validatorRootProofArr[15] = 0xd49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb;
        validatorRootProofArr[16] = 0x8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb;
        validatorRootProofArr[17] = 0x8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab;
        validatorRootProofArr[18] = 0x95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4;
        validatorRootProofArr[19] = 0xf893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f;
        validatorRootProofArr[20] = 0x0400000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xc25d22a1fb9429b489654db1907bbe717d85c462ad2a9b17e59e53c3faac19fa,
            proof: validatorRootProofArr
        });

        bytes32[] memory keyRootArr = new bytes32[](11);
        keyRootArr[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        keyRootArr[1] = 0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b;
        keyRootArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        keyRootArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        keyRootArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        keyRootArr[5] = 0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30;
        keyRootArr[6] = 0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1;
        keyRootArr[7] = 0x0100000000000000000000000000000000000000000000000000000000000000;
        keyRootArr[8] = 0x0100000000000000000000000000000000000000000000000000000000000000;
        keyRootArr[9] = 0xda641bf9e8d0732aeef573aea758062a8afc1a42a511819fd73c8fffaee4d8d5;
        keyRootArr[10] = 0xb18a0f326c83c9ec6e8926ed6ac5c5bf0089a0224239f761c54e91b02e38e3b6;

        bytes32 keyRootLeaf = 0x2550233714c0e0c9aca9668d020ed3333079256bfff7dc78cbd85eeaa213a0ca;
        ValSetVerifier.SszProof memory keyRootProof = ValSetVerifier.SszProof({leaf: keyRootLeaf, proof: keyRootArr});

        bytes32[] memory tagArr = new bytes32[](1);
        tagArr[0] = 0x07f1063c1c69798bd34c3cb06174d886b142b7840035b516d8f40c73a3eed745;

        ValSetVerifier.SszProof memory tagProof =
            ValSetVerifier.SszProof({leaf: bytes32(uint256(uint8(15)) << 248), proof: tagArr});

        bytes32[] memory payloadArr = new bytes32[](1);
        payloadArr[0] = 0x0f00000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory payloadProof = ValSetVerifier.SszProof({
            leaf: 0x07f1063c1c69798bd34c3cb06174d886b142b7840035b516d8f40c73a3eed745,
            proof: payloadArr
        });

        assertTrue(
            verifier.verifyKey(validatorRootProof, 0, validatorSetRoot, keyRootProof, 768, tagProof, payloadProof)
        );

        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) + 1);
        assertFalse(
            verifier.verifyKey(validatorRootProof, 0, validatorSetRoot, keyRootProof, 768, tagProof, payloadProof)
        );
        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) - 1);

        keyRootProof.leaf = bytes32(uint256(keyRootProof.leaf) + 1);
        assertFalse(
            verifier.verifyKey(validatorRootProof, 0, validatorSetRoot, keyRootProof, 768, tagProof, payloadProof)
        );
        keyRootProof.leaf = bytes32(uint256(keyRootProof.leaf) - 1);

        tagProof.leaf = bytes32(uint256(tagProof.leaf) + 1);
        assertFalse(
            verifier.verifyKey(validatorRootProof, 0, validatorSetRoot, keyRootProof, 768, tagProof, payloadProof)
        );
        tagProof.leaf = bytes32(uint256(tagProof.leaf) - 1);

        payloadProof.leaf = bytes32(uint256(payloadProof.leaf) + 1);
        assertFalse(
            verifier.verifyKey(validatorRootProof, 0, validatorSetRoot, keyRootProof, 768, tagProof, payloadProof)
        );
        payloadProof.leaf = bytes32(uint256(payloadProof.leaf) - 1);

        assertFalse(
            verifier.verifyKey(
                validatorRootProof, type(uint256).max, validatorSetRoot, keyRootProof, 768, tagProof, payloadProof
            )
        );

        assertFalse(
            verifier.verifyKey(
                validatorRootProof, 0, validatorSetRoot, keyRootProof, type(uint256).max, tagProof, payloadProof
            )
        );
    }

    function test_VerifyVault() public {
        bytes32 validatorSetRoot = 0x18d55348973a10ea84115602713982ad64bb3bfd07dc171b6e78557526cc1b43;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0xff9f44d15fbfe9c1356104b76ec962d6d20115706166c0a8e8c525e996d2f130;
        validatorRootProofArr[1] = 0x8db86f7789ed412777992ead7ff4b4e74f1d1b268af697a75ba88de2c23ad37c;
        validatorRootProofArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        validatorRootProofArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        validatorRootProofArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        validatorRootProofArr[5] = 0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30;
        validatorRootProofArr[6] = 0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1;
        validatorRootProofArr[7] = 0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c;
        validatorRootProofArr[8] = 0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193;
        validatorRootProofArr[9] = 0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1;
        validatorRootProofArr[10] = 0xffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b;
        validatorRootProofArr[11] = 0x6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220;
        validatorRootProofArr[12] = 0xb7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f;
        validatorRootProofArr[13] = 0xdf6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e;
        validatorRootProofArr[14] = 0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784;
        validatorRootProofArr[15] = 0xd49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb;
        validatorRootProofArr[16] = 0x8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb;
        validatorRootProofArr[17] = 0x8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab;
        validatorRootProofArr[18] = 0x95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4;
        validatorRootProofArr[19] = 0xf893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f;
        validatorRootProofArr[20] = 0x0400000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xc25d22a1fb9429b489654db1907bbe717d85c462ad2a9b17e59e53c3faac19fa,
            proof: validatorRootProofArr
        });

        bytes32[] memory vaultRootArr = new bytes32[](14);
        vaultRootArr[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        vaultRootArr[1] = 0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b;
        vaultRootArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        vaultRootArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        vaultRootArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        vaultRootArr[5] = 0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30;
        vaultRootArr[6] = 0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1;
        vaultRootArr[7] = 0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c;
        vaultRootArr[8] = 0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193;
        vaultRootArr[9] = 0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1;
        vaultRootArr[10] = 0x0100000000000000000000000000000000000000000000000000000000000000;
        vaultRootArr[11] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        vaultRootArr[12] = 0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b;
        vaultRootArr[13] = 0x45dbecaa5000a2996a3f63b86e235d8a02a9a00f6d21c294bc0435832e5fa39c;

        ValSetVerifier.SszProof memory vaultRootProof = ValSetVerifier.SszProof({
            leaf: 0x14847a632846b9dcf0c1379f1f17834f3caa6f8b3a1289ef058ab1532cae4a6d,
            proof: vaultRootArr
        });

        bytes32[] memory vaultChainIdArr = new bytes32[](2);
        vaultChainIdArr[0] = 0x1a05591693d4c70e5980deaa1ad9a73b43f95670000000000000000000000000;
        vaultChainIdArr[1] = 0xfb7233019dc66db60dd9035b6989ed945f7d3cac8c421face97150392b018d0f;
        ValSetVerifier.SszProof memory vaultChainIdProof =
            ValSetVerifier.SszProof({leaf: bytes32(uint256(0x697a) << (256 - 2 * 8)), proof: vaultChainIdArr}); // 0x7a69 = 31337

        bytes32[] memory vaultVaultArr = new bytes32[](2);
        vaultVaultArr[0] = 0x697a000000000000000000000000000000000000000000000000000000000000;
        vaultVaultArr[1] = 0xfb7233019dc66db60dd9035b6989ed945f7d3cac8c421face97150392b018d0f;
        ValSetVerifier.SszProof memory vaultVaultProof = ValSetVerifier.SszProof({
            leaf: bytes32(uint256(uint160(address(0x1a05591693D4C70e5980dEAa1AD9A73b43F95670))) << (256 - 20 * 8)),
            proof: vaultVaultArr
        });

        bytes32[] memory vaultVotingPowerArr = new bytes32[](2);
        vaultVotingPowerArr[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        vaultVotingPowerArr[1] = 0xcc1c332f6fc6ed54abea943a660a1e729d1dc08c81a17fe80f1d4b5ef95c5115;

        ValSetVerifier.SszProof memory votingPowerProof =
            ValSetVerifier.SszProof({leaf: bytes32(uint256(100_000) << (256 - 3 * 8)), proof: vaultVotingPowerArr});

        assertTrue(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                8192,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );

        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) + 1);
        assertFalse(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                8192,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );
        validatorRootProof.leaf = bytes32(uint256(validatorRootProof.leaf) - 1);

        vaultRootProof.leaf = bytes32(uint256(vaultRootProof.leaf) + 1);
        assertFalse(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                8192,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );
        vaultRootProof.leaf = bytes32(uint256(vaultRootProof.leaf) - 1);

        vaultChainIdProof.leaf = bytes32(uint256(vaultChainIdProof.leaf) + 1);
        assertFalse(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                8192,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );
        vaultChainIdProof.leaf = bytes32(uint256(vaultChainIdProof.leaf) - 1);

        vaultVaultProof.leaf = bytes32(uint256(vaultVaultProof.leaf) + 1);
        assertFalse(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                8192,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );
        vaultVaultProof.leaf = bytes32(uint256(vaultVaultProof.leaf) - 1);

        votingPowerProof.leaf = bytes32(uint256(votingPowerProof.leaf) + 1);
        assertFalse(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                8192,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );
        votingPowerProof.leaf = bytes32(uint256(votingPowerProof.leaf) - 1);

        assertFalse(
            verifier.verifyVault(
                validatorRootProof,
                type(uint256).max,
                validatorSetRoot,
                vaultRootProof,
                8192,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );

        assertFalse(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                type(uint256).max,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );
    }
}
