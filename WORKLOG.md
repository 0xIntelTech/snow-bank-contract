# todo-log

# ------------------------------------------------ #
## work log | backlog
    010625: _hrs + _hrs (prev) = _hrs (total)
    010625: _hrs + _hrs (prev) = _hrs (total)
    010625: _hrs + _hrs (prev) = _hrs (total)
        - continue BILL design doc review:
            https://mystery-dao.gitbook.io/bill-token/bill-tokenomics
        - migrate control of this repo (snowbank-dev) to admin github account
        - deploy snow on avalanche and pulsechain
        WORKING - snow: left off here ...
            - snow: integrate cool down in SNOW.getCurrentTaxRate()
            - snow: migrate chef globals over to CONF
        WORKING - snow bridge: finalize python bridge integration (ref: readme.md -> SNOW bridge design)
            DONE - python: handleEvent(bridgeOut)
            DONE - solidity: bridgeOut, bridgeIn, bridgeClaim
            - debug: ISnowLib.BRIDGE_OUT receives 'stack too deep' error (need alt design for this struct)
            - deply new snow on pulsechain
            - deploy snow on avalance test net (need RPC info)
            - test snowbridge.py pulsechain to avalanche (chan_a=pulsechain,chain_b=avalanche)        
        WORKING - review MasterChef.sol -> _allocPoint integration
        WORKING - review potential front-end devs (x3)
            WORKING - 1) https://github.com/intellltech
            2) https://github.com/asilenced/bill (jacob)
                - https://www.pioneerlegends.io/
                - https://slowrug.io/play
                - https://www.shreddedapes-staking.io/
            3) https://github.com/green901612
        HOLD - front-end:
            - front-end: get 'SNOW_Bank-eth-testnet' talking to newly deployed contracts on pulsechain
            - update addresses.js w/ pulsechain contracts & test to see what displays
        - create python script for easy deployment on additional EVM chains (w/ how-to guide)
        - design SnowVault.sol for storing all globals (so CONF & all other .sol can be re-deployed freely for updates)
        - review 'quicknode' integraiton to help with faster tx (TG admin: "like a cloud RPC you pay for")

## work log | week #3 | start: 011925 | hours: _ | total hours: _ (112 prev)
    Week #3 goals (priority scrum tasks)
        PIVOT - 1) finish testing snow bridge between pulsechain & avalanche test net
        PIVOT - 2) design & integration of BILL smart contract (w/ bridge support)
        PIVOT - 3) create & test BILL LPs on dev.snowbank.io
        PIVOT - 4) test BILL bridging between pulsechain & avalanche test net
        ROLLOVER - 5) assist with steven and bluehost file system cleanup (git integration & deploying dev.snowbank.io)
        ROLLOVER - 6) organize all github repos to be used and transfer control to admin's github account (~3 repos)
        7) sonic: test deploy snow (pre-referral|bridge integration)

    012525: _hrs + _hrs (prev) = _hrs (total) 
    012425: _hrs + _hrs (prev) = _hrs (total) 
    012325: _hrs + 10hrs (prev) = _hrs (total)
        - steven: manage pivot progress (TG)
        - sonic: review & design snow deploy (git analsys/contract requirements)
                - git branch migration for sonic deploy (revert back to before bridge branch)
                
        - sonic: test deploy snow (pre-referral|bridge integration)
        - bluehost: create shell scripts for node build & deploy of dev.snowbank.io
            ref: ./knowledgebase/node_common_tasks.pdf

    012225: 8hrs + 2hrs (prev) = 10hrs (total) 
        WORKING - sonic: test deploy snow (pre-referral|bridge integration)
        DONE - steven: discuss pivot progress (TG)
        ROLLOVER - bridge: fix snow token build errors (stack too deep issues)
        DONE - debug: ISnowLib.BRIDGE_OUT receives 'stack too deep' error
                solution: need alt design for this struct (TODO)
        DONE - bridge: finalize python bridge integration (ref: readme.md -> SNOW bridge design)
            DONE - python: handleEvent(bridgeOut)
            DONE - solidity: bridgeOut, bridgeIn, bridgeClaim

    012025 - 012125: 2hrs + 0hrs (prev) = 2hrs (total) 
        WORKING - bridge: finalize python bridge integration (ref: readme.md -> SNOW bridge design)
                DONE - testing

