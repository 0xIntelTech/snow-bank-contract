__fname = '_event_listener' # ported from 'meme-call' (010325)
__filename = __fname + '.py'
cStrDivider = '#================================================================#'
print('', cStrDivider, f'GO _ {__filename} -> starting IMPORTs & declaring globals', cStrDivider, sep='\n')
cStrDivider_1 = '#----------------------------------------------------------------#'

''' house_041824
    ref: https://github.com/tradingstrategy-ai/web3-ethereum-defi/blob/master/scripts/uniswap-v2-swaps-live.py
        uniswap example for decoding swap events

    house_102823
    ref: https://docs.balancer.fi/reference/contracts/apis/vault.html#flashloan
        flashLoan(
            IFlashLoanRecipient recipient,
            IERC20[] tokens,
            uint256[] amounts,
            bytes userData)

        emits FlashLoan(IFlashLoanRecipient indexed recipient,
                        IERC20 indexed token,
                        uint256 amount,
                        uint256 feeAmount)
'''
#------------------------------------------------------------#
# IMPORTS
#------------------------------------------------------------#
import _bst_keeper, _abi, _web3
from web3 import Web3
from _env import env
from datetime import datetime
import sys, os, traceback, time, pprint, json
from ethereum.abi import encode_abi, decode_abi # pip install ethereum

#------------------------------------------------------------#
# GLOBALS
#------------------------------------------------------------#
BLOCK_WAIT_SEC = 10
ADDR_BST = "0x7A580b7Cd9B48Ba729b48B8deb9F4D2cb216aEBC"
ADDR_PDAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
ADDR_BEAR = "0xd6c31bA0754C4383A41c0e9DF042C62b5e918f6d"
DEBUG_LVL = 3

FUNC_SIGN_TRANS_FROM = "transferFrom(address,address,uint256)"
FUNC_HASH_TRANS_FROM = "23b872dd"
ERC20_FUNC_MAP_WRITE = {
    # write functions
    "allowance(address,address)": ["dd62ed3e", ["address","address"], []],
    "approve(address,uint256)": ["095ea7b3", ["address","uint256"], []],
    "transfer(address,uint256)": ["a9059cbb", ["address","uint256"], []],
    FUNC_SIGN_TRANS_FROM: [FUNC_HASH_TRANS_FROM, ["address","address","uint256"], []],
    "renounceOwnership()": ["715018a6", [], []],
    "transferOwnership(address)": ["f2fde38b", ["address"], []],
}
#------------------------------------------------------------#
# FUNCTIONS
#------------------------------------------------------------#
def parse_logs_for_tx_receipt(_tx_receipt, _func_hash, _w3:Web3=None):
    # Get the logs from the transaction receipt
    logs = _tx_receipt['logs']
    d_ret_log = {'err':'no logs found'}
    if _w3 == None: return d_ret_log
    print(f' event logs (for func_hash: {_func_hash}) ...')
    if _func_hash == ERC20_FUNC_MAP_WRITE[FUNC_SIGN_TRANS_FROM][0]:
        # Define & filter logs based on the event signature
        # event Transfer(address indexed from, address indexed to, uint256 value);
        event_sign = _w3.keccak(text="Transfer(address,address,uint256)").hex()
        transfer_logs = [log for log in logs if log['topics'][0].hex() == event_sign]

        # Parse the event logs
        for log in transfer_logs:
            lst_evt_params = ['address','address','uint256']
            evt_data = log['data']
            decoded_data = decode_abi(lst_evt_params, evt_data)
            d_ret_log = {'from':decoded_data[0],
                         'to':decoded_data[1],
                         'value':decoded_data[2]}
        
            # [print(f'   {key}: {val}') for key,val in d_ret_log.items()]
            # print()
            
    return d_ret_log

def parse_logs_for_block_num(_block_number, _event_sign, _contr_addr, _w3:Web3=None):
    lst_ret_log = []
    if _w3 == None: return lst_ret_log
    lst_evt_params = ['address','address','uint256']

    # Get logs for the specified block number and event signature
    event_sign = _w3.keccak(text=_event_sign).hex()
    transfer_logs = _w3.eth.get_logs({
        'fromBlock': _block_number,
        'toBlock': _block_number,
        'address': _contr_addr,
        'topics': [event_sign]            
    })
    
    for logs in transfer_logs:
        # Extract topics & data (ie. indexed & non-indexed params from ABI list)
        topics = [topic for i,topic in enumerate(logs['topics']) if i > 0] # skip topic 0 (event sign)
        data = logs['data']
        log_idx = logs['logIndex']

        # Concatenate topics + data & decode w/ abi params
        event_data = b''.join(topics) + data # NOTE: b' required
        decoded_data = decode_abi(lst_evt_params, event_data)
        d_ret_log = {'log_idx':log_idx,
                        'address (token)':transfer_logs[0]['address'],
                        'from':decoded_data[0],
                        'to':decoded_data[1],
                        'value':float(decoded_data[2]) / 10**18}
        lst_ret_log.append(d_ret_log)
    if len(lst_ret_log) == 0: lst_ret_log = [{'err':'no logs found'}]
    return lst_ret_log

