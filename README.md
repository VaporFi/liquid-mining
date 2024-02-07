# Liquid Staking

## Features

- Users can stake VPND to earn VAPE
- Staking occurs in seasons, each season has a fixed duration of 25 days
- If a user wants to withdraw his VPND before the season ends, he will be charged a penalty
- At the end of each season, users can withdraw their VAPE and VPND or re-stake their VPND to earn more VAPE in the next season
- Users can claim a free daily Boost if they are Stratosphere members
- Users can claim a paid daily Boost, paid in USDC. The are 3 Boost levels, each with a different price and reward

### How does the points system work?

When a user deposits VPND, we calculate the number of points they will earn for the remainder of the season using an optimistic approach.

**Users receive 1 point for every 1 VPND deposited daily.**

If a user withdraws VPND before the season ends, we deduct the points they would have earned for the remaining days by calculating the days left in the season.

For each Deposit and Unlock action, we update the total points accumulated in a season. This information is later utilized when the season concludes to determine each user's fair share of VAPE.

---

## Tasks

## How to start the FIRST season

- [] Deploy LiquidStaking contract
- [] Setup the LS address in EmissionsManager
- [] Get `seasonMintAllowance` from EmissionsManager
- [] Execute `startSeason` in LiquidStaking, using `seasonMintAllowance` as the argument
- [] Execute `mintLiquidStaking` in EmissionsManager (or manually transfer VAPE if testnet)

## How to start a new season

- [] Get `seasonMintAllowance` from EmissionsManager
- [] Execute `startSeason` in LiquidStaking, using `seasonMintAllowance` as the argument

### Commands

❯ yarn hardhat automated-claim:all --network avalanche --load-from-subgraph true
❯ yarn hardhat run --network avalanche scripts/startSeason.ts
