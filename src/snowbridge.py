'''
## SNOW bridge design
    - chain-to-chain python bridge
        chain_a -> burn/lock (solidity)
        chain_b -> mint (solidity)
        bridge  -> listen for chain_a|b burn and triggers chain_b|a mint (python)
    - functional requirements
        1) need to integrate a fee structure (take a % of each SNOW bridged either way)
        2) python needs to track processed event hashes (etc.) to ensure no missed bridge-overs
            - requires thread loop event listener
            - requires database to track processed events
            - requires scaning backlog of events occurred during any down time
            - requires enforced wait time for enough block confirms of "burn", before "minting"
        3) claim process required because sending tokens to receiver costs gas
            - requires SNOW contract to maintain bridged funds waiting to be claimed/minted
                NOTE: this means the client-side does NOT NEED web2 rest APIs to call
        4) SNOW contract will process sender tokens by burning
            - SNOW will be burned on transfer to contract address
        Q: should there be a 'cancel bridge' feature?
    - python integration
        python snowbridge.py:
            # NOTE: no database needed
            #   if python goes down (missed events)
            #    then simply run script starting from any blocknumber
            #    and all txHashes already processed will be skipped/reverted
            def handle_BridgeOutEvent(struct BRIDGE_OUT): # listen loop
                # 1) get txHash for this BridgeOutEvent 
                # 2) invoke: SNOW.TXHASH_BRIDGE(txHash) _ checks if txHash exists
                #       if yes: skip/'continue' to next handle_BridgeOutEvent 
                #        (ie. SNOW contract is updated past that txHash)
                # 3) add txHash to struct BRIDGE_OUT
                # 4) get to_chain from BRIDGE_OUT
                # 5) invoke on to_chain: SNOW.bridge_in(struct BRIDGE_OUT) _ *GAS*
                #       reverts if BRIDGE_OUT.txHash already exists
'''



# ====================================================================================== #
'''
    simplified algorithmic design... _ 011725_2018
    	- running snowbridge.py enables listening for bridging OUT of chain_a
	    -  NOTE: when bridging OUT, use can freely choose where to bridge TO
		    as long as the _chainIdx exists in the bridging OUT (from) contract 
            (ie. the chain_a contract has info for that _chainIdx attempting to be used)
'''
from web3 import Web3
import time, json
from _env import env

# 0xEEd80539c314db19360188A66CccAf9caC887b22
BRIDGE_EOA = env.sender_address_3 
BRIDGE_EOA_PRIVATE_KEY = env.sender_secret_3

# read ABI
with open("../bin/contracts/SnowToken.abi", "r") as f:
    FROM_TO_CHAIN_CA_ABI = json.load(f)

# Connect to the Ethereum network (replace with your provider)
w3 = Web3(Web3.HTTPProvider('https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID'))

# chain rpc urls
CHAIN_A_RPC = "https://rpc.pulsechain.com" # pulsechain -> BURN
CHAIN_B_RPC = "" # avalanche test net -> MINT

# chain contract addresses
CHAIN_A_ADDRESS = "" # pulsechain CA
CHAIN_B_ADDRESS = "0x0" # avalanche test net CA

# set chain ABIs
CHAIN_A_ABI = FROM_TO_CHAIN_CA_ABI
CHAIN_B_ABI = FROM_TO_CHAIN_CA_ABI

# Initialize web3 instances for both chains
web3_chain_a = Web3(Web3.HTTPProvider(CHAIN_A_RPC))
web3_chain_b = Web3(Web3.HTTPProvider(CHAIN_B_RPC))

# Generate contract instances
bridge_burn = web3_chain_a.eth.contract(address=CHAIN_A_ADDRESS, abi=CHAIN_A_ABI)
bridge_mint = web3_chain_b.eth.contract(address=CHAIN_B_ADDRESS, abi=CHAIN_B_ABI)

# set contract address to listen for BridgeOutEvent to come from
contract_address = CHAIN_A_ADDRESS
event_signature = w3.keccak(text="BridgeOutEvent((address,string,uint16,string,uint256,string,uint16,string,uint256,uint256,uint256,uint256,uint256,bytes32,bool))").hex()

