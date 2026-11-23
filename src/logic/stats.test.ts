import { describe, expect, it } from 'vitest'
import { addDays, DateText, startOfDay } from './dates'
import {
  bristolDistribution,
  computeStats,
  countsByDay,
  moodFor,
  mostCommonBristol,
  StatsFormat,
  trendBuckets,
} from './stats'

const date = (y: number, m: number, d: number, h = 9, min = 0) => new Date(y, m - 1, d, h, min).getTime()

describe('PoopStats', () => {
  const now = date(2026, 11, 2, 12, 0)

  it('has no averages for an empty log', () => {
    const stats = computeStats([], now)
    expect(stats.totalCount).toBe(0)
    expect(stats.last7DaysCount).toBe(0)
    expect(stats.daysSinceLast).toBeNull()
    expect(stats.averagePerDay).toBeNull()
    expect(stats.averageIntervalDays).toBeNull()
    expect(stats.trackedDays).toBe(0)
  })

  it('handles a single entry today', () => {
    const stats = computeStats([date(2026, 11, 2, 8)], now)
    expect(stats.todayCount).toBe(1)
    expect(stats.daysSinceLast).toBe(0)
    expect(stats.trackedDays).toBe(1)
    expect(stats.averagePerDay).toBeCloseTo(1.0, 4)
    expect(stats.averageIntervalDays).toBeNull()
  })

  it('gives one per day and a one-day interval for daily entries', () => {
    const dates = Array.from({ length: 10 }, (_, i) => addDays(date(2026, 11, 2, 9), -i))
    const stats = computeStats(dates, now)
    expect(stats.totalCount).toBe(10)
    expect(stats.trackedDays).toBe(10)
    expect(stats.averagePerDay).toBeCloseTo(1.0, 4)
    expect(stats.averageIntervalDays).toBeCloseTo(1.0, 4)
    expect(stats.last7DaysCount).toBe(7)
    expect(stats.last30DaysCount).toBe(10)
  })

  it('uses calendar days for window boundaries', () => {
    const dates = [
      date(2026, 10, 27, 0, 1), // 6 days ago, early morning: inside 7-day window
      date(2026, 10, 26, 23, 59), // 7 days ago: outside
      date(2026, 10, 4, 0, 0), // 29 days ago: inside 30-day window
      date(2026, 10, 3, 23, 0), // 30 days ago: outside
    ]
    const stats = computeStats(dates, now)
    expect(stats.last7DaysCount).toBe(1)
    expect(stats.last30DaysCount).toBe(3)
    expect(stats.daysSinceLast).toBe(6)
  })

  it('counts days since last in calendar days, not hours', () => {
    const stats = computeStats([date(2026, 11, 1, 23, 50)], now)
    expect(stats.daysSinceLast).toBe(1)
    expect(moodFor(stats.daysSinceLast)).toEqual({ kind: 'yesterday' })
  })

  it('averages uneven gaps from unsorted input', () => {
    const stats = computeStats([date(2026, 11, 2, 9), date(2026, 10, 29, 9), date(2026, 10, 30, 9)], now)
    expect(stats.averageIntervalDays).toBeCloseTo(2.0, 4)
    expect(stats.trackedDays).toBe(5)
    expect(stats.averagePerDay).toBeCloseTo(0.6, 4)
  })

  it('handles multiple entries per day', () => {
    const stats = computeStats([date(2026, 11, 2, 7), date(2026, 11, 2, 11), date(2026, 11, 1, 20)], now)
    expect(stats.todayCount).toBe(2)
    expect(stats.averagePerDay).toBeCloseTo(1.5, 4)
    expect(StatsFormat.interval(stats.averageIntervalDays).unit).toBe('小时')
  })

  it('ignores future entries', () => {
    const stats = computeStats([date(2026, 11, 2, 8), date(2026, 11, 3, 8)], now)
    expect(stats.totalCount).toBe(1)
    expect(stats.daysSinceLast).toBe(0)
  })

  it('counts by day', () => {
    const counts = countsByDay([date(2026, 11, 2, 7), date(2026, 11, 2, 21), date(2026, 11, 1, 9)])
    expect(counts.get(startOfDay(date(2026, 11, 2)))).toBe(2)
    expect(counts.get(startOfDay(date(2026, 11, 1)))).toBe(1)
    expect(counts.size).toBe(2)
  })

  it('maps mood thresholds', () => {
    expect(moodFor(null)).toEqual({ kind: 'noData' })
    expect(moodFor(0)).toEqual({ kind: 'today' })
    expect(moodFor(1)).toEqual({ kind: 'yesterday' })
    expect(moodFor(2)).toEqual({ kind: 'aWhile', days: 2 })
    expect(moodFor(5)).toEqual({ kind: 'tooLong', days: 5 })
  })

  it('formats numbers', () => {
    expect(StatsFormat.perDay(null)).toBe('—')
    expect(StatsFormat.perDay(1.26)).toBe('1.3')
    expect(StatsFormat.interval(1.5)).toEqual({ value: '1.5', unit: '天' })
    expect(StatsFormat.interval(0.5).value).toBe('12')
    // Just under a day reads as "1.0 天", not "24 小时".
    expect(StatsFormat.interval(0.99)).toEqual({ value: '1.0', unit: '天' })
    expect(StatsFormat.daysSince(0).value).toBe('今天')
    expect(StatsFormat.daysSince(3).value).toBe('3')
  })

  it('greets by time of day', () => {
    const at = (hour: number) => date(2026, 11, 17, hour, 30)
    expect(DateText.greeting(at(7))).toBe('早上好')
    expect(DateText.greeting(at(12))).toBe('中午好')
    expect(DateText.greeting(at(15))).toBe('下午好')
    expect(DateText.greeting(at(20))).toBe('晚上好')
    expect(DateText.greeting(at(23))).toBe('夜深了')
    expect(DateText.greeting(at(3))).toBe('夜深了')
  })

  it('formats elapsed time', () => {
    const t = 1_800_000_000_000
    const hour = 3_600_000
    expect(StatsFormat.elapsed(null, t)).toBeNull()
    expect(StatsFormat.elapsed(t - 20 * 60_000, t)).toBe('刚刚')
    expect(StatsFormat.elapsed(t + 60_000, t)).toBe('刚刚')
    expect(StatsFormat.elapsed(t - 11.5 * hour, t)).toBe('11 小时')
    expect(StatsFormat.elapsed(t - 47.9 * hour, t)).toBe('47 小时')
    expect(StatsFormat.elapsed(t - 73 * hour, t)).toBe('3 天')
  })

  it('formats day titles', () => {
    const now2 = date(2026, 11, 17, 20)
    expect(DateText.dayTitle(date(2026, 11, 17, 8), now2)).toBe('今天')
    expect(DateText.short(date(2026, 11, 16, 21, 10), now2)).toBe('昨天 21:10')
    expect(DateText.dayTitle(date(2026, 11, 2), now2)).toBe('11月2日 星期一')
    expect(DateText.short(date(2026, 11, 2, 8, 30), now2)).toBe('11月2日 08:30')
  })
})

