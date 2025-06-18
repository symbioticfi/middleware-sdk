# Symbiotic Relay Smart Contracts

## Overview

Symbiotic Relay is a peer-to-peer side-network designed to collect and aggregate signatures from validators, maintain validator sets on the settlement contract.

To achieve that, Symbiotic provides a set of predefined smart contracts, in general, representing the following modules:

- [VotingPowerProvider](./src/contracts/modules/voting-power/) - provides the basic data regarding operators, vaults and their voting power, it allows constructing various onboarding schemes such as:
  - [OperatorsWhitelist](./src/contracts/modules/voting-power/extensions/OperatorsWhitelist.sol) - only whitelisted operators can register
  - [OperatorsBlacklist](./src/contracts/modules/voting-power/extensions/OperatorsBlacklist.sol) - blacklisted operators are unregistered and are forbidden to return back
  - [OperatorsJail](./src/contracts/modules/voting-power/extensions/OperatorsJail.sol) - operators can be jailed for some amount of time and register back after that
  - [SharedVaults](./src/contracts/modules/voting-power/extensions/SharedVaults.sol) - shared (with other networks) vaults (like the ones with NetworkRestakeDelegator) can be added
  - [OperatorVaults](./src/contracts/modules/voting-power/extensions/OperatorVaults.sol) - vaults that are attached to a single operator can be added
  - [MultiToken](./src/contracts/modules/voting-power/extensions/MultiToken.sol) - possible to add new supported tokens on the go
  - [OpNetVaultAutoDeploy](./src/contracts/modules/voting-power/extensions/OpNetVaultAutoDeploy.sol) - enable auto-creation of the configured by you vault on each operator registration
  - Also, there are ready bindings for [slashing](./src/contracts/modules/voting-power/extensions/BaseSlashing.sol) and [rewards](./src/contracts/modules/voting-power/extensions/BaseRewards.sol)
- [KeyRegistry](./src/contracts/modules/key-registry/) - verifies and manages operators' keys; currently, these key types are supported:
  - [BlsBn254](./src/contracts/libraries/keys/KeyBlsBn254.sol) ([signature verification](./src/contracts/libraries/sigs/SigBlsBn254.sol))
  - [EcdsaSecp256k1](./src/contracts/libraries/keys/KeyEcdsaSecp256k1.sol) ([signature verification](./src/contracts/libraries/sigs/SigEcdsaSecp256k1.sol))
- [ValSetDriver](./src/contracts/modules/valset-driver/) - is used by the off-chain part of the Symbiotic Relay for validator set deriving and maintenance
- [Settlement](./src/contracts/modules/settlement/) - requires a compressed validator set (header) to be committed each epoch, but allows verifying signatures made by the validator set; currently, it supports the following verification mechanics:
  - [SimpleVerifier](./src/contracts/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol) - requires the whole validator set to be inputted on the verification, but in a compressed and efficient way, so that it is the best choice to use up to around 125 validators
  - [ZKVerifier](./src/contracts/modules/settlement/sig-verifiers/SigVerifierBlsBn254ZK.sol) - uses ZK verification made with [gnark](https://github.com/Consensys/gnark), allowing larger validator sets with an almost constant verification gas cost
- [Network](./src/contracts/modules/network/) - a standard contract that can be used as a "network" address across the Symbiotic ecosystem, it enables verifiability of delays for different actions (e.g., change of the middleware or change of the resolver)

## Examples

Can be found [here](./examples/).

## Security

Security audits can be found [here](./audits).

## Repo init

Clone the repo:

```bash
git clone --recurse-submodules https://github.com/symbioticfi/middleware-sdk.git
```

## Create env configuration

```bash
cp .env.example .env
```

Key parameters:

- `OPERATORS` - number of operators in network
- `VERIFICATION_TYPE` - signatures aggregation type, (0 for ZK, 1 for simple)

## On-chain setup

Before running off-chain nodes need to set up on-chain contract.

To simplify local development, we've prepared a Docker image with an Anvil node and deployed Symbiotic contracts.

### Build Docker image

```bash
docker build -t symbiotic-anvil .
```

### Run anvil node

```bash
docker run --rm -d -p 8545:8545 --env-file .env --name symbiotic-node symbiotic-anvil
```

### Configure network

Use the right `generate_genesis` file depending on your system [here](./script/test/utils/).

```bash
docker run --rm -it --env-file .env --network host symbiotic-anvil yarn deploy:network
```

This command will execute a list of transactions to set up network contracts.

In execution logs, you can see the deployed configuration and contract addresses.

### Stop anvil node

```bash
docker stop symbiotic-node
```

## Tests

```
forge test
```

## Coverage

```
forge coverage
```