## work log | week #2 | start: 011325 | hours: 43 | total hours: 112 (69 prev)
    Week #2 goals (priority scrum tasks)
        DONE - 1) build centralized python bridge between avalanche test net and pulsechain
        WORKING - 2) test bridging snow between pulsechain and avalanche
        WORKING - 3) deploy snow probject to avalanche test net
        DONE - 4) assist with steven and bluehost file system cleanup (git integration & deploying dev.snowbank.io)
        DONE - 5) assist with steven in referral testing (w/ latest front-end from legend)
        ROLLOVER - 6) organize all github repos to be used and transfer control to admin's github account (~3 repos)
        
    011825: 1hrs + 42hrs (prev) = 43hrs (total) 
        WORKING - bridge: finalize python bridge integration (ref: readme.md -> SNOW bridge design)
                DONE - python handleEvent(bridgeOut)
                - deply new snow on pulsechain
                - deploy snow on avalance test net (need RPC info)
                - test snowbridge.py pulsechain to avalanche (chan_a=pulsechain,chain_b=avalanche)        

    011725: 8hrs + 34hrs (prev) = 42hrs (total) 
        DONE - bridge: finalize python bridge integration (ref: readme.md -> SNOW bridge design)
                DONE - python handleEvent(bridgeOut)
        DONE - bridge: added support for multipel chain selection (in SNOW.bridgeOut)
        DONE - TG correspondants and steven support
        DONE - bridge: finalize front-end work flow for steven
            FUNCTIONS to call ...
            1) SNOW.bridgeOut(_snowAmnt, _chainIdx)
            2) SNOW.bridgeClaim(_claimIdx, bool _all)
            4) SNOW.EOA_BRIDGE_INS(wallet)
            5) SNOW.EOA_BRIDGE_OUTS(wallet)

            WORK FLOW / USE CASE ...
            1) user invokes 'bridgeOut' from your dapp
                - w/ snow amount and what chain to bridge to
                - that snow amount gets burned
            2) user switches to the chain they bridge to
            3) user invokes 'bridgeClaim(_claimIdx, _all)'
                - _all = true (pay all unclaimed)
                - _all = false (pay specific _idx of pending bridge-in claims list)
                - user expects ~90 block delay (before claims succeed)
            4) get list of bridge-in claims
                - SNOW.EOA_BRIDGE_INS(wallet)
                    'EOA_BRIDGE_INS(wallet).claimed=false' -> pending
            5) get list of bridge-outs
                - SNOW.EOA_BRIDGE_OUTS(wallet)

            NOTE: EOA_BRIDGE_INS|OUTS struct (screenshot above)

    011625: 8hrs + 26hrs (prev) = 34hrs (total) 
        DONE - bridge: start integration of python bridge (ref: readme.md -> SNOW bridge design)
                ROLLOVER- finalize python handleEvent(bridgeOut)
        DONE - bridge: start integration of solidity side requirements (ref: readme.md -> SNOW bridge design)
                DONE - SNOW.bridgeOut()
                DONE - SNOW.bridgeIn()
                DONE - SNOW.bridgeClaim()
        DONE - re-deploy eveything w/ new CONF.owner() model for all .sol
        DONE - snow: debugging zap-in and deposit testing with legend (seems to be working now)
                fix: snowLP needs to be the _target since snowLP was added to chef pools (not SNOW token)
            
    011525: 6hrs + 20hrs (prev) = 26hrs (total) 
        DONE - snow: re-deploy all contracts and set initial configs for steven client-side testing
        DONE - snow: debug zap issue with 'zapIntoFarmWithETH|zapIntoFarmWithToken'
            TG: requesting help from legend
        DONE - bridge: finalize code base design model (python & solidity)
            python snowbridge.py:
                def handle_BridgeOutEvent(struct BRIDGE_OUT): # listen loop
                    # add/fill: txHash in struct BRIDGE_OUT
                    # invoke: SNOW.bridge_in(struct BRIDGE_OUT) _ *cost GAS*
                    # insert db: id, dt_created|updated, struct BRIDGE_OUT

                # NOTE: need to maintain db
                #   delete old BRIDGE_OUT.blocknumber entries weekly

            solidity SNOW.sol:
                struct BRIDGE_OUT {
                    EOA (msg.sender)
                    from|to_chain
                    from|to_chainID
                    from|to_chain_rpc
                    snowAmnt
                    blocknumber
                    txHash -> filled in python
                    synced=true
                }
                address treasAddr;
                uint16 PERC_CLAIM_FEE = 300; // 300 = 3.00%
                mapping(address => BRIDGE_OUT[]) public EOA_BRIDGE_OUTS;
                address[] public BRIDGE_EOAS;
                function bridge_out(snowAmnt)
                    // generate struct BRIDGE_OUT (w/o txHash)
                    // burn(snowAmnt)
                    // emit BridgeOutEvent(struct BRIDGE_OUT)
                function bridge_in(struct BRIDGE_OUT)
                    // append BRIDGE_OUT to EOA_BRIDGE_OUTS[msg.sender][]
                    //  if new bridger, also append msg.sender to BRIDGE_EOAS[]
                function bridge_claim() 
                    // find 'i': block.number > EOA_BRIDGE_OUTS[msg.sender][i].blocknumber + MIN_BLOCK_CNT
                    // validate: EOA_BRIDGE_OUTS[msg.sender][i].snowAmnt > 0
                    // calc bridge_fee: PERC_CLAIM_FEE * [i].snowAmnt
                    // send [i].snowAmnt - bridge_fee to [i].EOA
                    // send bridge_fee to treasAddr
                    // delete EOA_BRIDGE_OUTS[msg.sender][i]
                
    011425: 9hrs + 11hrs (prev) = 20hrs (total) 
        IN-SCOPE:
            ROLLOVER - snow: re-deploy all contracts with latest updates (deploy algorithm in README.md)
                - run through deploy process in README.md
            DONE - snow: update zap init configs after re-deploy
            DONE - bridge: finalize design in README.md
        OUT-SCOPE
            n/a - call w/ steven: review this weeks goals (scrum)
            DONE - TG steve: referral integration support
            DONE - TG legend: debug zapIntoFarmWithETH & zapIntoFarmWithToken
            DONE - ZAP re-deploy and config (legend has owner of zap v0.2)
            DONE - debug zap issue w/ cross contract support (due to non-owner from zap v0.2)

    011325: 6hrs + 5hrs (prev) = 11hrs (total)
        IN-SCOPE:
            DONE - snow: updates xap support with CONF and ownable
            DONE - bridge: start design of chain-to-chain python bridge
                chain_a -> burn/lock
                chain_b -> mint
                bridge  -> listen for chain_a burn and triggers chain_b mint (ie. a <-> b)
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
            DONE - snow: update all time lock queueTx_* functions w/ wait time params
            DONE - organize & send week#2 scrum goals (below) to admin
        OUT-SCOPE
            DONE - TG debug sessions w/ steven and legends

    011225: 5hrs + 0hrs (prev) = 5hrs (total) -> week#1 rollover
        DONE - work with legend
        DONE - finalize design & integration of timelock / delay integration (using SnowTimelock.sol in CONF)
            DONE - review: SnowNFT.setNFTPrice()
            DONE - review: MasterChef.updateEmissionRate()
            DONE - review: SnowConfig.setDevAddress() _ queueTx_setDev
            DONE - review: MasterChef.add|set() _queueTx_add|set
                DONE - integrated new SnowTimelock.sol
            DONE - review: "transferOwnership()" (now indeed doable w/ latest timelock model and _ownerCheck() override)
                n/a - requires losing owner control to time lock contract, during lock/transition time
                DONE - owner model update (ovverrriding _checkOwner())
                	    DONE - all admin function across the project will now reference CONF
	                    DONE - this means owners across all contracts can be renounced
            DONE - weekly scrum TG "call" with admin
                week #2 goals
                    1) assist with steven in file system migration
                    2) assist with steven in referral testing (w/ latest front-end)
                    3) deploy snow probject to avalanche test net
                    4) build centralized bridge between avalanche test net and pulsechain
                    5) test w/ POC gui maybe

