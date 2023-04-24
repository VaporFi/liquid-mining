import fs from 'fs/promises'

async function getContractDeployment(
  contractName: string,
  networkName: string
) {
  const Contract = await import('../deployments/' + contractName + '.json')

  return {
    address: Contract[networkName].address,
    args: Contract[networkName].options.args,
  }
}

export default getContractDeployment
