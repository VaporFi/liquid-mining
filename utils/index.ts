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

export function getNextMonthTimestamp(): number {
  const now = new Date()
  const nextMonth = new Date(
    Date.UTC(
      now.getUTCMonth() === 11
        ? now.getUTCFullYear() + 1
        : now.getUTCFullYear(),
      now.getUTCMonth() === 11 ? 0 : now.getUTCMonth() + 1,
      1
    )
  )
  return Math.floor(nextMonth.getTime() / 1000)
}
