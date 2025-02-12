__fname = '_deploy_contract' # ported from 'meme-call' (010325)
__filename = __fname + '.py'
cStrDivider = '#================================================================#'
print('', cStrDivider, f'GO _ {__filename} -> starting IMPORTs & declaring globals', cStrDivider, sep='\n')
cStrDivider_1 = '#----------------------------------------------------------------#'

# CLI:
#   $ python3.10 _deploy_contract.py | tee ../bin/receipts/deploy_tBST_17_032424_2109.txt 
#------------------------------------------------------------#
#   IMPORTS                                                  #
#------------------------------------------------------------#
import sys, os, traceback, time, pprint, json
from datetime import datetime

# from web3 import Web3, HTTPProvider
# from web3.middleware import construct_sign_and_send_raw_middleware
# from web3.gas_strategies.time_based import fast_gas_price_strategy
# import env
import pprint
from attributedict.collections import AttributeDict # tx_receipt requirement
import _web3 # from web3 import Account, Web3, HTTPProvider
import _abi # only used as single edge case in 'go_enter_func_params'

SELECT_DEPLOY_ALL = False
LST_CONTR_ABI_BIN = [
    # "../bin/contracts/Multicall",
    "../bin/contracts/SnowLib",
    "../bin/contracts/SnowTimelock",
    "../bin/contracts/SnowNFT",
    "../bin/contracts/SnowToken",
    "../bin/contracts/ZapV3",
    "../bin/contracts/MasterChef",
    "../bin/contracts/SnowConfig",
]

W3_ = None
ABI_FILE = None
BIN_FILE = None
CONTRACT = None

def init_web3_all():
    global W3_, ABI_FILE, BIN_FILE, CONTRACT
    # init W3_, user select abi to deploy, generate contract & deploy
    W3_ = _web3.myWEB3().init_inp()
    # lst_tup_abi_bin_path = []
    lst_contracts = []
    lst_contract_names = []
    lst_contract_file_paths = []
    print('*WARNING* detected SELECT_DEPLOY_ALL == True ...')
    print(' Gathering all ABIs & BINs to build all contracts in "LST_CONTR_ABI_BIN" ...')
    for i, v in enumerate(LST_CONTR_ABI_BIN): print(' ',i,'=',f'{v} _ {W3_.get_file_dt(v+".bin")}') # parse through tuple
    for i,v in enumerate(LST_CONTR_ABI_BIN):
        contr_name = LST_CONTR_ABI_BIN[i].split('/')[-1]
        # CallitConfig (bc i needs the addresses of the other)
        if contr_name == 'CallitConfig': 
            print('\nIGNORING CallitConfig ... just FYI ;) ')
            continue

        contract_ = W3_.add_contract_deploy(LST_CONTR_ABI_BIN[i]+'.abi', LST_CONTR_ABI_BIN[i]+'.bin')
        lst_contracts.append(contract_)
        lst_contract_names.append(contr_name)
        lst_contract_file_paths.append((LST_CONTR_ABI_BIN[i]+'.abi', LST_CONTR_ABI_BIN[i]+'.bin'))

    return lst_contracts, lst_contract_names, lst_contract_file_paths

def init_web3():
    global W3_, ABI_FILE, BIN_FILE, CONTRACT
    # init W3_, user select abi to deploy, generate contract & deploy
    W3_ = _web3.myWEB3().init_inp()
    ABI_FILE, BIN_FILE, idx_contr = W3_.inp_sel_abi_bin(LST_CONTR_ABI_BIN) # returns .abi|bin
    CONTRACT = W3_.add_contract_deploy(ABI_FILE, BIN_FILE)
    contr_name = LST_CONTR_ABI_BIN[idx_contr].split('/')[-1]
    return contr_name