# Function to process events
def process_event(event):
    bridge_out = event['args']['_bridgeOut']
    print(f"Event detected in transaction: {event['transactionHash'].hex()}")
    print(f"EOA: {bridge_out['EOA']}")
    print(f"From Chain Name: {bridge_out['from_chain_name']}")
    print(f"From Chain ID: {bridge_out['from_chain_id']}")
    print(f"From Chain RPC: {bridge_out['from_chain_rpc']}")
    print(f"To Chain Index: {bridge_out['to_chain_idx']}")
    print(f"To Chain Name: {bridge_out['to_chain_name']}")
    print(f"To Chain ID: {bridge_out['to_chain_id']}")
    print(f"To Chain RPC: {bridge_out['to_chain_rpc']}")
    print(f"To Chain CA: {bridge_out['to_chain_ca']}")
    print(f"Snow Amount: {bridge_out['snowAmnt']}")
    print(f"Bridge Fee: {bridge_out['bridgeFee']}")
    print(f"Claim Fee: {bridge_out['claimFee']}")
    print(f"Net Amount: {bridge_out['netAmnt']}")
    print(f"Block Number: {bridge_out['blocknumber']}")
    print(f"Transaction Hash: {bridge_out['txHash'].hex()}")
    print(f"Claimed: {bridge_out['claimed']}")

def handle_BridgeOutEvent(event):
    # 1) Get txHash for this BridgeOutEvent
    tx_hash = event['transactionHash']

    # 2) Invoke: SNOW.TXHASH_BRIDGE(txHash)
    #   to check for existing/processed txHash in to_chain (if yes, return/skip)
    bridge_out_check = bridge_mint.functions.TXHASH_BRIDGE(tx_hash).call()
    if bridge_out_check['EOA'] != '0x0000000000000000000000000000000000000000': # if has EOA
        print(f" *** txHash '{tx_hash.hex()}' _ already has EOA / already processed. Skipping... ***")
        return

    # 3) Add event txHash to struct BRIDGE_OUT
    bridge_out = event['args']['_bridgeOut']
    bridge_out['txHash'] = tx_hash

    # 4) Get to_chain info from _bridgeOut
    #    and create contract instance for to_chain_ca
    to_chain_rpc = bridge_out['to_chain_rpc']
    to_chain_ca = bridge_out['to_chain_ca']
    web3_to_chain = Web3(Web3.HTTPProvider(to_chain_rpc))
    bridge_mint_to_chain = web3_to_chain.eth.contract(address=to_chain_ca, abi=CHAIN_B_ABI)

    # 5) Invoke on to_chain: SNOW.bridgeIn(struct BRIDGE_OUT) _ *GAS*
    tx = bridge_mint_to_chain.functions.bridgeIn(bridge_out).buildTransaction({
        'from': BRIDGE_EOA,
        'nonce': web3_to_chain.eth.getTransactionCount(BRIDGE_EOA),
        'gas': 2000000,
        'gasPrice': web3_to_chain.toWei('50', 'gwei')
    })

    # Sign the transaction
    signed_tx = web3_to_chain.eth.account.signTransaction(tx, private_key=BRIDGE_EOA_PRIVATE_KEY)

    # Send the transaction
    tx_hash = web3_to_chain.eth.sendRawTransaction(signed_tx.rawTransaction)

    # Wait for the transaction receipt
    receipt = web3_to_chain.eth.waitForTransactionReceipt(tx_hash)
    print(f"Transaction receipt: {receipt}")

# Function to scan blocks
def scan_blocks(start_block, end_block=None):
    current_block = start_block
    while True:
        if end_block and current_block > end_block:
            break

        block = w3.eth.getBlock(current_block, full_transactions=True)
        for tx in block.transactions:
            if tx.to and tx.to.lower() == contract_address.lower():
                receipt = w3.eth.getTransactionReceipt(tx.hash)
                for log in receipt.logs:
                    if log.topics[0].hex() == event_signature:
                        event = w3.eth.contract(address=contract_address, abi=[]).events.BridgeOutEvent().processLog(log)
                        process_event(event)
                        # handle_BridgeOutEvent(event)

        current_block += 1
        if not end_block:
            time.sleep(15)  # Wait for the next block

# Example usage
start_block = 12345678  # Replace with your start block number
end_block = 12345680  # Replace with your end block number, or set to None for live tracking

scan_blocks(start_block, end_block)

# ====================================================================================== #
# ====================================================================================== #

# # ref: chatgpt_011325
# from web3 import Web3
# import json
# from _env import env
# # RPC URLs for both chains
# CHAIN_A_RPC = "https://rpc.chainA.example" # BridgeBurnLock.sol deployed on this chain
# CHAIN_B_RPC = "https://rpc.chainB.example" # BridgeMint.sol deployed on this chain

# # Smart contract addresses
# BRIDGE_LOCK_ADDRESS = "0x1234567890abcdef1234567890abcdef12345678"
# BRIDGE_MINT_ADDRESS = "0xabcdef1234567890abcdef1234567890abcdef12"

