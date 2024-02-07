import * as fs from 'fs'
import hre from 'hardhat'
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
  console.log('🚀 ~ file: deployContract.ts:23 ~ contractName:', contractName)
  const artifact = await hre.artifacts.readArtifact(contractName)

  if (hre.network.name !== 'hardhat' && options.skipIfAlreadyDeployed) {
    // Load previous deployment if exists
    const previousDeployment = await loadPreviousDeployment(
      contractName,
      artifact
    )

    if (previousDeployment) return previousDeployment
  }

  const Contract = await hre.ethers.getContractFactory(contractName)
  const contract = await Contract.deploy(...options.args)
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  saveDeployment(
    contractName,
    { artifact, options, address: contractAddress },
    hre.network.name
  )
  // generateFullABI(network.name)
  if (options.log) {
    console.log(`${contractName} deployed to:`, contractAddress)
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

  if (previousDeployment[hre.network.name] === undefined) return null

  // If contract is already deployed, return it
  if (
    previousDeployment[hre.network.name].artifact.bytecode === artifact.bytecode
  ) {
    console.log("Contract's bytecode is the same, reusing previous deployment")
    const contract = await hre.ethers.getContractAt(
      contractName,
      previousDeployment[hre.network.name].address
    )

    console.log(
      `Contract ${contractName} already deployed at ${await contract.getAddress()}`
    )

    return contract
  }

  return null
}