def estimate_gas(contract, contract_args=[]):
    global W3_, ABI_FILE, BIN_FILE, CONTRACT
    # Replace with your contract's ABI and bytecode
    # contract_abi = CONTR_ABI
    # contract_bytecode = CONTR_BYTES
    
    # Replace with your wallet's private key
    private_key = W3_.SENDER_SECRET

    # Create a web3.py contract object
    # contract = W3_.W3.eth.contract(abi=contract_abi, bytecode=contract_bytecode)

    # Set the sender's address from the private key
    sender_address = W3_.W3.eth.account.from_key(private_key).address

    # Estimate gas for contract deployment
    # gas_estimate = contract.constructor().estimateGas({'from': sender_address})
    gas_estimate = contract.constructor(*contract_args).estimate_gas({'from': sender_address})

    print(f"\nEstimated gas cost _ 0: {gas_estimate}")

    import statistics
    block = W3_.W3.eth.get_block("latest", full_transactions=True)
    gas_estimate = int(statistics.median(t.gas for t in block.transactions))
    gas_price = W3_.W3.eth.gas_price
    gas_price_eth = W3_.W3.from_wei(gas_price, 'ether')
    print(f"Estimated gas cost _ 1: {gas_estimate}")
    print(f" Current gas price: {gas_price_eth} ether (PLS) == {gas_price} wei")
    # Optionally, you can also estimate the gas price (in Gwei) using a gas price strategy
    # Replace 'fast' with other strategies like 'medium' or 'slow' as needed
    #gas_price = W3.eth.generateGasPrice(fast_gas_price_strategy)
    #print(f"Estimated gas price (Gwei): {W3.fromWei(gas_price, 'gwei')}")
    
    return input('\n (3) procced? [y/n]\n  > ') == 'y'

# note: params checked/set in priority order; 'def|max_params' uses 'mpf_ratio'
#   if all params == False, falls back to 'min_params=True' (ie. just use 'gas_limit')
def get_gas_params_lst(rpc_url, min_params=False, max_params=False, def_params=True):
    global W3_, ABI_FILE, BIN_FILE, CONTRACT
    # Estimate the gas cost for the transaction
    #gas_estimate = buy_tx.estimate_gas()
    gas_limit = W3_.GAS_LIMIT # max gas units to use for tx (required)
    gas_price = W3_.GAS_PRICE # price to pay for each unit of gas (optional?)
    max_fee = W3_.MAX_FEE # max fee per gas unit to pay (optional?)
    max_prior_fee = W3_.MAX_PRIOR_FEE # max fee per gas unit to pay for priority (faster) (optional)
    #max_priority_fee = W3.to_wei('0.000000003', 'ether')

    if min_params:
        return [{'gas':gas_limit}]
    elif max_params:
        #return [{'gas':gas_limit}, {'gasPrice': gas_price}, {'maxFeePerGas': max_fee}, {'maxPriorityFeePerGas': max_prior_fee}]
        return [{'gas':gas_limit}, {'maxFeePerGas': max_fee}, {'maxPriorityFeePerGas': max_prior_fee}]
    elif def_params:
        return [{'gas':gas_limit}, {'maxPriorityFeePerGas': max_prior_fee}]
    else:
        return [{'gas':gas_limit}]

def generate_contructor(_str_constructor):
    constr_args = []
    print()
    print(f' Set multiple constructor args (one-at-a-time) for: "{_str_constructor}" ...')
    while True:
        arg = input(f'  Add constructor arg (use -1 to end):\n  > ')
        if arg == '-1': break
        # if arg.isdigit(): arg = int(arg)
        if arg.lower() == 'true': constr_args.append(True)
        elif arg.lower() == 'false': constr_args.append(False)
        elif arg.isdigit(): constr_args.append(int(arg))
        else: constr_args.append(arg)
    return constr_args

def go_enter_func_params(_func_select):
    lst_func_params = []
    value_in_wei = 0
    ans = input(f'\n  Enter params for: "{_func_select}"\n  > ')
    for v in list(ans.split()):
        if v.lower() == 'true': lst_func_params.append(True)
        elif v.lower() == 'false': lst_func_params.append(False)
        elif v.isdigit(): lst_func_params.append(int(v))
        elif v.startswith('['):
            lst_str = [i.strip() for i in v[1:-1].split(',')]
            if lst_str[0][1:3] == '0x':
                # appned list of addresses
                lst_func_params.append([W3_.W3.to_checksum_address(i) for i in lst_str])
            elif lst_str[0].isdigit():
                # append list of ints                
                lst_func_params.append([int(i) for i in lst_str])
            else:
                # fall back to appending list of strings
                lst_func_params.append(lst_str)
        else: lst_func_params.append(v)

    # handle edge case: uniswap 'addLiquidityETH'
    if _func_select == _abi.ROUTERv2_FUNC_ADD_LIQ_ETH:
        print(f'\n  found edge case in "{_func_select}"')
        print(f'   inserting & appending additional params to lst_func_params ...\n')
        # lst_func_params[0] = 'token' -> input OG (static idx)
        # lst_func_params[1] = 'amountTokenDesired' -> input OG (static idx)
        # lst_func_params[2] = 'amountETHMin' -> input OG (dynamic idx)
        lst_func_params.insert(2, int(lst_func_params[1])) # insert 'amountTokenMin' into idx #2 (push 'amountETHMin' to #3)
        lst_func_params[3] = W3_.Web3.to_wei(int(float(lst_func_params[3])), 'ether') # update idx #3 'amountETHMin'
        lst_func_params.append(W3_.SENDER_ADDRESS) # append idx #4 -> 'to' 
        lst_func_params.append(int(time.time()) + 3600) # append idx #5 -> 'deadline' == now + 3600 seconds = 1 hour from now

        value_in_wei = lst_func_params[3] # get return value in wei (for write_with_hash)

    print(f'  executing "{_func_select}" w/ params: {lst_func_params} ...\n')
    return lst_func_params, value_in_wei

