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
}

contract ValSetVerifierDataTest is Test {
    ValSetVerifierContract verifier;

    function setUp() public {
        verifier = new ValSetVerifierContract();
    }

    function test_VerifyOperator() public {
        bytes32 validatorSetRoot = 0x2f6efac15af7365cfc77dfdba6dbaaf5db057543c2892264804d1b07f3175aee;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0x5b6c25845e4ec34790fa940ade47f17ca2784595070ba71a3beb32a497b637ad;
        validatorRootProofArr[1] = 0x7d0ac373073567af7cd9d619d75caefca4230e12e37be87f4845c841d3874c79;
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
        validatorRootProofArr[20] = 0x0300000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xfafc11f91f2382cdbd325bb017959b771032ab47dfec9c3118ce42aebb4600d6,
            proof: validatorRootProofArr
        });

        bytes32[] memory operatorProofArr = new bytes32[](3);
        operatorProofArr[0] = 0x1b48eb57e0000000000000000000000000000000000000000000000000000000;
        operatorProofArr[1] = 0x989459dae16c447294a19dd1c3d6f8c5ad498a175149c14e7b47cdd09a0a55eb;
        operatorProofArr[2] = 0xabd3e41c535978c1aee04e43e3c9613907b574bc6398988c912a0ea032c64f85;

        bytes32 operatorLeaf = 0x1C7Ec4a3c19034C8e1ACD917C18c6c5757d7Ee18000000000000000000000000;
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
    }

    function test_VerifyVotingPower() public {
        bytes32 validatorSetRoot = 0x2f6efac15af7365cfc77dfdba6dbaaf5db057543c2892264804d1b07f3175aee;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0x5b6c25845e4ec34790fa940ade47f17ca2784595070ba71a3beb32a497b637ad;
        validatorRootProofArr[1] = 0x7d0ac373073567af7cd9d619d75caefca4230e12e37be87f4845c841d3874c79;
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
        validatorRootProofArr[20] = 0x0300000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xfafc11f91f2382cdbd325bb017959b771032ab47dfec9c3118ce42aebb4600d6,
            proof: validatorRootProofArr
        });

        bytes32[] memory votingPowerArr = new bytes32[](3);
        votingPowerArr[0] = 0x1c7ec4a3c19034c8e1acd917c18c6c5757d7ee18000000000000000000000000;
        votingPowerArr[1] = 0x989459dae16c447294a19dd1c3d6f8c5ad498a175149c14e7b47cdd09a0a55eb;
        votingPowerArr[2] = 0xabd3e41c535978c1aee04e43e3c9613907b574bc6398988c912a0ea032c64f85;
        bytes32 votingPowerLeaf = bytes32(uint256(30_000_000_000_000) << (256 - 6 * 8));
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
    }

    function test_VerifyIsActive() public {
        bytes32 validatorSetRoot = 0x2f6efac15af7365cfc77dfdba6dbaaf5db057543c2892264804d1b07f3175aee;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0x5b6c25845e4ec34790fa940ade47f17ca2784595070ba71a3beb32a497b637ad;
        validatorRootProofArr[1] = 0x7d0ac373073567af7cd9d619d75caefca4230e12e37be87f4845c841d3874c79;
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
        validatorRootProofArr[20] = 0x0300000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xfafc11f91f2382cdbd325bb017959b771032ab47dfec9c3118ce42aebb4600d6,
            proof: validatorRootProofArr
        });

        bytes32[] memory isActiveArr = new bytes32[](3);
        isActiveArr[0] = 0x0defa7ea44d052762fc254f0a7846440b65858c04bab4ebeaa0738182af419ee;
        isActiveArr[1] = 0xd0183674ce31bf9513d599b270baa6ab00added134215c4af5b21f9d082c27cb;
        isActiveArr[2] = 0xabd3e41c535978c1aee04e43e3c9613907b574bc6398988c912a0ea032c64f85;

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
    }

    function test_VerifyKey() public {
        bytes32 validatorSetRoot = 0x2f6efac15af7365cfc77dfdba6dbaaf5db057543c2892264804d1b07f3175aee;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0x5b6c25845e4ec34790fa940ade47f17ca2784595070ba71a3beb32a497b637ad;
        validatorRootProofArr[1] = 0x7d0ac373073567af7cd9d619d75caefca4230e12e37be87f4845c841d3874c79;
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
        validatorRootProofArr[20] = 0x0300000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xfafc11f91f2382cdbd325bb017959b771032ab47dfec9c3118ce42aebb4600d6,
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
        keyRootArr[9] = 0xd0183674ce31bf9513d599b270baa6ab00added134215c4af5b21f9d082c27cb;
        keyRootArr[10] = 0xabd3e41c535978c1aee04e43e3c9613907b574bc6398988c912a0ea032c64f85;

        bytes32 keyRootLeaf = 0x411796fa598f8a6413151844edee0a26ad2a6bfc47fd2be1d49fdc7636ba070a;
        ValSetVerifier.SszProof memory keyRootProof = ValSetVerifier.SszProof({leaf: keyRootLeaf, proof: keyRootArr});

        bytes32[] memory tagArr = new bytes32[](1);
        tagArr[0] = 0xef1a7187c182da6c6c7155f8fb8dfe102a4b33d8e8653dc2addc165a8eb73d62;

        ValSetVerifier.SszProof memory tagProof =
            ValSetVerifier.SszProof({leaf: bytes32(uint256(uint8(15)) << 248), proof: tagArr});

        bytes32[] memory payloadArr = new bytes32[](1);
        payloadArr[0] = 0x0f00000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory payloadProof = ValSetVerifier.SszProof({
            leaf: 0xef1a7187c182da6c6c7155f8fb8dfe102a4b33d8e8653dc2addc165a8eb73d62,
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
    }

    function test_VerifyVault() public {
        bytes32 validatorSetRoot = 0x2f6efac15af7365cfc77dfdba6dbaaf5db057543c2892264804d1b07f3175aee;

        bytes32[] memory validatorRootProofArr = new bytes32[](21);
        validatorRootProofArr[0] = 0x5b6c25845e4ec34790fa940ade47f17ca2784595070ba71a3beb32a497b637ad;
        validatorRootProofArr[1] = 0x7d0ac373073567af7cd9d619d75caefca4230e12e37be87f4845c841d3874c79;
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
        validatorRootProofArr[20] = 0x0300000000000000000000000000000000000000000000000000000000000000;

        ValSetVerifier.SszProof memory validatorRootProof = ValSetVerifier.SszProof({
            leaf: 0xfafc11f91f2382cdbd325bb017959b771032ab47dfec9c3118ce42aebb4600d6,
            proof: validatorRootProofArr
        });

        bytes32[] memory vaultRootArr = new bytes32[](9);
        vaultRootArr[0] = 0x635af50abbbaa38b1f93f30b802bdf465ed08a8eef517325e9ce242a99d2d015;
        vaultRootArr[1] = 0x56e00641ea2510531ab2c67ec1c62e611c5ff38fd6912368207c6c27ae9ef7b7;
        vaultRootArr[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        vaultRootArr[3] = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;
        vaultRootArr[4] = 0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c;
        vaultRootArr[5] = 0x0300000000000000000000000000000000000000000000000000000000000000;
        vaultRootArr[6] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        vaultRootArr[7] = 0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b;
        vaultRootArr[8] = 0xbfae3ce202e5e9f3fffd5af39b0923f94e8f10bd4a9b520d240ce21e468aa6d6;

        ValSetVerifier.SszProof memory vaultRootProof = ValSetVerifier.SszProof({
            leaf: 0x2250893312c38979a463afaa8ef8502fc78d61992710902a2846da48c36e5dc4,
            proof: vaultRootArr
        });

        bytes32[] memory vaultChainIdArr = new bytes32[](2);
        vaultChainIdArr[0] = 0x08b1ff0b405821b3cda044268217f6299b9d1a6f000000000000000000000000;
        vaultChainIdArr[1] = 0x6fe0e7a12c70ea93bde103565b74abbc1231e4e1ee443bfb775e64fca6517e98;
        ValSetVerifier.SszProof memory vaultChainIdProof =
            ValSetVerifier.SszProof({leaf: bytes32(uint256(0)), proof: vaultChainIdArr});

        bytes32[] memory vaultVaultArr = new bytes32[](2);
        vaultVaultArr[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        vaultVaultArr[1] = 0x6fe0e7a12c70ea93bde103565b74abbc1231e4e1ee443bfb775e64fca6517e98;
        ValSetVerifier.SszProof memory vaultVaultProof = ValSetVerifier.SszProof({
            leaf: 0x08B1ff0b405821B3CdA044268217F6299B9D1a6F000000000000000000000000,
            proof: vaultVaultArr
        });

        bytes32[] memory votingPowerArr = new bytes32[](2);
        votingPowerArr[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        votingPowerArr[1] = 0xeeadb2937693eee6ba6c93464afd72fdb4df78d76f553edcae6f8499f3ea48d9;

        ValSetVerifier.SszProof memory votingPowerProof = ValSetVerifier.SszProof({
            leaf: bytes32(uint256(10_000_000_000_000) << (256 - 6 * 8)),
            proof: votingPowerArr
        });

        assertTrue(
            verifier.verifyVault(
                validatorRootProof,
                0,
                validatorSetRoot,
                vaultRootProof,
                256,
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
                256,
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
                256,
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
                256,
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
                256,
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
                256,
                vaultChainIdProof,
                vaultVaultProof,
                votingPowerProof
            )
        );
        votingPowerProof.leaf = bytes32(uint256(votingPowerProof.leaf) - 1);
    }
}
