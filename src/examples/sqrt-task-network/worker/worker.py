import math
import time
import logging
from eth_account import Account
from web3 import Web3
from web3.middleware import SignAndSendRawMiddlewareBuilder
import json
import click
from web3.providers import HTTPProvider
from eth_account.messages import encode_defunct

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SqrtTaskWorker:
    def __init__(self, web3_url, validator_private_key, contract_address, contract_abi):
        self._setup_web3(web3_url, validator_private_key, contract_address, contract_abi)
        self._setup_block_cache(contract_address)

    def _setup_web3(self, web3_url, private_key, contract_address, contract_abi):
        self.w3 = Web3(HTTPProvider(web3_url))
        self.account = Account.from_key(private_key)
        self.w3.middleware_onion.add(
            SignAndSendRawMiddlewareBuilder.build(self.account)
        )
        self.contract = self.w3.eth.contract(address=contract_address, abi=contract_abi)

    def _setup_block_cache(self, contract_address):
        self.cache_file = f".last_block_{contract_address}.txt"
        try:
            with open(self.cache_file, 'r') as f:
                self.last_processed_block = int(f.read().strip())
                logger.info(f"Loaded last processed block: {self.last_processed_block}")
        except:
            self.last_processed_block = -1
            logger.info("No previous block cache found, starting from latest block")

    def _create_eip712_message(self, task_id, answer):
        return {
            "types": {
                "EIP712Domain": [
                    {"name": "name", "type": "string"},
                    {"name": "version", "type": "string"},
                    {"name": "chainId", "type": "uint256"},
                    {"name": "verifyingContract", "type": "address"}
                ],
                "CompleteTask": [
                    {"name": "taskIndex", "type": "uint256"},
                    {"name": "answer", "type": "uint256"}
                ]
            },
            "primaryType": "CompleteTask",
            "domain": {
                "name": "SelfRegisterSqrtTaskMiddleware",
                "version": "1",
                "chainId": self.w3.eth.chain_id,
                "verifyingContract": self.contract.address
            },
            "message": {
                "taskIndex": task_id,
                "answer": answer
            }
        }

    def _process_task(self, task_id, task, incorrect=False):
        if task[3]:  # Skip if completed
            logger.info(f"Task {task_id} already completed")
            return
        
        if task[2].lower() != self.account.address.lower():
            logger.info(f"Task {task_id} not assigned to this validator")
            return
            
        logger.info(f"Processing task {task_id}")
        value = task[1]
        if incorrect:
            answer = int(math.isqrt(value)) + 2
        else:
            answer = int(math.isqrt(value))
        logger.info(f"Calculated sqrt({value}) = {answer}")

        # Create and sign EIP-712 message
        full_message = self._create_eip712_message(task_id, answer)
        signed = Account.sign_typed_data(
            self.account.key,
            full_message=full_message
        )
        logger.info("Created signature for task completion")

        # Submit transaction
        self._submit_task_completion(task_id, answer, signed.signature)

    def _submit_task_completion(self, task_id, answer, signature):
        nonce = self.w3.eth.get_transaction_count(self.account.address)
        gas_price = self.w3.eth.gas_price
        
        tx = self.contract.functions.completeTask(
            task_id,
            answer,
            signature,
            [], # stake hints
            []  # slash hints
        ).build_transaction({
            'from': self.account.address,
            'nonce': nonce,
            'gas': 500000,
            'gasPrice': gas_price
        })
        
        signed_tx = self.w3.eth.account.sign_transaction(tx, self.account.key)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        logger.info(f"Submitted task {task_id}, waiting for confirmation. Tx hash: {tx_hash.hex()}")
        
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        logger.info(f"Task {task_id} confirmed on chain")

    def _update_block_cache(self, block_number):
        if block_number > self.last_processed_block:
            self.last_processed_block = block_number
            with open(self.cache_file, 'w') as f:
                f.write(str(self.last_processed_block))
            logger.info(f"Updated block cache to {block_number}")

    def process_tasks(self):
        if self.last_processed_block == -1:
            self.last_processed_block = 2951000

        while True:
            try:
                # Get logs directly using get_logs
                events = self.contract.events.CreateTask().get_logs(
                    from_block=self.last_processed_block,
                    argument_filters={'operator': [self.account.address]}
                )

                # Process the raw logs
                for event in events:
                    # Decode the event data
                    task_id = event['args']['taskIndex']
                    block_number = event['blockNumber']
                    logger.info(f"New task detected: {task_id} in block {block_number}")

                    task = self.contract.functions.tasks(task_id).call()
                    logger.info(f"Checking task {task_id}")
                    
                    self._process_task(task_id, task)
                    self._update_block_cache(block_number)

            except Exception as e:
                logger.error(f"Error processing tasks: {e}", exc_info=True)
                
            time.sleep(60)