def main():
    # import _keeper
    global W3_, ABI_FILE, BIN_FILE, CONTRACT
    contr_name = init_web3()
    tx_nonce = W3_.W3.eth.get_transaction_count(W3_.SENDER_ADDRESS)
    print(f'\nDEPLOYING bytecode: {BIN_FILE}')
    print(f'DEPLOYING abi: {ABI_FILE}')
    print(f'DEPLOYING w/ nonce: {tx_nonce}')
    assert input('\n (1) procced? [y/n]\n  > ') == 'y', "aborted...\n"

    constr_args = generate_contructor(f'{contr_name}.constructor(...)') # 0x78b48b71C8BaBd02589e3bAe82238EC78966290c
    # constr_args, _ = _keeper.go_enter_func_params(f'{contr_name}.constructor(...)')
    # constr_args, _ = go_enter_func_params(f'{contr_name}.constructor(...)')
    
    print(f'  using "constructor({", ".join(map(str, constr_args))})"')
    assert input(f'\n (2) procced? [y/n] _ {get_time_now()}\n  > ') == 'y', "aborted...\n"

    # proceed = estimate_gas(CONTRACT, constr_args) # (3) proceed? [y/n]
    # assert proceed, "\ndeployment canceled after gas estimate\n"

    print('\ncalculating gas ...')
    # tx_nonce = W3_.W3.eth.get_transaction_count(W3_.SENDER_ADDRESS)
    tx_params = {
        'chainId': W3_.CHAIN_ID,
        'nonce': tx_nonce,
    }
    lst_gas_params = get_gas_params_lst(W3_.RPC_URL, min_params=False, max_params=True, def_params=True)
    for d in lst_gas_params: tx_params.update(d) # append gas params

    print(f'building tx w/ NONCE: {tx_nonce} ...')
    # constructor_tx = CONTRACT.constructor().build_transaction(tx_params)
    constructor_tx = CONTRACT.constructor(*constr_args).build_transaction(tx_params)

    print(f'signing and sending tx ... {get_time_now()}')
    # Sign and send the transaction # Deploy the contract
    tx_signed = W3_.W3.eth.account.sign_transaction(constructor_tx, private_key=W3_.SENDER_SECRET)
    tx_hash = W3_.W3.eth.send_raw_transaction(tx_signed.rawTransaction)

    print(cStrDivider_1, f'waiting for receipt ... {get_time_now()}', sep='\n')
    print(f'    tx_hash: {tx_hash.hex()}')

    # Wait for the transaction to be mined
    wait_time = 300 # sec
    try:
        tx_receipt = W3_.W3.eth.wait_for_transaction_receipt(tx_hash, timeout=wait_time)
        print("Transaction confirmed in block:", tx_receipt.blockNumber, f' ... {get_time_now()}')
    # except W3_.W3.exceptions.TransactionNotFound:    
    #     print(f"Transaction not found within the specified timeout... wait_time: {wait_time}", f' ... {get_time_now()}')
    # except W3_.W3.exceptions.TimeExhausted:
    #     print(f"Transaction not confirmed within the specified timeout... wait_time: {wait_time}", f' ... {get_time_now()}')
    except Exception as e:
        print(f"\n{get_time_now()}\n Transaction not confirmed within the specified timeout... wait_time: {wait_time}")
        print_except(e)
        exit(1)

    # print incoming tx receipt (requires pprint & AttributeDict)
    tx_receipt = AttributeDict(tx_receipt) # import required
    tx_rc_print = pprint.PrettyPrinter().pformat(tx_receipt)
    print(cStrDivider_1, f'RECEIPT:\n {tx_rc_print}', sep='\n')
    print(cStrDivider_1, f"\n\n Contract deployed at address: {tx_receipt['contractAddress']}\n\n", sep='\n')

