// import fs from 'fs'
import { getEnvValSafe } from './utils'
import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-foundry'
import '@nomicfoundation/hardhat-network-helpers'
import '@nomiclabs/hardhat-solhint'
import '@nomicfoundation/hardhat-toolbox'
import 'dotenv/config'

import './tasks/verify'
import './tasks/automatedClaim'
import './tasks/season'

const AVALANCHE_RPC_URL = getEnvValSafe('AVALANCHE_RPC_URL')
const FUJI_RPC_URL = getEnvValSafe('FUJI_RPC_URL')

const DEPLOYER_PRIVATE_KEY = getEnvValSafe('PRIVATE_KEY')

const COINMARKETCAP_API_KEY = getEnvValSafe('COINMARKETCAP_API_KEY')
const SNOWTRACE_API_KEY = getEnvValSafe('SNOWTRACE_API_KEY', false)

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: SNOWTRACE_API_KEY,
  },
  networks: {
    avalanche: {
      accounts: [DEPLOYER_PRIVATE_KEY],
      chainId: 43114,
      url: AVALANCHE_RPC_URL,
    },
    fuji: {
      accounts: [DEPLOYER_PRIVATE_KEY],
      chainId: 43113,
      url: FUJI_RPC_URL,
      gas: 8000000,
      timeout: 10000000,
    },
    hardhat: {
      forking: {
        blockNumber: 21540815,
        url: AVALANCHE_RPC_URL,
      },
    },
  },
  solidity: {
    version: '0.8.18',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
    },
  },
}

export default config