@click.group()
def cli():
    pass

@cli.command()
@click.option('--validator-private-key', required=True, help='Private key for signing transactions')
@click.option('--web3-url', default='https://ethereum-holesky-rpc.publicnode.com', help='Web3 RPC URL')
@click.option('--contract-address', default='0x18586B8cb86b59EF3F44BC915Ef92C83B6BAfd75', help='Contract address')
@click.option('--abi-file', default='abi.json', help='Path to ABI JSON file')
def start(web3_url, validator_private_key, contract_address, abi_file):
    """Start the sqrt task worker"""
    with open(abi_file, 'r') as f:
        contract_abi = json.load(f)

    logger.info("Initializing SqrtTaskWorker")
    worker = SqrtTaskWorker(
        web3_url=web3_url,
        validator_private_key=validator_private_key,
        contract_address=contract_address,
        contract_abi=contract_abi
    )
    
    logger.info("Starting task processing loop")
    worker.process_tasks()

@cli.command()
@click.option('--validator-private-key', required=True, help='Private key for signing transactions')
@click.option('--task-id', required=True, type=int, help='Task ID to complete incorrectly')
@click.option('--web3-url', default='https://ethereum-holesky-rpc.publicnode.com', help='Web3 RPC URL')
@click.option('--contract-address', default='0x18586B8cb86b59EF3F44BC915Ef92C83B6BAfd75', help='Contract address')
@click.option('--abi-file', default='abi.json', help='Path to ABI JSON file')
def submit_incorrect_answer(web3_url, validator_private_key, contract_address, abi_file, task_id):
    """Submit an incorrect answer for a specific task"""
    with open(abi_file, 'r') as f:
        contract_abi = json.load(f)

    logger.info("Initializing SqrtTaskWorker for incorrect task completion")
    worker = SqrtTaskWorker(
        web3_url=web3_url,
        validator_private_key=validator_private_key,
        contract_address=contract_address,
        contract_abi=contract_abi
    )
    
    task = worker.contract.functions.tasks(task_id).call()
    worker._process_task(task_id, task, incorrect=True)

@cli.command()
@click.option('--validator-private-key', required=True, help='Validator private key')
@click.option('--operator-private-key', required=True, help='Private key for signing transactions')
@click.option('--vault-address', default='0x0000000000000000000000000000000000000000', help='Vault address')
@click.option('--web3-url', default='https://ethereum-holesky-rpc.publicnode.com', help='Web3 RPC URL')
@click.option('--contract-address', default='0x18586B8cb86b59EF3F44BC915Ef92C83B6BAfd75', help='Contract address')
@click.option('--abi-file', default='abi.json', help='Path to ABI JSON file')
def register(validator_private_key, vault_address, web3_url, operator_private_key, contract_address, abi_file):
    """Register as an operator"""
    with open(abi_file, 'r') as f:
        contract_abi = json.load(f)

    w3 = Web3(HTTPProvider(web3_url))
    validator_account = Account.from_key(validator_private_key)
    operator_account = Account.from_key(operator_private_key)
    w3.middleware_onion.add(SignAndSendRawMiddlewareBuilder.build(operator_account))
    contract = w3.eth.contract(address=contract_address, abi=contract_abi)
    # Create message hash from packed operator and validator addresses
    message_hash = w3.solidity_keccak(
        ['address', 'address'],
        [operator_account.address, validator_account.address]
    )

    signature = Account.unsafe_sign_hash(
        message_hash,
        private_key=validator_private_key
    )
    
    logger.info("Generated validator signature for operator registration")
    logger.info(f"Registering as operator {operator_account.address} for validator {validator_account.address} and vault {vault_address}")
    
    nonce = w3.eth.get_transaction_count(operator_account.address)
    gas_price = w3.eth.gas_price
    key = Web3.to_bytes(hexstr='00' * 12 + validator_account.address[2:])

    tx = contract.functions.registerOperator(
        key, 
        vault_address, 
        signature.signature
    ).build_transaction({
        'from': operator_account.address,
        'nonce': nonce,
        'gas': 500000,
        'gasPrice': gas_price
    })

    signed_tx = w3.eth.account.sign_transaction(tx, operator_account.key)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    logger.info(f"Registration submitted. Tx hash: {tx_hash.hex()}")
    
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    logger.info("Registration confirmed on chain")


if __name__ == "__main__":
    cli()