def main_deploy_all():
    # import _keeper
    global W3_, ABI_FILE, BIN_FILE, CONTRACT
    lst_constructor_tx = []
    lst_nonce_tx = []

    # select chain, read/init abis & bins, set gas, return contract list
    lst_contracts, lst_contr_names, lst_contract_file_paths = init_web3_all() 
    for i in range(0, len(lst_contracts)):
        tx_nonce = W3_.W3.eth.get_transaction_count(W3_.SENDER_ADDRESS) + i
        print(f'\nBUILDING...\n bytecode: {lst_contract_file_paths[i][1]}')
        print(f' abi: {lst_contract_file_paths[i][0]}')
        print(f' w/ nonce: {tx_nonce}')
        # assert input('\n (1) procced? [y/n]\n  > ') == 'y', "aborted...\n"

        constr_args = generate_contructor(f'{lst_contr_names[i]}.constructor(...)') # 0x78b48b71C8BaBd02589e3bAe82238EC78966290c
        # constr_args, _ = _keeper.go_enter_func_params(f'{lst_contr_names[i]}.constructor(...)')
        # constr_args, _ = go_enter_func_params(f'{lst_contr_names[i]}.constructor(...)')
        
        print(f'  using "constructor({", ".join(map(str, constr_args))})"')
        # assert input(f'\n (2) procced? [y/n] _ {get_time_now()}\n  > ') == 'y', "aborted...\n"

        # proceed = estimate_gas(CONTRACT, constr_args) # (3) proceed? [y/n]
        # assert proceed, "\ndeployment canceled after gas estimate\n"

        print('\n calculating gas ...')
        # tx_nonce = W3_.W3.eth.get_transaction_count(W3_.SENDER_ADDRESS)
        tx_params = {
            'chainId': W3_.CHAIN_ID,
            'nonce': tx_nonce,
        }
        lst_gas_params = get_gas_params_lst(W3_.RPC_URL, min_params=False, max_params=True, def_params=True)
        for d in lst_gas_params: tx_params.update(d) # append gas params

        print(f' staging tx #{i} w/ NONCE: {tx_nonce} ...')
        # constructor_tx = CONTRACT.constructor().build_transaction(tx_params)
        constructor_tx = lst_contracts[i].constructor(*constr_args).build_transaction(tx_params)
        lst_constructor_tx.append(constructor_tx)
        lst_nonce_tx.append(tx_nonce)

    dict_contr_addr = {}
    for j in range(0, len(lst_constructor_tx)):
        print('', cStrDivider_1, f'SIGNING & SENDING tx #{j} ({lst_contr_names[j]}) _ w/ NONCE: {lst_nonce_tx[j]} ... {get_time_now()}', sep='\n')
        # Sign and send the transaction # Deploy the contract
        tx_signed = W3_.W3.eth.account.sign_transaction(lst_constructor_tx[j], private_key=W3_.SENDER_SECRET)
        tx_hash = W3_.W3.eth.send_raw_transaction(tx_signed.rawTransaction)

        print(cStrDivider_1, f'waiting for receipt ... {get_time_now()}', sep='\n')
        print(f'    tx_hash: {tx_hash.hex()}')

        # Wait for the transaction to be mined
        wait_time = 300 # sec
        try:
            tx_receipt = W3_.W3.eth.wait_for_transaction_receipt(tx_hash, timeout=wait_time)
            print("Transaction confirmed in block:", tx_receipt.blockNumber, f' ... {get_time_now()}')
        # except W3_.W3.exceptions.TransactionNotFound:    
        #     print(f"Transaction not found within the specified timeout... wait_time: {wait_time}", f' ... {get_time_now()}')
        # except W3_.W3.exceptions.TimeExhausted:
        #     print(f"Transaction not confirmed within the specified timeout... wait_time: {wait_time}", f' ... {get_time_now()}')
        except Exception as e:
            print(f"\n{get_time_now()}\n Transaction not confirmed within the specified timeout... wait_time: {wait_time}")
            print_except(e)
            # exit(1)
            continue

        # print incoming tx receipt (requires pprint & AttributeDict)
        tx_receipt = AttributeDict(tx_receipt) # import required
        tx_rc_print = pprint.PrettyPrinter().pformat(tx_receipt)
        print(cStrDivider_1, f'RECEIPT:\n {tx_rc_print}', sep='\n')
        print(cStrDivider_1, f"\n\n Contract deployed at address: {tx_receipt['contractAddress']}\n\n", sep='\n')

        dict_contr_addr[lst_contr_names[j]] = tx_receipt['contractAddress']

    print(cStrDivider_1, f'DEPLOYED CONTRACTS ...', cStrDivider_1, sep='\n')
    # print(*(f"{key}: {val}" for key, val in dict_contr_addr.items()), sep='\n')``
    print(*(f"{key}: {val}" for key, val in reversed(list(dict_contr_addr.items()))), sep='\n')
    print()

