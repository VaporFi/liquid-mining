import * as fs from 'fs'
import { ethers, network, artifacts } from 'hardhat'
import { Artifact } from 'hardhat/types'
import { generateFullABI } from './generateFullAbi'
import { saveDeployment } from './saveDeployment'

export type DeployOptions = {
  args: any[]
  log?: boolean
  skipIfAlreadyDeployed?: boolean
}

const defaultDeployOptions: DeployOptions = {
  args: [],
  log: true,
  skipIfAlreadyDeployed: true,
}

export async function deployContract(
  contractName: string,
  options: DeployOptions = defaultDeployOptions
) {
  const artifact = await artifacts.readArtifact(contractName)

  if (network.name !== 'hardhat' && options.skipIfAlreadyDeployed) {
    // Load previous deployment if exists
    const previousDeployment = await loadPreviousDeployment(
      contractName,
      artifact
    )

    if (previousDeployment) return previousDeployment
  }

  const Contract = await ethers.getContractFactory(contractName)
  const contract = await Contract.deploy(...options.args)
  await contract.deployed()

  saveDeployment(
    contractName,
    { artifact, options, address: contract.address },
    network.name
  )
  generateFullABI(network.name)
  if (options.log) {
    console.log(`${contractName} deployed to:`, contract.address)
  }

  return contract
}

async function loadPreviousDeployment(
  contractName: string,
  artifact: Artifact
) {
  const dirName = 'deployments'
  const dirPath = `${process.cwd()}/${dirName}`
  const filePath = `${dirPath}/${contractName}.json`

  if (!fs.existsSync(filePath)) return null

  const previousDeployment = JSON.parse(
    fs.readFileSync(filePath, { encoding: 'utf-8' })
  )

  if (previousDeployment[network.name] === undefined) return null

  // If contract is already deployed, return it
  if (
    previousDeployment[network.name].artifact.bytecode === artifact.bytecode
  ) {
    const contract = await ethers.getContractAt(
      contractName,
      previousDeployment[network.name].address
    )

    console.log(
      `Contract ${contractName} already deployed at ${contract.address}`
    )

    return contract
  }

  return null
}
