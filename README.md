# snowbank

## system deploy algorithm (w/ SnowConfig.sol)
    NOTE: deployment algorithm (consolidated)
        - deploy contracts
        - preformed initial configs
            - conf.KEEPER_setContracts
            - pulsexV2: create snowLP (SNOW:WPLS, 100k:100k) -> auto-configs in SNOW constructor
            - snow.setPair(snowLP) -> auto-configs in SNOW constructor
            - snow.setProxy(pulsexV2) -> auto-configs in SNOW constructor
            - snow.setProxy(zap)
            - chef.add(...) for initial snowLP created
            - zap.setCoreValues
            - zap.setTokenTypes
    NOTE: deployment algorithm (detailed)
        - deploy SnowConfig (or deploy last w/ all other addies as constants)
        - deploy all other contracts (log addies created)
            NOTE: SnowToken.sol contructor ...
                    1) auto-generates first SNOW LP on PulseX (empty)
                    2) auto-configs this pair & router (setPair & setProxy)
                    3) auto-configs initial tax settings (tax rate and cool down)
        - Required: manually invoke CONF.KEEPER_setContracts (w/ input: addies created)
            NOTE: auto-invokes CONF_setConfig on all other contracts (triggers FIRST_ onlyConfig)
        - Manually: set tax proxy -> 
            ref: .../snow_bank_masterchef_scripts/deploy-protocol.ts
                > SnowToken.setProxy(ZapV3)
        - Manually: add more inital LPs (BILL LP, snow tok address, snow nft address)
            ref: .../snow_bank_masterchef/scripts/deploy-protocol.ts
                > MasterChef.add(700, snowLp, 100, false, false); _ **REQUIRED**: add first SNOW LP to pool
                > MasterChef.add(100, billLp, 100, false, false);
                > MasterChef.add(100, token.address, 300, false, false);
                > MasterChef.add(50, nftContract.address, 0, false, true);
                    LEFT OFF HERE ... should automate this with python
        - Manually: set zap configs
            ref: .../snow_bank_masterchef/scripts/deploy-protocol.ts (TokenType: 0,1,2 = INVALID,ERC20,LP)
                > ZapV3.setCoreValues(v2_rout, v2_fact, chef_addr, snow_addr, snowLP, wpls) _ sets tokenType[snowLP] = 2
                > ZapV3.setTokensType([dai, usdc, bill], 1); 1 = TokenType ERC20
                > ZapV3.setTokensType([billLP], 2);          2 = TokenType LP
            NOTE: not in .../snow_bank_masterchef/scripts/deploy-protocol.ts
                > ZapV3.setSwapPath
                    but zap global 'swapPath' required for ...
                        external swapTokensForTokens
                        external swapTokensForETH 
                        external swapETHForTokens
                    however, down stack support functions checks for empty 'swapPath' global
                        and handles it accordingly (phew _ QQ)
        - Manually: add initial liquidity to init-LPs created (requires pair addy created)
            LEFT OFF HERE ... should automate this in SnowToken constructor w/ msg.value passed in
        - Optional: manually add/sub/manage MasterChef farms _ function add|set(farms...)
        - Optional: manualy update SnowConfig tax settings _ (tax rates, cool down, pair, proxy)

    NOTE: contract update algorithm
        - deploy contract (log addy created)
        - invoke CONF.KEEPER_setContracts (w/ input: addy created & 0x0 opt-out)
            - invokes CONF_setConfig on updates contracts (triggers FIRST_ onlyConfig)

    NOTE: contract update algorithm (CONFIG)
        - deploy CONF contract (w/ globals: addies from all contracts)
        - invoke CONF.KEEPER_setContracts (w/ input: addy created & 0x0 opt-out)
            - invokes CONF_setConfig on all contracts (triggers FIRST_ onlyConfig)