#------------------------------------------------------------#
#   DEFAULT SUPPORT                                          #
#------------------------------------------------------------#
READ_ME = f'''
    *DESCRIPTION*
        deploy contract to chain
         selects .abi & .bin from ../bin/contracts/

    *NOTE* INPUT PARAMS...
        nil
        
    *EXAMPLE EXECUTION*
        $ python3 {__filename} -<nil> <nil>
        $ python3 {__filename}
'''

#ref: https://stackoverflow.com/a/1278740/2298002
def print_except(e, debugLvl=0):
    #print(type(e), e.args, e)
    if debugLvl >= 0:
        print('', cStrDivider, f' Exception Caught _ e: {e}', cStrDivider, sep='\n')
    if debugLvl >= 1:
        print('', cStrDivider, f' Exception Caught _ type(e): {type(e)}', cStrDivider, sep='\n')
    if debugLvl >= 2:
        print('', cStrDivider, f' Exception Caught _ e.args: {e.args}', cStrDivider, sep='\n')
    if debugLvl >= 3:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        strTrace = traceback.format_exc()
        print('', cStrDivider, f' type: {exc_type}', f' file: {fname}', f' line_no: {exc_tb.tb_lineno}', f' traceback: {strTrace}', cStrDivider, sep='\n')

def wait_sleep(wait_sec : int, b_print=True, bp_one_line=True): # sleep 'wait_sec'
    print(f'waiting... {wait_sec} sec')
    for s in range(wait_sec, 0, -1):
        if b_print and bp_one_line: print(wait_sec-s+1, end=' ', flush=True)
        if b_print and not bp_one_line: print('wait ', s, sep='', end='\n')
        time.sleep(1)
    if bp_one_line and b_print: print() # line break if needed
    print(f'waiting... {wait_sec} sec _ DONE')

def get_time_now(dt=True):
    if dt: return '['+datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[0:-4]+']'
    return '['+datetime.now().strftime("%H:%M:%S.%f")[0:-4]+']'

def read_cli_args():
    print(f'\nread_cli_args...\n # of args: {len(sys.argv)}\n argv lst: {str(sys.argv)}')
    for idx, val in enumerate(sys.argv): print(f' argv[{idx}]: {val}')
    print('read_cli_args _ DONE\n')
    return sys.argv, len(sys.argv)

if __name__ == "__main__":
    ## start ##
    RUN_TIME_START = get_time_now()
    print(f'\n\nRUN_TIME_START: {RUN_TIME_START}\n'+READ_ME)
    lst_argv_OG, argv_cnt = read_cli_args()
    
    ## exe ##
    try:
        SELECT_DEPLOY_ALL = input(' Deploy all contracts in "LST_CONTR_ABI_BIN"? [y/n]\n > ')
        SELECT_DEPLOY_ALL = SELECT_DEPLOY_ALL.lower() == 'y' or SELECT_DEPLOY_ALL == '1'
        if SELECT_DEPLOY_ALL:
            print(' *WARNING* detected SELECT_DEPLOY_ALL == True ...')
            main_deploy_all()
        else:
            main()
        
    except Exception as e:
        print_except(e, debugLvl=0)
    
    ## end ##
    print(f'\n\nRUN_TIME_START: {RUN_TIME_START}\nRUN_TIME_END:   {get_time_now()}\n')

print('', cStrDivider, f'# END _ {__filename}', cStrDivider, sep='\n')
