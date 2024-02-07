import { ContractTransactionResponse } from 'ethers'

export async function logTx(
  res: ContractTransactionResponse,
  confirmations?: number
) {
  console.log(`Transaction pending: ${res.hash}`)
  await res.wait(confirmations ?? 1)
  console.log('Done! 🎉')
}
