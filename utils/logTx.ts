import { ContractTransaction } from 'ethers'

async function logTx(res: ContractTransaction) {
  console.log(`Transaction pending: ${res.hash}`)
  await res.wait()
  console.log('Done! 🎉')
}

export default logTx
