// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ValSetVerifier} from "../../src/libraries/utils/ValSetVerifier.sol";

contract ValSetVerifierMock {
    function verifyOperator(
        ValSetVerifier.SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        ValSetVerifier.SszProof calldata operatorRootProof
    ) public view returns (bool) {
        return ValSetVerifier.verifyOperator(
            validatorRootProof, validatorRootLocalIndex, validatorSetRoot, operatorRootProof
        );
    }

    function verifyValidatorRootLocal(
        ValSetVerifier.SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot
    ) public view returns (bool) {
        return ValSetVerifier.verifyValidatorRootLocal(validatorRootProof, validatorRootLocalIndex, validatorSetRoot);
    }

    function verifyValidatorOperatorLocal(
        ValSetVerifier.SszProof calldata operatorRootProof,
        bytes32 validatorSetRoot
    ) public view returns (bool) {
        return ValSetVerifier.verifyValidatorOperatorLocal(operatorRootProof, validatorSetRoot);
    }

    function verifyValidatorVaultRootLocal(
        ValSetVerifier.SszProof calldata vaultRootProof,
        uint256 vaultRootLocalIndex,
        bytes32 validatorRoot
    ) public view returns (bool) {
        return ValSetVerifier.verifyValidatorVaultRootLocal(vaultRootProof, vaultRootLocalIndex, validatorRoot);
    }

    function verifyVaultVotingPowerLocal(
        ValSetVerifier.SszProof calldata vaultVotingPowerProof,
        bytes32 vaultRoot
    ) public view returns (bool) {
        return ValSetVerifier.verifyVaultVotingPowerLocal(vaultVotingPowerProof, vaultRoot);
    }
}