def main(_w3:Web3=None, _tx_hash=None):
    if _tx_hash != None:
        tx_receipt = _w3.eth.get_transaction_receipt(_tx_hash)
        d_ret_log = parse_logs_for_tx_receipt(tx_receipt, FUNC_HASH_TRANS_FROM, _w3)
        [print(f'   {key}: {val}') for key,val in d_ret_log.items()]
        print()
    else:
        # ca = ADDR_PDAI
        # ca = ADDR_BST
        ca = "0xdc318Ea55e15Fd480a7c9baEc6d957Cf602b5063" # SnowToken_v0.5: 0xdc318Ea55e15Fd480a7c9baEc6d957Cf602b5063
        while True: # live...
            block_num = _w3.eth.block_number # blockNumber
            print(cStrDivider_1, f'ca: {ca}', f'block# {block_num} _ {get_time_now()}', sep='\n')
            # ret_log = parse_logs_for_block_num(block_num, FUNC_HASH_TRANS_FROM, ADDR_PDAI, W3_)
            # event Transfer(address indexed from, address indexed to, uint256 value);
            # event_sign = "Transfer(address,address,uint256)"
            event_sign = "BridgeOutEvent(address,string,uint16,string,string,uint16,string,uint256,uint256,uint256,uint256,uint256)"
            print(f"fetching logs for ...\n event: {event_sign}\n address: {ca}\n")
            ret_log = parse_logs_for_block_num(block_num, event_sign, ca, _w3)
            pprint.pprint(ret_log)
            print('', f'block# {block_num} _ {get_time_now()} _ sleep({BLOCK_WAIT_SEC})', cStrDivider_1, sep='\n')
            time.sleep(BLOCK_WAIT_SEC) # ~10sec block times (pc)

def main_BST(_tx_hash='', _func_hash=''):
    if not _tx_hash or len(_tx_hash) == 0:
        # _tx_hash = '0xee2d3d10cfc5fd4c1a42f0de2de96a41ddcbb43773248365815eb8d4c62c3fd5'
        _tx_hash = '0x9bbc67b34aadcf6209a7fc795af7dc68ba44d6879b244b7f87db96806b244e09'
    if not _func_hash or len(_func_hash) == 0:
        _func_hash = _abi.BST_PAYOUT_FUNC_HASH
    print(f'executing ...\n _tx_hash: {_tx_hash}\n func_hash: {_func_hash}')
    tx_receipt = W3_.W3.eth.get_transaction_receipt(_tx_hash)
    d_ret_log = _bst_keeper.parse_logs_for_func_hash(tx_receipt, _func_hash, W3_) # performs print

#------------------------------------------------------------#
#   DEFAULT SUPPORT                                          #
#------------------------------------------------------------#
READ_ME = f'''
    *DESCRIPTION*
        nil

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
        # execute CLI input
        # W3_ = _web3.myWEB3().init_nat(1, env.sender_addr_trinity, env.sender_secr_trinity) # 1 = pulsechain
        W3_ = _web3.myWEB3().init_nat(1, env.sender_address_3, env.sender_secret_3) # 1 = pulsechain (0xEEd80539c314db19360188A66CccAf9caC887b22)
        # W3_.set_gas_params(W3_.W3)

        # select to use prod bot or dev bot
        inp = input('\nSelect run mode:\n  0 = BST events logs \n  1 = Other \n  > ')
        RUN_MODE_BST = True if inp == '0' else False
        print(f'  input = {inp} _ RUN_MODE_BST = {RUN_MODE_BST}\n')

        if RUN_MODE_BST:
            tx_hash = input('Input BST tx hash (leave blank for default testing):\n > ')
            print(f'  input = {tx_hash}\n')
            _func_hash = _abi.BST_PAYOUT_FUNC_HASH
            main_BST(tx_hash, _func_hash)
        else:
            arg = input(f'\n Enter tx hash to get logs for specific tx (use -1 to skip):\n  > ')
            if arg.startswith('0x'): main(_w3=W3_.W3, _tx_hash=arg)
            else: main(_w3=W3_.W3, _tx_hash=None)

            # NOTE: 041724 _ does not work yet ... specifiying tx_hash
            # tx_hash = '0x7ac97de7444bd5f65739e71c20a3962589ce832cba263ccd3aa6a027c6cc02e7'
            # main(_w3=W3_.W3, _tx_hash=tx_hash)
    except Exception as e:
        print_except(e, debugLvl=DEBUG_LVL)
    
    ## end ##
    print(f'\n\nRUN_TIME_START: {RUN_TIME_START}\nRUN_TIME_END:   {get_time_now()}\n')

print('', cStrDivider, f'# END _ {__filename}', cStrDivider, sep='\n')