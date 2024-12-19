# Sqrt Task Network Worker

This is a worker implementation for the Sqrt Task Network example. The worker listens for new tasks, computes square roots, and submits the results back to the blockchain.

## Prerequisites

- Docker
- Python 3.11+
- Access to an Holesky Ethereum node
- Private keys for validator and operator accounts
- Some Holesky ETH in the operator and validator account for gas fees
- Registration in `OperatorRegistry` and opt-in in `NetworkOptInService` to the network (middleware address: 0x18586B8cb86b59EF3F44BC915Ef92C83B6BAfd75)

## Usage

### Registering as an Operator

1. Install dependencies:

```
pip install -r requirements.txt
```

2. Register as an operator (one-time setup):
```bash
python worker.py register \
    --validator-private-key YOUR_VALIDATOR_PRIVATE_KEY \
    --operator-private-key YOUR_OPERATOR_PRIVATE_KEY \
    --vault-address YOUR_VAULT_ADDRESS
```

3. (Optional) Submit an incorrect answer for a specific task:
```bash
python worker.py submit-incorrect-answer \
    --validator-private-key YOUR_VALIDATOR_PRIVATE_KEY \
    --task-id TASK_ID
```

### Running the Worker

1. Build the Docker image:
```bash
docker build -t sqrt-worker .
```

2. Run the container:
```bash
docker run -e VALIDATOR_PRIVATE_KEY=your_private_key -e WEB3_URL=your_web3_url sqrt-worker
```

## Configuration Options

- `--validator-private-key`: Private key for signing task results
- `--operator-private-key`: Private key for transaction submission (only needed for registration)
- `--web3-url`: RPC endpoint URL (default: Holesky public node)
- `--vault-address`: Operator-specific vault address (default: 0x0)

## How It Works

1. The worker monitors the blockchain for new sqrt calculation tasks
2. When a task is found, it computes the square root using Python's math.isqrt
3. The result is signed using EIP-712 and submitted back to the contract
4. The worker maintains a block cache to resume from the last processed block

## Error Handling

The worker includes automatic retry logic and will:
- Reconnect on network issues
- Skip already completed tasks
- Log all operations for debugging
- Restart automatically when run in Docker