## SNOW bridge design
    - front-end workflow
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

    - finalize code base design model (python & solidity)
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

            ## *dead design* -> n/a
            # insert db: id, dt_created|updated, struct BRIDGE_OUT
            # if insert succeeds:
            #   invoke: SNOW.bridge_in(struct BRIDGE_OUT) _ *cost GAS*
            # else:
            #   this txHash has already been bridged (ignore/log)
            # NOTE: need to maintain db
            #   delete old BRIDGE_OUT.blocknumber entries weekly

        solidity SNOW.sol:
            struct BRIDGE_OUT {
                EOA (msg.sender)
                from|to_chain
                from|to_chainID
                from|to_chain_rpc
                snowAmnt -> not 0
                blocknumber
                txHash -> filled in python
                claimed -> set true in bridge_claim
            }
            address treasAddr;
            uint16 REQ_BLOCK_CNT_CLAIM = 90; // pulsex requires ~90
            uint16 PERC_CLAIM_FEE = 300; // 300 = 3.00%
            mapping(address => BRIDGE_OUT[]) public EOA_BRIDGE_OUTS;
            mapping(address => BRIDGE_OUT[]) public EOA_BRIDGE_INS;
            mapping(address => BRIDGE_OUT) public TXHASH_BRIDGE;
            address[] public BRIDGE_EOAS; // ... do we want/need this?
            function bridge_out(snowAmnt)
                // generate struct BRIDGE_OUT (w/o txHash)
                // append BRIDGE_OUT to EOA_BRIDGE_OUTS[msg.sender][]
                // burn(snowAmnt)
                // emit BridgeOutEvent(struct BRIDGE_OUT)
            def handle_BridgeOutEvent(struct BRIDGE_OUT): # listen loop
                # 1) get txHash for this BridgeOutEvent 
                # 2) invoke: SNOW.TXHASH_BRIDGE(txHash) _ checks if txHash exists
                #       if yes: skip/'continue' to next handle_BridgeOutEvent 
                #        (ie. SNOW contract is updated past that txHash)
                # 3) add txHash to struct BRIDGE_OUT
                # 4) get to_chain from BRIDGE_OUT
                # 5) invoke on to_chain: SNOW.bridge_in(struct BRIDGE_OUT) _ *GAS*
                #       reverts if BRIDGE_OUT.txHash already exists
            function bridge_in(struct BRIDGE_OUT)
                // check if TXHASH_BRIDGE[BRIDGE_OUT.txHash] exists (if yes: revert/fail)
                // map TXHASH_BRIDGE[BRIDGE_OUT.txHash] = BRIDGE_OUT
                // append BRIDGE_OUT to EOA_BRIDGE_INS[msg.sender][]
                //  if new bridger, also append msg.sender to BRIDGE_EOAS[] ... do we want/need this?
            function bridge_claim(uint32 _idx, bool _all) 
                // if _all: 
                //  for all 'i' in EOA_BRIDGE_INS[msg.sender][],
                //      validate: block.number > EOA_BRIDGE_INS[msg.sender][i].blocknumber + REQ_BLOCK_CNT_CLAIM
                //      validate: [i].claimed == false
                //      calc bridge_fee: PERC_CLAIM_FEE * [i].snowAmnt
                //      send net_amnt to [i].EOA: [i].snowAmnt - bridge_fee 
                //      send bridge_fee to treasAddr
                //      set [i].claimed == true
                //       -OR- delete EOA_BRIDGE_INS[msg.sender][i]
                // else: 
                //  validate: block.number > EOA_BRIDGE_INS[msg.sender][_idx].blocknumber + REQ_BLOCK_CNT_CLAIM
                //  validate: [_idx].claimed == false
                //  calc bridge_fee: PERC_CLAIM_FEE * [_idx].snowAmnt
                //  send net_amnt to [_idx].EOA: [_idx].snowAmnt - bridge_fee 
                //  send bridge_fee to treasAddr
                //  set [_idx].claimed == true
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

