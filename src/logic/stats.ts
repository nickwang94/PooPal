import { messages } from '../i18n'
import { asBristol, type BristolType } from './bristol'
import { addDays, addMonths, calendarDaysBetween, startOfDay, startOfMonth, startOfWeek, type Millis } from './dates'

/** Frequency statistics derived from a list of timestamps. Pure, so it can be tested with a fixed `now`. */
export interface PoopStats {
  totalCount: number
  todayCount: number
  last7DaysCount: number
  last30DaysCount: number
  /** Calendar days between the latest entry and today (0 = today). `null` without entries. */
  daysSinceLast: number | null
  lastDate: Millis | null
  /** Days from the first entry's day through today, inclusive. */
  trackedDays: number
  /** Entries per day across the tracked span. */
  averagePerDay: number | null
  /** Entries per day over the last 30 days (or fewer, if tracking started more recently). */
  averagePerDayLast30: number | null
  /** Mean gap between consecutive entries, in days. `null` with fewer than two entries. */
  averageIntervalDays: number | null
}

export function computeStats(dates: Millis[], now: Millis = Date.now()): PoopStats {
  const sorted = dates.filter((d) => d <= now).sort((a, b) => a - b)
  const today = startOfDay(now)
  const countSince = (daysBack: number) => {
    const start = addDays(today, -daysBack)
    return sorted.reduce((n, d) => n + (d >= start ? 1 : 0), 0)
  }

  const totalCount = sorted.length
  const last30DaysCount = countSince(29)
  const first = sorted[0]
  const last = sorted[sorted.length - 1]

  let daysSinceLast: number | null = null
  let trackedDays = 0
  let averagePerDay: number | null = null
  let averagePerDayLast30: number | null = null
  if (first !== undefined && last !== undefined) {
    daysSinceLast = calendarDaysBetween(last, today)
    trackedDays = Math.max(calendarDaysBetween(first, today) + 1, 1)
    averagePerDay = totalCount / trackedDays
    averagePerDayLast30 = last30DaysCount / Math.min(trackedDays, 30)
  }

  const averageIntervalDays =
    totalCount >= 2 ? (last - first) / 1000 / (totalCount - 1) / 86_400 : null

  return {
    totalCount,
    todayCount: countSince(0),
    last7DaysCount: countSince(6),
    last30DaysCount,
    daysSinceLast,
    lastDate: last ?? null,
    trackedDays,
    averagePerDay,
    averagePerDayLast30,
    averageIntervalDays,
  }
}

/** Number of entries per calendar day, keyed by the start of that day. */
export function countsByDay(dates: Millis[]): Map<Millis, number> {
  const counts = new Map<Millis, number>()
  for (const d of dates) {
    const day = startOfDay(d)
    counts.set(day, (counts.get(day) ?? 0) + 1)
  }
  return counts
}

export interface TypedDate {
  date: Millis
  type?: number | null
}

/** Bristol type counts for entries in the last `days` calendar days (including today). */
export function bristolDistribution(
  entries: TypedDate[],
  days = 30,
  now: Millis = Date.now(),
): Map<BristolType, number> {
  const start = addDays(startOfDay(now), -(days - 1))
  const result = new Map<BristolType, number>()
  for (const entry of entries) {
    const type = asBristol(entry.type)
    if (entry.date < start || entry.date > now || type === undefined) continue
    result.set(type, (result.get(type) ?? 0) + 1)
  }
  return result
}

/** Most frequent Bristol type in the window; ties go to the type closest to the ideal (4). */
export function mostCommonBristol(entries: TypedDate[], days = 30, now: Millis = Date.now()): BristolType | null {
  let best: [BristolType, number] | null = null
  for (const [type, count] of bristolDistribution(entries, days, now)) {
    if (
      best === null ||
      count > best[1] ||
      (count === best[1] && Math.abs(type - 4) < Math.abs(best[0] - 4))
    ) {
      best = [type, count]
    }
  }
  return best?.[0] ?? null
}

export type TrendPeriod = 'week' | 'month'

export interface TrendBucket {
  start: Millis
  count: number
}

function periodStart(t: Millis, period: TrendPeriod): Millis {
  return period === 'week' ? startOfWeek(t) : startOfMonth(t)
}

/** The last `count` periods ending with the current one, oldest first, including empty periods. */
export function trendBuckets(
  dates: Millis[],
  period: TrendPeriod,
  count = 12,
  now: Millis = Date.now(),
): TrendBucket[] {
  const current = periodStart(now, period)
  const starts = Array.from({ length: count }, (_, i) => {
    const back = count - 1 - i
    return period === 'week' ? addDays(current, -7 * back) : addMonths(current, -back)
  })
  const counts = new Map<Millis, number>()
  for (const d of dates) {
    if (d > now) continue
    const s = periodStart(d, period)
    counts.set(s, (counts.get(s) ?? 0) + 1)
  }
  return starts.map((start) => ({ start, count: counts.get(start) ?? 0 }))
}

export type PoopMood =
  | { kind: 'noData' }
  | { kind: 'today' }
  | { kind: 'yesterday' }
  | { kind: 'aWhile'; days: number }
  | { kind: 'tooLong'; days: number }

export function moodFor(daysSinceLast: number | null): PoopMood {
  if (daysSinceLast === null) return { kind: 'noData' }
  if (daysSinceLast <= 0) return { kind: 'today' }
  if (daysSinceLast === 1) return { kind: 'yesterday' }
  if (daysSinceLast === 2) return { kind: 'aWhile', days: daysSinceLast }
  return { kind: 'tooLong', days: daysSinceLast }
}

export function moodTitle(mood: PoopMood): string {
  const t = messages().moodTitle
  switch (mood.kind) {
    case 'noData':
      return t.noData
    case 'today':
      return t.today
    case 'yesterday':
      return t.yesterday
    default:
      return t.days(mood.days)
  }
}

export function moodMessage(mood: PoopMood): string {
  return messages().mood[mood.kind]
}

export interface ValueUnit {
  value: string
  unit: string
}

export const StatsFormat = {
  perDay(value: number | null): string {
    return value === null ? '—' : value.toFixed(1)
  },
  /** Hours when under a day, otherwise days with one decimal. */
  interval(days: number | null): ValueUnit {
    if (days === null) return { value: '—', unit: '' }
    const { units } = messages()
    const hours = Math.round(days * 24)
    if (hours < 24) {
      const shown = Math.max(hours, 1)
      return { value: shown.toFixed(0), unit: units.hours(shown) }
    }
    return { value: days.toFixed(1), unit: units.days(days) }
  },
  /** Whether the last entry was under an hour ago, which reads as "just now" rather than a duration. */
  isJustNow(last: Millis, now: Millis = Date.now()): boolean {
    return now - last < 3_600_000
  },
  /** Elapsed time since the last entry: "刚刚", "3 小时", "2 天". */
  elapsed(last: Millis | null, now: Millis = Date.now()): string | null {
    if (last === null) return null
    const { units } = messages()
    if (StatsFormat.isJustNow(last, now)) return units.justNow
    const hours = Math.floor(Math.max(0, now - last) / 3_600_000)
    if (hours < 48) return units.hoursValue(hours)
    return units.daysValue(Math.floor(hours / 24))
  },
  daysSince(days: number | null): ValueUnit {
    if (days === null) return { value: '—', unit: '' }
    if (days === 0) return { value: messages().date.today, unit: '' }
    return { value: String(days), unit: messages().units.days(days) }
  },
}
