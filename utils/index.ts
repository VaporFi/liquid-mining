export * from './getEnvValSafe'
// export * from "./diamond";
export * from './saveDeployment'
export * from './wait'
export * from './getContractDeployment'
export * from './logTx'

/*
 * Starting at 15,000 VAPE per season, on Season 1,
 * we will decreate the emissions by 0.41217% per season.
 */
export const calculateReward = (seasonId: number) => {
  // Initial values
  const initialRewards = 15000
  const reductionPercentage = 0.41217 / 100

  let reward = initialRewards
  for (let season = 2; season <= seasonId; season++) {
    reward = reward - reward * reductionPercentage
  }

  return reward
}

export const getNextMonthTimestamp = () => {
  const now = new Date()
  now.setUTCHours(0, 0, 0, 0)
  const nextMonth = new Date(
    now.getUTCMonth() === 11 ? now.getUTCFullYear() + 1 : now.getUTCFullYear(),
    now.getUTCMonth() === 11 ? 0 : now.getUTCMonth() + 1,
    1
  )
  const timestamp = Math.floor(nextMonth.getTime() / 1000)
  return timestamp
}
