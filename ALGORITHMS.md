# ALGORITHMS

## system deploy algorithm (w/ SnowConfig.sol)
    NOTE: new deployment algorithm
        - deploy CONFIG
        - deploy all contracts (log addies created)
        - invoke CONF.KEEPER_setContracts (w/ input: addies created)
            - invokes CONF_setConfig on all contracts

    NOTE: contract update algorithm
        - deploy contract (log addy created)
        - invoke CONF.KEEPER_setContracts (w/ input: addy created & 0x0 opt-out)
            - invokes CONF_setConfig on updates contracts

    NOTE: contract update algorithm (CONFIG)
        - deploy CONF contract (w/ globals: addies from all contracts)
        - invoke CONF.KEEPER_setContracts (w/ input: addy created & 0x0 opt-out)
            - invokes CONF_setConfig on all contracts

## .sol file contract external functions
    - MasterChef.sol
        

