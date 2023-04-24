import * as fs from 'fs'
import { Artifact } from 'hardhat/types'
import { DeployOptions } from './deployContract'

export type Deployment = {
  address: string
  artifact: Artifact
  options: DeployOptions
}

export const saveDeployment = (
  fileName: string,
  deployment: Deployment,
  networkName: string
) => {
  const dirName = 'deployments'
  const dirPath = `${process.cwd()}/${dirName}`
  const filePath = `${dirPath}/${fileName}.json`

  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true })
  }

  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(
      filePath,
      JSON.stringify({ [networkName]: deployment }, null, 2)
    )
  } else {
    const details = JSON.parse(fs.readFileSync(filePath, { encoding: 'utf-8' }))

    details[networkName] = deployment

    fs.writeFileSync(filePath, JSON.stringify(details, null, 2))
  }
}