# # read ABIs
# with open("../bin/contracts/BridgeBurnLock.abi", "r") as f:
#     bridge_lock_abi = json.load(f)
# with open("../bin/contracts/BridgeBurnLock.abi", "r") as f:
#     BRIDGE_MINT_ABI = json.load(f)

# # init Web3 instances
# web3_chain_a = Web3(Web3.HTTPProvider(CHAIN_A_RPC)) # BridgeBurnLock.sol deployed on this chain
# web3_chain_b = Web3(Web3.HTTPProvider(CHAIN_B_RPC)) # BridgeMint.sol deployed on this chain

# # generate contract instances
# bridge_lock = web3_chain_a.eth.contract(address=BRIDGE_LOCK_ADDRESS, abi=bridge_lock_abi)
# bridge_mint = web3_chain_b.eth.contract(address=BRIDGE_MINT_ADDRESS, abi=BRIDGE_MINT_ABI)

# # Relayer's private key for signing transactions on Chain B (mints tokens on chain b)
# RELAYER_PRIVATE_KEY = env.sender_secret_3
# RELAYER_ADDRESS = Web3.to_checksum_address(env.sender_address_3)



# def handle_event(event):
#     # Parse event data
#     user = event["args"]["user"]
#     amount = event["args"]["amount"]
#     nonce = event["args"]["nonce"]

#     print(f"Detected lock event: User={user}, Amount={amount}, Nonce={nonce}")

#     # Generate a proof (dummy in this example)
#     proof = b"dummy_proof"

#     # Call mintTokens on Chain B (BridgeMint.sol)
#     tx = bridge_mint.functions.mintTokens(user, amount, nonce, proof).build_transaction({
#         "chainId": web3_chain_b.eth.chain_id,
#         "gas": 200000,
#         "gasPrice": web3_chain_b.eth.gas_price,
#         "nonce": web3_chain_b.eth.get_transaction_count(RELAYER_ADDRESS),
#     })

#     signed_tx = web3_chain_b.eth.account.sign_transaction(tx, private_key=RELAYER_PRIVATE_KEY)
#     tx_hash = web3_chain_b.eth.send_raw_transaction(signed_tx.rawTransaction)
#     print(f"Transaction sent to Chain B: {tx_hash.hex()}")

# def log_loop(event_filter, poll_interval):
#     while True:
#         for event in event_filter.get_new_entries():
#             handle_event(event)
#         time.sleep(poll_interval)

# def main():
#     # Create an event filter for AssetLocked events on Chain A
#     event_filter = bridge_lock.events.AssetLocked.createFilter(fromBlock="latest")

#     print("Listening for events...")
#     log_loop(event_filter, 2)

# if __name__ == "__main__":
#     main()




# # =================================================================== #
# # =================================================================== #
# from web3 import Web3

# # Connect to the Ethereum network (replace with your provider)
# w3 = Web3(Web3.HTTPProvider('https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID'))

# # Contract ABI (replace with your contract's ABI)
# contract_abi = [
#     # ... ABI JSON ...
# ]

# # Contract address (replace with your contract's address)
# contract_address = '0xYourContractAddress'

# # Create contract instance
# contract = w3.eth.contract(address=contract_address, abi=contract_abi)

# # Define the BRIDGE_OUT struct
# bridge_out = {
#     'EOA': '0xYourAddress',
#     'from_chain_name': 'example_chain',
#     'from_chain_id': 1,
#     'from_chain_rpc': 'example_rpc',
#     'to_chain_idx': 0,
#     'to_chain_name': 'example_chain',
#     'to_chain_id': 2,
#     'to_chain_rpc': 'example_rpc',
#     'snowAmnt': 1000,
#     'bridgeFee': 100,
#     'claimFee': 100,
#     'netAmnt': 800,
#     'blocknumber': 12345678,
#     'txHash': '0x0000000000000000000000000000000000000000000000000000000000000000',
#     'claimed': False
# }

# # Define the account and private key (replace with your account and private key)
# account = '0xYourAccount'
# private_key = 'YourPrivateKey'

# # Build the transaction
# transaction = contract.functions.processBridgeOut(bridge_out).buildTransaction({
#     'from': account,
#     'nonce': w3.eth.getTransactionCount(account),
#     'gas': 2000000,
#     'gasPrice': w3.toWei('50', 'gwei')
# })

# # Sign the transaction
# signed_txn = w3.eth.account.signTransaction(transaction, private_key=private_key)

# # Send the transaction
# txn_hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)

# # Wait for the transaction receipt
# txn_receipt = w3.eth.waitForTransactionReceipt(txn_hash)

# print(f'Transaction receipt: {txn_receipt}')
# # =================================================================== #