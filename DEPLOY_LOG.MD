# DELOY LOG ...

## system deploy algorithm (w/ SnowConfig.sol)
    NOTE: deployment algorithm
        - deploy SnowConfig (or deploy last w/ all other addies as constants)
        - deploy all other contracts (log addies created)
            NOTE: SnowToken.sol contructor ...
                    1) auto-generates first SNOW LP on PulseX (empty)
                    2) auto-configs this pair & router (setPair & setProxy)
                    3) auto-configs initial tax settings (tax rate and cool down)
        - Required: manually invoke CONF.KEEPER_setContracts (w/ input: addies created)
            NOTE: auto-invokes CONF_setConfig on all other contracts (triggers FIRST_ onlyConfig)
        - Manually: Set MasterChef intial LP _ function add(farms..., first SNOW LP)
            LEFT OFF HERE ... should automate this with python
        - Manually: add initial liquidity to LP auto-created LP (requires pair addy created)
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

## DELOY LOG ...
    # weUSDC: 0x15D38573d2feeb82e7ad5187aB8c1D52810B1f07
    # weDAI: 0xefD766cCb38EaF1dfd701853BFCe31359239F305
    # WPLS: 0xA1077a294dDE1B09bB078844df40758a5D0f9a27
    # BURN: 0x0000000000000000000000000000000000000000
    # addr array: ["0xefD766cCb38EaF1dfd701853BFCe31359239F305", "0x15D38573d2feeb82e7ad5187aB8c1D52810B1f07"]

    #---------------------------------------------------------------------------------------------------#
    011525: (latest deploys)
    SNOW:WPLS (100K:100K): 0xB564f77D0E4F295f4b0E8528c15b7fb432aB1D34

    SnowConf_v0.4: 0x790C736Fd431420086a2b4C9505BADAf0676B8B9
    MasterChef_v0.5: 0x520E7c83B0859FC6915AcC75A7b4d4FD256F97FA
    ZapV3_v0.4: 0x983389Eee6Bb76419b0176d64E1dB8191213A0B5
    SnowToken_v0.5: 0xdc318Ea55e15Fd480a7c9baEc6d957Cf602b5063
    SnowNFT_v0.4: 0xb9520710e38b8D83554962D2e4Fc0D311653D176
    SnowTimelock_v0.1: 0x97350f425ABa6554fb1bF879D98830C13A7A9819
    SnowLib_v0.2: 0x3e833F280b223CDaBDb52a16d8cf45A83B757d77
    Multicall_v0.0 (client side): 0xEF123260B4da864cB55D3c14378B09b1Fb734cd3

    ADDR_TREAS_EOA = 0xF5F3b513b77182D83010dbe49C90EBDfF60e9964 // admin_010325
    ADDR_DEV_EOA = 0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7 // admin_010325
    ADDR_FEE_EOA = 0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40 // admin_010325
    Testing^^^ ... 0xEEd80539c314db19360188A66CccAf9caC887b22 // testing all   

    #---------------------------------------------------------------------------------------------------#
    011425:
    SNOW:WPLS (100K:100K): 0xB564f77D0E4F295f4b0E8528c15b7fb432aB1D34

    SnowConf_v0.4: 0x790C736Fd431420086a2b4C9505BADAf0676B8B9
    MasterChef_v0.5: 0x520E7c83B0859FC6915AcC75A7b4d4FD256F97FA
    ZapV3_v0.4: 0x983389Eee6Bb76419b0176d64E1dB8191213A0B5
    SnowToken_v0.5: 0xdc318Ea55e15Fd480a7c9baEc6d957Cf602b5063
    SnowNFT_v0.2: 0x2160B8BeeE78b71B5995245CCCd36b8D9E57ED56
    SnowTimelock_v0.1: 0x97350f425ABa6554fb1bF879D98830C13A7A9819
    SnowLib_v0.2: 0x3e833F280b223CDaBDb52a16d8cf45A83B757d77
    Multicall_v0.0 (client side): 0xEF123260B4da864cB55D3c14378B09b1Fb734cd3

    
    ADDR_TREAS_EOA = 0xF5F3b513b77182D83010dbe49C90EBDfF60e9964 // admin_010325
    ADDR_DEV_EOA = 0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7 // admin_010325
    ADDR_FEE_EOA = 0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40 // admin_010325
    Testing^^^ ... 0xEEd80539c314db19360188A66CccAf9caC887b22 // testing all

    #---------------------------------------------------------------------------------------------------#
    011425:
    ADDR_CONF = (0xD0B984883A640FeEC527014B7364C0d94061e006) // SnowConfig v0.3
    ADDR_CHEF = (0x8B37B95E48D7e420174Df1b90e0Ff1119f2576a3) // MasterChef v0.4
    ADDR_SNOW = (0xe02B38C2649B68e798E135EF885bc40dbB1173fA) // SnowToken v0.4
    ADDR_INIT_PAIR = (0xF261b520C7d770D0D6d1AF0f1486A9b21A0d870a) // SnowToken v0.4 _ SNOW:WPLS (100K:100K)
    ADDR_SNFT = (0x6087D80F623281bE699cDc369f2F766aF7D3f548) // SnowNFT.sol v0.1
    ADDR_ZAP = (0xE45a35baFE5c9A7db0CD2aCb2f4a867520b561B8) // ZapV3 v0.2.1 _ NOTE: no CONF integration
    ADDR_LIB = (0x1c815565415116081Bc5b5DF359F41bdF866735e) // SnowLib v0.1
    ADDR_MULTI = (0xEF123260B4da864cB55D3c14378B09b1Fb734cd3) // Multicall v0.0 _ client side (010725)

    ADDR_TREAS_EOA = 0xF5F3b513b77182D83010dbe49C90EBDfF60e9964 // admin_010325
    ADDR_DEV_EOA = 0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7 // admin_010325
    ADDR_FEE_EOA = 0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40 // admin_010325
    Testing^^^ ... 0xEEd80539c314db19360188A66CccAf9caC887b22 // testing all

    #---------------------------------------------------------------------------------------------------#
    011025:
    ADDR_CONF = (0xD0B984883A640FeEC527014B7364C0d94061e006) // SnowConfig v0.3
    ADDR_CHEF = (0x8B37B95E48D7e420174Df1b90e0Ff1119f2576a3) // MasterChef v0.4
    ADDR_SNOW = (0xe02B38C2649B68e798E135EF885bc40dbB1173fA) // SnowToken v0.4
    ADDR_INIT_PAIR = (0xF261b520C7d770D0D6d1AF0f1486A9b21A0d870a) // SnowToken v0.4 _ SNOW:WPLS (100K:100K)
    ADDR_SNFT = (0x6087D80F623281bE699cDc369f2F766aF7D3f548) // SnowNFT.sol v0.1
    ADDR_ZAP = (0x3FfFAFC7B08e345C6A6A35FBfE6a79C7df320CB7) // ZapV3 v0.2
    ADDR_LIB = (0x1c815565415116081Bc5b5DF359F41bdF866735e) // SnowLib v0.1
    ADDR_MULTI = (0xEF123260B4da864cB55D3c14378B09b1Fb734cd3) // Multicall v0.0 _ client side (010725)

    ADDR_TREAS_EOA = 0xF5F3b513b77182D83010dbe49C90EBDfF60e9964 // admin_010325
    ADDR_DEV_EOA = 0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7 // admin_010325
    ADDR_FEE_EOA = 0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40 // admin_010325
    Testing^^^ ... 0xEEd80539c314db19360188A66CccAf9caC887b22 // testing all

    #---------------------------------------------------------------------------------------------------#
    010925:
    ADDR_CONF = (0x2172a571a3b06aa72D04Cc4f14Fee61233B4A1d2) // SnowConfig v0.2
    ADDR_CHEF = (0x8B37B95E48D7e420174Df1b90e0Ff1119f2576a3) // MasterChef v0.4
    ADDR_SNOW = (0xe02B38C2649B68e798E135EF885bc40dbB1173fA) // SnowToken v0.4
    ADDR_INIT_PAIR = (0xF261b520C7d770D0D6d1AF0f1486A9b21A0d870a) // SnowToken v0.4 _ SNOW:WPLS (100K:100K)
    ADDR_SNFT = () // SnowNFT.sol v0.0
    ADDR_ZAP = (0x3FfFAFC7B08e345C6A6A35FBfE6a79C7df320CB7) // ZapV3 v0.2
    ADDR_LIB = (0x1c815565415116081Bc5b5DF359F41bdF866735e) // SnowLib v0.1
    ADDR_MULTI = (0xEF123260B4da864cB55D3c14378B09b1Fb734cd3) // Multicall v0.0 _ client side (010725)

    ADDR_TREAS_EOA = 0xF5F3b513b77182D83010dbe49C90EBDfF60e9964 // admin_010325
    ADDR_DEV_EOA = 0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7 // admin_010325
    ADDR_FEE_EOA = 0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40 // admin_010325
    Testing^^^ ... 0xEEd80539c314db19360188A66CccAf9caC887b22 // testing all

    #---------------------------------------------------------------------------------------------------#
    010425:
    ADDR_CHEF = 0xfAB898AB6caBc9f3f125E036184e54107Cf75Fd3 // MasterChef v0.3
    ADDR_SNOW = 0xa1fdB2c7AB704b0fa4ae6AF96e3D9fA730f544f3 // SnowToken v0.3
    ADDR_ZAP = 0xC2db979E8c9546b53deE21109B0bCf855ef7b716 // ZapV3 v0.1
    ADDR_MULTI = 0xEF123260B4da864cB55D3c14378B09b1Fb734cd3 // Multicall v0.0 _ client side (010725)

    ADDR_CHEF = 0x083a183eb93cf4fc6d62b5BB19eEd0dAf873995d // MasterChef v0.2
    ADDR_SNOW = 0x2938eF24948f1B6733273725fcb7e789D412771a // SnowToken v0.2
    ADDR_ZAP = 0xC2db979E8c9546b53deE21109B0bCf855ef7b716 // ZapV3 v0.1
    
    ADDR_TREAS_EOA = 0xF5F3b513b77182D83010dbe49C90EBDfF60e9964 // admin_010325
    ADDR_DEV_EOA = 0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7 // admin_010325
    ADDR_FEE_EOA = 0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40 // admin_010325

    #---------------------------------------------------------------------------------------------------#
    010325:
    ADDR_CHEF = 0x35f3Bca1385149b76A644B84187dBB45fff56970 // MasterChef v0.1
    ADDR_SNOW = 0x2d67806d64b5A89Da8595fdc20C2D5e5e574feF3 // SnowToken v0.1
    ADDR_ZAP = 0xC2db979E8c9546b53deE21109B0bCf855ef7b716 // ZapV3 v0.1

    ADDR_TREAS_EOA = 0xF5F3b513b77182D83010dbe49C90EBDfF60e9964 // admin_010325
    ADDR_DEV_EOA = 0x9c43B089B2cc3a378497EAEd4E09A42889Bf98a7 // admin_010325
    ADDR_FEE_EOA = 0x4A797bbe31f827Bb27ce9aa68Bde0a6EB915ef40 // admin_010325

    #---------------------------------------------------------------------------------------------------#
    #---------------------------------------------------------------------------------------------------#