## work log | week #1 | start: 010625 | hours: ~45 | total hours: 69 (prev 24)
    Week #1 scrum tasks (priority)
        BACKLOG - deploy snow on avalanche and pulsechain
        ROLLOVER - create python script for easy deployment on additional EVM chains (w/ how-to guide)
        DONE - master chef defi features (current gui)
            DONE - review/remove 'setSnowX' (n/a in latest master chef)
            DONE - timelock integration (ie. delay global updates for taking effect for x amount of hrs)
                NOTE: reviewed TimeLock.sol but may not be correcct for this use case
                        can't handle functions that need to reference msg.sender
                function requiring delay in execution (ie. set-it & forget-it)
                    DONE - MasterChef.add() -> new SnowTimelock.sol
                    DONE - MasterChef.set() -> new SnowTimelock.sol
                    DONE - MasterChef.updateEmissionRate()
                    DONE - SnowConfig.setDevAddress()
                    DONE - setAmountPerNFT() -> i think this means "price" in latest legacy repo (now in SnowNFT.setNFTPrice)
                    DONE - MasterChef|SnowToken|SnowNFT.transferOwnership()
                        NOTE: requires losing owner control to time lock contract, during lock/transition time
                                (waiting on admin approval)
        DONE - snow nft features (no pre-sale, no whitelist)
        DONE - snow referral integration _ review: ./legacy/referral/ (overcomplicated; wrote simpler integration instead)
            DONE - refferers register w/ new function registerPromotor(address, custom_uri)
            DONE - referrer earns 0.3% of earned snow that referree earns (or maybe mint new?)
            DONE - users use referrer EOA or custom_uri when clicking 'stake' or 'zap in' from GUI
            DONE - if user uses a referrer EOA, user gets no fees on x amount of deposits (admin controls/sets x amount)
                DONE - ie. if referral address provided (Ref: function deposit(...) & function depositFor(...))
                        DONE - then, skip burn existing integration ^
                            NOTE: ZapV3.sol invokes MasterChef.depositFor()
                                    and ZapV3 is invoked from client-side
                                DONE - HENCE, just need modify MasterChef deposit functions
                NOTE: need/want global tracking for everything possible

    011125: 3hrs + 42hrs (prev) = 45hrs (total)
        WORKING - finalize design & integration of timelock / delay integration (using SnowTimelock.sol in CONF)
            - review: SnowNFT.setNFTPrice()
            - review: MasterChef.updateEmissionRate()
            - review: SnowConfig.setDevAddress()
            DONE - review: MasterChef.add|set()
                DONE - integrated new SnowTimelock.sol
            - review: "transferOwnership()" (now indeed doable w/ latest timelock model and _ownerCheck() override)
                n/a - requires losing owner control to time lock contract, during lock/transition time
        DONE - type of work agreement
        DONE - type of week 1 invoice

    011025: 8hrs + 34hrs (prev) = 42hrs (total)
        DONE - start design & integration of timelock / delay integration
            - review: SnowNFT.setNFTPrice()
            - review: MasterChef.updateEmissionRate()
            - review: SnowConfig.setDevAddress()
            DONE - review: MasterChef.add|set()
                DONE - integrated new SnowTimelock.sol
            DONE - review: "transferOwnership()"
                requires losing owner control to time lock contract, during lock/transition time
        DONE - created & integrating new SnowTimelock.sol
        DONE - call with admin about tax cool-down algorithm in SnowToken (discussed/asked in TG)
        DONE - legend: work with deploying latest front-end w/ new contracts
        DONE - deploy & test current SnowNFT.sol integration
            note: need initial base uri from admin
            DONE - analyze & finalized URI requirements
        DONE - steve & zues: discuss referral deploy and next steps 
        DONE - admin: discuss bringing steve on board

    010925: 7hrs + 27hrs (prev) = 34hrs (total)
        DONE - begin timelock integration review (TimeLock.sol)
            DONE - playing with design of TimeLockSimple.sol (but no final solutions yet)
            DONE - TimeLock.sol may not be the right design for this solution 
                    since it uses an "admin", and also it may not be suitable for 
                     functions that require ‘msg.sender’ use cases
                        ex: tansferOwnership, requires current owner to be msg.sender
                            how would this be handled if msg.sender is not correct 
                            when function signature transaction is executed 
        DONE - initial cleanup and CONF model integration for SNOWNFT.sol (globals, etc.)
                not much work needed, legacy looks complete, compiles just fine and ready for testing deploy
        DONE - review & finalize project design requirements w/o using 'presale' and 'whitelisting' (request by admin TG)
            note: SNOWNFT.sol legacy integration is only within SnowPresale.sol 
                (ie. need to de-couple and allow for independant purchase at a certain USD price, paid in native PLS)
            note: purchasing of SnowToken.sol is indeed within SnowPresale.sol as well
                however, minting is executed algorithmically from MasterChef (no additional changes needed; looks like)
            *NOTE: latest legacy repo (github.com/0xLancerLab/snow_bank_masterchef.git) removes whitelist & pre-sale
                DONE - minor fixes allowed for succesesful test compiling just fine now
        DONE - test compile SNOWNFT.sol (current issue w/ 'String' keyword + additional compilation issues)
        DONE - pyhton script & multi-chain deploy automation design updates (README.md)
        DONE - deploy for testing promotor / referral model: SnowConfig, MasterChef, SnowToken, ZapV3, SnowLib
            DONE - lib, zap, snow, chef, conf
            DONE - add to initial SNOW LP (auto-created on pulsex via SnowToken constructor)
            DONE - perform initial configs (in master chef and conf)
                DONE - add initial farm (market chef)
                DONE - set tax configs in snow conf (setPair to tax, setProxy to ignore, and cool down setting)
            DONE - provide new contract adresses and function signatures to steven and zues (TG)
        DONE - begin review MasterChef.sol -> _allocPoint & basis points integration
                looks like...
                    10,000 max for alloc points
                     1,000 max for basis points
            DONE - initial testing of MasterChef.add(...)

    010825: 10hrs + 17hrs (prev) = 27hrs (total)
        DONE - finalize referral integration in master chef and snow config
            DONE - finalize promotor calc & paying earned SNOW (from master chef )
                removed SNOW_REWARDS and FREE_DEPOSITS array, updated to simpler storage model
                ready for initial testing
            DONE - finalized storage design for promotor / referral integration
            DONE - finalize tracking & update promoter SNOW_REWARDS & user FREE_DEPOSITS (on deposits)
            DONE - integrated master chef support to check / update if free deposit is available (for promo + user combo)
        DONE - finalize snow config updates (porting legacy code)
        DONE - review steven & zues intial tasks (respond w/ next steps)

    010725: 9hrs + 8hrs (prev) = 17hrs (total)
        DONE - referral: begin integration w/ new design below (in MasterChef.sol)
                    DONE - porting legacy callit 'promotor' code
        DONE - begin integration of SnowConfig.sol & SnowLib.sol (allow for dynamic contracts / updates)
        DONE - deploy new multicall.sol (appears to be used in front-end)
                CA: 0xEF123260B4da864cB55D3c14378B09b1Fb734cd3
        DONE - call with admin regarding referral integrtion
        DONE - call with zues (UTC -2) and admin to discuss referral input integration below
        DONE - call with steven (US-WST) and admin to discuss referral input integration below
        n/a - review: ./legacy/referral/
        DONE - design referral process (UX design)             
            - use case:
                in referal page:    
                    users can optionally register as a referrer, choose a custom URN, receive a refferal link to give away
                        benefit: receive 0.3% of referree earned $SNOW (or maybe mint new $SNOW?)
                in staking|zapping:
                    users can optionally include referrer EOA or referrer custom URN  
                        benefit: pay no deposit for x amount of deposits (admin/owner can set 'x')
            - input: 
                1) 'referrer tab' -> new referrer registration page -> (add input x2: EOA and custom URN)
                             invoke write MasterChef.registerPromotor(EOA, custom_urn)
                             invoke read MasterChef.getReferralInfo(EOA)
                2) 'stake tab' -> 'stake button' -> (add input x1: EOA or custom URN)
                             invokes write MasterChef.deposit|depositFrom(...)
                3) 'stake tab' -> 'zap in button' -> (add input x1: EOA or custom URN)
                             invokes write ZapV3.zapIntoFarmWithToken|zapIntoFarmWithETH(...)
            - master chef contract will track everything

    010625: 8hrs + 0hrs (prev) = 8hrs (total)
        DONE - review design pattern for SNOWNFT.sol integration
        DONE - review & migrate latest existing SNOW smart contract code to this current repo (snowbank-dev)
            DONE - https://github.com/0xLancerLab/snow_bank_masterchef (last commit 12/11/24)
            DONE - replaced everything except the following (merged latest changes in latest code base)
                MasterChef
                SnowToken.sol
                SNOWNFT.sol
                ZapV3.sol
            DONE - test everything still compiles just fine (execpt SNOWNFT.sol which always had an issue: 'String')
        DONE - review git commit history for https://github.com/0xLancerLab/snow_bank_masterchef
            - looks like zap contracts "might" be processing fees
            - looks like a batch/multi-chain deploy-protocol.ts script has been started
            - quite a few fixes & updates since legacy Snow_Bank_MasterChef-main.zip
        DONE - referral code / eoa integration discussion with admin
        DONE - review legacy git repos from LEGEND x3
            DONE - https://github.com/0xLancerLab/snow_bank_masterchef (last commit 12/11/24)
            DONE - https://github.com/devlegend524/SNOW_Bank (last commit 11/01/23)
            n/a  - https://github.com/0xLancerLab/snow_bank_frontend (last commit 12/10/24)
        