describe('Insights', () => {
  const now = date(2026, 11, 14, 19, 0) // Saturday
  const daysAgo = (n: number, hour = 9) => addDays(date(2026, 11, 14, hour), -n)

  it('uses a shorter span for the 30-day average when tracking is new', () => {
    const dates = [...Array.from({ length: 10 }, (_, i) => daysAgo(i)), daysAgo(0, 7)]
    const stats = computeStats(dates, now)
    expect(stats.trackedDays).toBe(10)
    expect(stats.averagePerDayLast30).toBeCloseTo(1.1, 4)
    expect(stats.averagePerDay).toBeCloseTo(1.1, 4)
  })

  it('keeps the 30-day average separate from the full history', () => {
    const old = Array.from({ length: 30 }, (_, i) => daysAgo(30 + i))
    const recent = Array.from({ length: 15 }, (_, i) => daysAgo(i * 2))
    const stats = computeStats([...old, ...recent], now)
    expect(stats.last30DaysCount).toBe(15)
    expect(stats.averagePerDayLast30).toBeCloseTo(0.5, 4)
    expect(stats.averagePerDay).toBeCloseTo(45 / 60, 4)
  })

  it('has no 30-day average without entries', () => {
    expect(computeStats([], now).averagePerDayLast30).toBeNull()
  })

  it('ignores old, missing and invalid Bristol types', () => {
    const entries = [
      { date: daysAgo(0), type: 4 },
      { date: daysAgo(1), type: 4 },
      { date: daysAgo(2), type: 3 },
      { date: daysAgo(3), type: null },
      { date: daysAgo(4), type: 9 },
      { date: daysAgo(40), type: 1 },
    ]
    expect(bristolDistribution(entries, 30, now)).toEqual(
      new Map([
        [4, 2],
        [3, 1],
      ]),
    )
    expect(mostCommonBristol(entries, 30, now)).toBe(4)
  })

  it('breaks most-common ties toward the ideal type', () => {
    const entries = [
      { date: daysAgo(0), type: 1 },
      { date: daysAgo(1), type: 5 },
    ]
    expect(mostCommonBristol(entries, 30, now)).toBe(5)
    expect(mostCommonBristol([], 30, now)).toBeNull()
  })

  it('builds weekly buckets oldest first, including empty weeks (Monday start)', () => {
    const buckets = trendBuckets([daysAgo(0), daysAgo(1), daysAgo(8), daysAgo(30)], 'week', 3, now)
    expect(buckets.map((b) => b.count)).toEqual([0, 1, 2])
    expect(buckets[2].start).toBe(date(2026, 11, 9, 0, 0))
    expect(buckets[0].start).toBe(date(2026, 10, 26, 0, 0))
  })

  it('builds monthly buckets', () => {
    const dates = [daysAgo(0), date(2026, 11, 1, 0, 30), date(2026, 10, 31, 23, 0), date(2026, 9, 5)]
    const buckets = trendBuckets(dates, 'month', 3, now)
    expect(buckets.map((b) => b.count)).toEqual([1, 1, 2])
    expect(buckets.map((b) => b.start)).toEqual([date(2026, 9, 1, 0, 0), date(2026, 10, 1, 0, 0), date(2026, 11, 1, 0, 0)])
  })

  it('ignores future entries in trends', () => {
    expect(trendBuckets([date(2026, 11, 15)], 'week', 1, now).map((b) => b.count)).toEqual([0])
  })
})