## SNOW back-end notes
    - Zap-in fuctionality (TG: leged 011625)
        Let's say, If you want stake on snowLP pool using zap in, then target token will be LP
        and if you want to stake on SNOW pool using zap in, then target token will be snow
    - NFT: example server image path: https://snowbank.io/images/nfts/01.png
            baseURI: https://snowbank.io/images/nfts/
            tokenID: 01
            baseExtension: .png
    - MasterChef.sol -> add|set(...) params?
        - param: _allocPoint, required?: <10,000, ref: set(...)
        - param: _depositFeeBP, required?: <1,000, ref: set|add(...>
    - MultipleOperator.sol (010925)
		NOTE: had to enabled onlyOwner in constructor
			and owner is only used in one function: setOperatorStatus
			all the rest use the ‘onlyOperator’ modifier 
				(this is a bug? should Ownable be used here?
    - functional design: referral model
        - snow referral integration _ review: ./legacy/referral/
            - refferers register w/ new function registerRefferer(address, custom_uri)
            - referrer earns 0.3% of earned snow that referree earns (or maybe mint new?)
            - users use referrer EOA or custom_uri when clicking 'stake' or 'zap in' from GUI
            - if user uses a referrer EOA, user gets no fees on x amount of deposits (admin controls/sets x amount)
                ie. if referral address provided (Ref: function deposit(...) & function depositFor(...))
                        then, skip burn existing integration ^
                            NOTE: ZapV3.sol invokes MasterChef.depositFor()
                                    and ZapV3 is invoked from client-side
                                HENCE, just need modify MasterChef deposit functions
                NOTE: need/want global tracking for everything possible
    - 010625: received & merged w/ latest dev source: github.com/0xLancerLab/snow_bank_masterchef
        - looks like zap contracts "might" be processing fees
        - looks like a batch/multi-chain deploy-protocol.ts script has been started
        - quite a few fixes & updates since legacy Snow_Bank_MasterChef-main.zip
    - using legacy project: Snow_Bank_MasterChef-main.zip
    - primary source code files copied (dependencies):
        interfaces/*
        pancakeSwap/*
    - primary source code files forked (requirements):
        MasterChef.sol
        SnowToken.sol
        SNOWNFT.sol
        ZapV3.sol
        ZapBase.sol
        TimeLock.sol
        PrizeConverter.sol
        Multicall.sol

## SNOW front-end notes
    - bridge (front-end workflow)
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

    - referral / promotor API
        register a PROMO
            MasterChef.registerPromotor(address _promotor, string calldata _customURN)
                - both params required & reverts if _promotor OR _customURN already exists
        get PROMO info by promotor EOA or custom URN
            SnowConfig.PROMOTOR_PROMO(address _promotor)
            SnowConfig.URN_PROMO(string _customURN)
            returns ...
                struct PROMO { // NOTE: 1 promo per promotor EOA (created in MasterChef.registerPromotor)
                    address promotor; // influencer wallet this promo is for
                    string customURN; // custom promo code for snowbank.io custom referral url (eg. "snowbank.io/SNOW123")
                    uint16 percReward; // 100.00% = 10000; % of user $SNOW earnings rewarded (dynamic control by admin)
                    uint8 numFreeDepPerUsr; // number of free deposits this promo is good for per user
                    address creator; // address who created this promo
                    uint256 blockTimestamp; // sec timestamp this promo was created
                    uint256 blockNumber;} // block number this promo was created
        get FREE_DEPOSIT info of a PROMO user
            SnowConfig.USER_FREE_DEP(address _user)
            returns ...
                struct FREE_DEPOSIT { // NOTE: 1 free deposits per user
                    address user; // EOA who used a promo on deposit
                    address promotor; // promo / influencer wallet that was used
                    uint256 snowDeposited; // cumulative amount of $SNOW deposited by user (if possible)
                    uint8 freeDepositCnt; // # of free deposits this user has used (default 0, increment to PROMO.numFreeDepPerUsr)
                    uint256 blockTimestamp; // sec timestamp this promo was used
                    uint256 blockNumber;} // block number this promo was created
        use a PROMO
            ZapV3.zapIntoFarmWithToken|zapIntoFarmWithETH(..., address _promotor, _string calldata _customURN)
            MasterChef.deposit|depositFrom(..., address _promotor, _string calldata _customURN)
            *NOTE: these additional param are NOT required (may pass address 0x0 and empty string to opt-out)
                    however, if they are used, then address _promotor is prioritized

    - UX design - referral model
        - referral process (UX design)             
            - use case:
                in referal page:    
                    users can optionally register as a referrer, choose a custom URN, receive a refferal link to give away
                        benefit: receive 0.3% of referree earned $SNOW (or maybe mint new $SNOW?)
                in staking|zapping:
                    users can optionally include referrer EOA or referrer custom URN  
                        benefit: pay no deposit for x amount of deposits (admin/owner can set 'x')
            - input: 
                1) 'referrer tab' -> new referrer registration page -> (add input x2: EOA and custom URN)
                             invoke write MasterChef.registerReferralEOA(EOA, custom_urn)
                             invoke read MasterChef.getReferralInfo(EOA)
                2) 'stake tab' -> 'stake button' -> (add input x1: EOA or custom URN)
                             invokes write MasterChef.deposit|depositFrom(...)
                3) 'stake tab' -> 'zap in button' -> (add input x1: EOA or custom URN)
                             invokes write ZapV3.zapIntoFarmWithToken|zapIntoFarmWithETH(...)
            - master chef contract will track everything
    - using legacy project: SNOW_Bank-eth-testnet.zip
    - config source code:
        - const  -> globals path: SNOW_Bank-eth-testnet/src/config/farms|tokens.js (w/ BILL)
        - config -> globals path: SNOW_Bank-eth-testnet/src/config/index.js (defi)
        - ABIs   -> globals path: SNOW_Bank-eth-testnet/src/config/abis
        - ADDRs  -> globalS path: SNOW_Bank-eth-testnet/src/constants/addresses.js
    - using node -> react.js (npm)
        DEPLOY cmd ref:
            #========================================================#
            # SNOW_Bank-eth-testnet
            #========================================================#
            $ npm install next react react-dom
            $ npm start

            #========================================================#
            # next
            #========================================================#
            $ nvm install 18
            $ node -v
            $ npm install next react react-dom
            $ npm install next@13 react react-dom
            $ npm install next@latest
            $ npm rebuild
            $ npm run dev
            $ next start

            #========================================================#
            # npm
            #========================================================#
            $ npm install
            $ npm start

## references:
    - test wallets
        admin: 0xFB62bF66dDa68857c67859Aa1F36E844cDF879b6
        steven: 0xcaEC86D0D56a828Dc44f1d308Bf2200518d16c78
        0xIntelTech: 0xEEd80539c314db19360188A66CccAf9caC887b22
    - snowbank.io
        https://snowbank.io
        https://snowbank.io/nfts
        https://snowbank.io/swap
        https://snowbank.io/roadmap
    - Pulse chain smart contracts deployment (https://scan.pulsechainfoundation.org/)
        router: "0x165C3410fC91EF562C50559f7d2289fEbed552d9",
        factory: "0x29ea7545def87022badc76323f373ea1e707c523",
        dai: "0xefD766cCb38EaF1dfd701853BFCe31359239F305",
        wpls: "0xa1077a294dde1b09bb078844df40758a5d0f9a27",
        usdc: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        usdcLp: "0x8F6DfB2Fa2f7Ccf9d7106E96207d8B947a89998a",

        snow: "0xdc318Ea55e15Fd480a7c9baEc6d957Cf602b5063",
        bill: "0xc0F1BA2780bBb41363d94859D8EBC26809dcC010",
        snowWplslp: "0xB564f77D0E4F295f4b0E8528c15b7fb432aB1D34",
        billWplslp: "0x1C2f109e263DF5575751A83e071Cd55C7f4Ac096",
        nft: "0xb9520710e38b8D83554962D2e4Fc0D311653D176",
        zap: "0x983389Eee6Bb76419b0176d64E1dB8191213A0B5",
        masterChef: "0x520E7c83B0859FC6915AcC75A7b4d4FD256F97FA",
        stake: "0x50c59f6ac05ed909750f8ab3d6539492b36fe4bc",
        stakeToken: "0x6C99174867C1f41a2DfE0b196A667e6130Cf3C61",
        lib: "0x1c815565415116081Bc5b5DF359F41bdF866735e",
        config: "0xD0B984883A640FeEC527014B7364C0d94061e006",
        snowConfig: "0x790C736Fd431420086a2b4C9505BADAf0676B8B9",
    - BASE chain MasterChef.sol deployment (0xB51020eB045FA03595cF0377092b39bC7EB7B608)
        https://basescan.org/address/0xB51020eB045FA03595cF0377092b39bC7EB7B608#readContract
    - Snowbank admin panel from previous dev (no soure code available yet)
        https://admin.snowbank.io/bill