## work log | week #0 | start: 010125 | hours: 24hrs | total hours: 24hrs
    010525: 1hrs (now) + 23hrs (prev) = 24hrs (total)
        DONE - front-end: get 'SNOW_Bank-eth-testnet' running locally 
        DONE - analyze .sol files needed to deploy for client side: multicall.sol, SNOWNFT.sol
            note: snowWplslp address also needed for client side (generate on pulxev2)

    010525: 1hrs (now) + 22hrs (prev) = 23hrs (total)
        DONE - continued analysis of addresses.js
            NEXT:
                - update addresses.js w/ pulsechain contracts & test to see what displays 
                    deploy GUI & check what features available and display logic
                    NOTE: some addresses won’t be available to fill (pay attention to these)
            
    010525: 1hrs (now) + 21hrs (prev) = 22hrs (total)
        DONE - analysis of 'SNOW_Bank-eth-testnet' front-end react code
            - ABIs  -> globals path: .../SNOW_Bank-eth-testnet/src/config/abis
            - ADDRs -> globalS path: .../SNOW_Bank-eth-testnet/src/constants/addresses.js
        DONE - organized README notes and references

    010525: 4hrs + 17hrs (prev) = 21hrs (total)
        DONE - get SNOW_Bank-eth-testnet/ deployed to versel successfully
            - https://snowbank-dev-eth-testnet.vercel.app/
        DONE - get SNOW_Bank-eth-testnet/ deployed locally 
            - analize for blockchain integration (yes found)
            - veriify can work with and start testing locally (yes all good)
        DONE - local run attempt of front-end potential: .../public/snowbase-base/
            - failed
        DONE - local run attempt of front-end potential: .../public/snow/
            - failed
        DONE - local run attempt of front-end potential: .../public/SNOW_Bank-eth-testnet/
            - successful
        DONE - in-depth analysis of front-end potential: .../public/SNOW_Bank-eth-testnet/
        DONE - in-depth analysis of front-end potential: .../public/snow/
        DONE - attempting to deploy more front-end snow potentials (.zip files from admin)

    010425: 2hr + 15hrs (prev) = 17hrs (total)
        DONE - deploy attempt w/ wildebase.farm front-end integration
        DONE - retreive legacy snow source code 
            maybe in snowbank.io/ folder from admin harddrive during screen share session ~01/02/25
        DONE - deploy and test legacy snow source on versel.com
            failed - sno
            failed - snow
            old - snowbank-base
            old - wildebase.farm
    
    010425: 4hrs + 11hrs (prev) = 15hrs (total)
        DONE - debugging and testing of intial deploys (v0.3, etc. call with admin)
        DONE - start BILL design doc review: https://mystery-dao.gitbook.io/bill-token/bill-tokenomics
        DONE - review and confirm ...
            Week #1 scrum tasks
            - deploy snow on avalanche and pulsechain
                - master chef defi features (current gui)
                    - review/remove 'setSnowX'
                    - timelock integration (ie. delay global updates for taking effect for x amount of hrs)
                        - add()
                        - set()
                        - setAmountPerNFT()
                        - setDevAddress()
                        - transferOwnership()
                        - updateEmissionRate()
                - snow nft features (no pre-sale, no whitelist)
                - snow referral integration
                    - referrer earns 3% of earned snow that referral earns
            - create python script for easy deployment on additional EVM chains
                - w/ how-to guide

    010325: 6hrs + 5hrs (prev) = 11hrs (total)
        DONE - added deploy fixes & updates for MasterChef & SnowToken
        DONE - design & analysis of de-coupling snow token & NFT from SnowPresale
                note: need more info on snow token distribution from admin TG
                update: minting is executed algorithmically from MasterChef
        DONE - review and port python utility scripts
        DONE - EXECUTION MODEL (snow token -> ref: wildbase.pdf template)
            DONE - 1) deploy ZapV3.sol (Snow_Bank_MasterChef-main)
            DONE - 2) deploy SnowToken.sol (Snow_Bank_MasterChef-main) _ note: SnowPresale.sol n/a
                    note: mints 1,000,000 SNOW to static treasury EOA
            DONE - 3) deploy MasterChef.sol (Snow_Bank_MasterChef-main) _ w/ snow & zap addies
            admin - 4) manually create LPs needed using treasury EOA    
            admin - 4) configure MasterChef.sol (add farms) _ onlyOwner
                    note: use admin designated LP addresses, alloc points, and fee requirements -> function add(...)
                    note: may want to add initialization of farms in constructor (if possible; legacy code does NOT do this)
            admin - 5) configure SnowToken.sol (tax settings: tax rates & pair addies) _ onlyOwner
                    note: legacy code looks like LP deployments integrated inside constructor (commented out)
            
            LEGACY EXECUTION MODEL (legacy wildbase.pdf)
                1) deploy LODGE.sol (NDA-LOL)
                2) deploy MasterChef.sol (NDA-LOL)
                3) configure MasterChef.sol (add farms)
                4) deploy Oracle.sol (NDA-LOL)
                5) deploy TaxOfficeV5.sol (NDA-LOL)
                6) deploy ZapV2.sol (NDA-LOL)
                7) configure LODGE.sol
                8) integrate wildebase.farm front-end

    010325: 2hrs + 3hrs (prev) = 5hrs (total)
        DONE - intial debug and compiling of MasterChef and SnowToken .sol source fiels

    010225: 1hrs + 2hrs (prev) = 3hrs (total)
        DONE - organize solidity file questions for admin (via TG)
        DONE - review LODGE.sol (NDA-LOL) -> N/A _ replace w/ SnowToken.sol
        DONE - review Oracle.sol (NDA-LOL) -> N/A for snow token
        DONE - review TaxOfficeV5.sol (NDA-LOL) -> N/A for snow token
        DONE - review ZapV2.sol (NDA-LOL) -> n/a for snow token, should use V3 and Zapbase instead
        DONE - review MasterChef.sol
        DONE - review ZapV3.sol
        DONE - review ZapBase.sol

    010225: _ 2hrs + 0hrs (prev) = 2hrs (total)
        DONE - organize solidity file questions for admin (via TG)
        DONE - review & organize wildbase.pdf
        DONE - review https://snowbank.gitbook.io/snow-bank/protocol-info/tokenomics
        DONE - review current tax integration in SnowToken.sol 'tranfer' functions
        DONE - init review curent SnowPresale.sol integration
        DONE - init review curent SNOWNFT.sol integration

