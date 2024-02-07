import { expect } from 'chai'
import { getNextMonthTimestamp } from '../utils'

describe('getNextMonthTimestamp', () => {
  it('should return the timestamp of the first day of the next month', () => {
    const now = new Date()
    now.setUTCHours(0, 0, 0, 0)
    const nextMonth = new Date(
      now.getMonth() === 11 ? now.getFullYear() + 1 : now.getFullYear(),
      now.getMonth() === 11 ? 0 : now.getMonth() + 1,
      1
    )
    const expectedTimestamp = Math.floor(nextMonth.getTime() / 1000)
    expect(getNextMonthTimestamp()).to.equal(expectedTimestamp)
  })
})