# ------------------------------------------------ #
## TODO: (TG: house 010125)
    good meeting you admin!
    just to follow up...

    i am taking this as an opportunity to simply prove my value and skills sets (ie. if you have the funding and you can get the users... then i can definitely handle the code👍️️)

    i am going to attempt to re-deploy your model on pulsechain using
    1) NDA-LOL.zip
    2) Snow_Bank_MasterChef-main.zip

    timeline... should be 2 to 5 days (i'll give you an update by friday)

    testing can then be done using smartcontractgui.xyz (i will provide the ABIs and addresses needed, etc.)

    after testing and verifying that things were re-deployed successfully, i can then walk you through the python scripts so you can replicate these actions on your own 👍️️

    if all goes well.. i would be more than happy to continue discussing your deployment plans and business model requirements moving forward.

    thanks for the opportunity, let me know if you have any questions!

# ------------------------------------------------ #
## NEXT: (TG admin 010125)
    If you're any good with creating tokens with good tax logic, I need a token called Bill Cipher ticker $BiLL with 1 Billion initial and maximum supply.

    Buy Tax: 0.3% - Auto-Burns
    Sales Tax: 6% - 4% Auto-Burns, 2% goes to the Treasury

    Although, in order for $BiLL to be bridgeable it needs to be mintable, so unfortunately minting must be enabled but a hard cap can be set at 1 Billion..

    Other than what may be necessary for $BiLL to be bridgeable (besides Mint functionality),
# ------------------------------------------------ #
# ------------------------------------------------ #

